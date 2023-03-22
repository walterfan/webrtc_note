####################
WebRTC test
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC test
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============


Chrome testing
====================

* Chrome command line flags that are useful for WebRTC-related testing:


for example

.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging=stderr --v=1 \

   > log.txt 2>&1 

some other options:


.. code-block::

   --allow-file-access-from-files allows getUserMedia() to be called from file:// URLs.

   --disable-gesture-requirement-for-media-playback removes the need to tap a <video> element to start it playing on Android.

   --use-fake-ui-for-media-stream avoids the need to grant camera/microphone permissions.

   --use-fake-device-for-media-stream feeds a test pattern to getUserMedia() instead of live camera input.

   --use-file-for-fake-video-capture=path/to/file.y4m feeds a Y4M test file to getUserMedia() instead of live camera input.

* disable CORS

.. code-block::

  open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security


* enable logging

refer to https://www.chromium.org/for-testers/enable-logging/

.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging=stderr --v=1 > log.txt 2>&1 # Capture stderr and stdout to a log file

   /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary  --enable-logging --v=1


* disable SRTP


.. code-block::

    cd /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/
    ./Google\ Chrome\ Canary --disable-webrtc-encryption


* allow some unsafe ports

.. code-block::

   "C:\Program Files\Google\Chrome\Application\chrome.exe --explicitly-allowed-ports=6000,6443"

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --explicitly-allowed-ports=6000,6443

   /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary --explicitly-allowed-ports=6000,6443


Load local vide file as a virtual camear
--------------------------------------------

* MacOS

.. code-block::

   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --use-fake-device-for-media-stream \
   --use-file-for-fake-video-capture=/Users/yafan/Downloads/station2_1080p25.y4m

* Windows

.. code-block::

   "C:\Program Files\Google\Chrome\Application\chrome.exe" --use-fake-device-for-media-stream \
   --use-file-for-fake-video-capture="C:\Users\yafan\Downloads\rush_hour_1080p25.y4m"



.. code-block::

   cd /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/
   ./Google\ Chrome\ Canary --disable-webrtc-encryption


Firefox testing
===============================

Input "about:webrtc" in the browser address line

How to turn on RTP logging
---------------------------------
As described on Firefox Media Logging page you have to set environment variables to turn on the logging. 
Note that we now need to use MOZ_LOG instead of NSPR_LOG as used to be the case. 
So a real world example which logs the SDP and the RTP would look like this:

.. code-block::

  MOZ_LOG=timestamp,signaling:5,jsep:5,RtpLogger:5
  MOZ_LOG_FILE=/tmp/logs/moz.log

The log lines are in the text2pcap format. RTP packets will have RTP_PACKET at the end of the line, 
which allows you to filter for either that or RTCP packets. 

You might have also noticed that the track ID from the MSID is present. 
So if you have access to the SDP from the signaling, for example on ‘about:webrtc‘, 
you can also filter all incoming and outgoing RTP and RTCP messages for a single audio or video track.


How to Convert logs into PCAP
-------------------------------------
Finally here is one handy line to convert all RTP and RTCP from the log file into a PCAP file which can be loaded and analyzed with Wireshark:

.. code-block::

   egrep '(RTP_PACKET|RTCP_PACKET)' moz.log | text2pcap -D -n -l 1 -i 17 -u 1234,1235 -t '%H:%M:%S.' - rtp.pcap

Wireshark allows you now easily to search for example for NACKs or PLIs in the RTCP and check if the requested video packet got send to or by Firefox.


And here are two filter criteria for future reference:

.. code-block::

   NACK: rtcp.rtpfb.fmt == 1
   PLI: rtcp.psfb.fmt == 1

* Update

If your log lines start with an extra GECKO like this “GECKO(23379) | I 16:36:58.954388” you might need to tweak you grep command to something like this:

.. code-block::

   egrep '(RTP_PACKET|RTCP_PACKET)' moz.log | cut -d '|' -f 2 | text2pcap -D -n -l 1 -i 17 -u 1234,1235 -t '%H:%M:%S.' - rtp.pcap

* Update 2

Most recently more updates made the above line not work fully any more. So here is a version which works again with Firefox >= 65:

.. code-block::

   egrep '(RTP_PACKET|RTCP_PACKET)' moz.log.child-4 | cut -d '|' -f 2 | cut -d ' ' -f 5- | text2pcap -D -n -l 1 -i 17 -u 1234,1235 -t '%H:%M:%S.' - rtp.pcap   

Unit testing
===============================
./out/Default/modules_unittests --gtest_filter="GoogCc*" --gtest_output="xml:goog-cc-ut-report.xml"

they are the test cases that generated from "goog-cc-ut-report.xml" by a python script I wrote before

.. code-block:: 

   gtest2html.py --input=goog-cc-ut-report.xml --output=goog-cc-ut-report.md

+-----+------------------------------+-------------------------------------------------------+---------+--------+
| #   | suite                        | case                                                  | time    | result |
+=====+==============================+=======================================================+=========+========+
|| 1  || GoogCcNetworkControllerTest || InitializeTargetRateOnFirstProcessInterval           || 0      || pass  |
|| 2  || GoogCcNetworkControllerTest || ReactsToChangedNetworkConditions                     || 0      || pass  |
|| 3  || GoogCcNetworkControllerTest || OnNetworkRouteChanged                                || 0      || pass  |
|| 4  || GoogCcNetworkControllerTest || ProbeOnRouteChange                                   || 0      || pass  |
|| 5  || GoogCcNetworkControllerTest || UpdatesDelayBasedEstimate                            || 0.182  || pass  |
|| 6  || GoogCcNetworkControllerTest || PaceAtMaxOfLowerLinkCapacityAndBwe                   || 0      || pass  |
|| 7  || GoogCcScenario              || CongestionWindowPushbackOnNetworkDelay               || 1.156  || pass  |
|| 8  || GoogCcScenario              || CongestionWindowPushbackDropFrameOnNetworkDelay      || 1.196  || pass  |
|| 9  || GoogCcScenario              || PaddingRateLimitedByCongestionWindowInTrial          || 0.996  || pass  |
|| 10 || GoogCcScenario              || LimitsToFloorIfRttIsHighInTrial                      || 0.703  || pass  |
|| 11 || GoogCcScenario              || UpdatesTargetRateBasedOnLinkCapacity                 || 6.291  || pass  |
|| 12 || GoogCcScenario              || StableEstimateDoesNotVaryInSteadyState               || 4.137  || pass  |
|| 13 || GoogCcScenario              || LossBasedControlUpdatesTargetRateBasedOnLinkCapacity || 6.13   || pass  |
|| 14 || GoogCcScenario              || LossBasedControlDoesModestBackoffToHighLoss          || 8.637  || pass  |
|| 15 || GoogCcScenario              || LossBasedRecoversFasterAfterCrossInducedLoss         || 16.913 || pass  |
|| 16 || GoogCcScenario              || LossBasedEstimatorCapsRateAtModerateLoss             || 2.988  || pass  |
|| 17 || GoogCcScenario              || MaintainsLowRateInSafeResetTrial                     || 0.047  || pass  |
|| 18 || GoogCcScenario              || CutsHighRateInSafeResetTrial                         || 0.049  || pass  |
|| 19 || GoogCcScenario              || DetectsHighRateInSafeResetTrial                      || 0.21   || pass  |
|| 20 || GoogCcScenario              || TargetRateReducedOnPacingBufferBuildupInTrial        || 0.556  || pass  |
|| 21 || GoogCcScenario              || NoBandwidthTogglingInLossControlTrial                || 0.286  || pass  |
|| 22 || GoogCcScenario              || NoRttBackoffCollapseWhenVideoStops                   || 0.19   || pass  |
|| 23 || GoogCcScenario              || NoCrashOnVeryLateFeedback                            || 6.718  || pass  |
|| 24 || GoogCcScenario              || IsFairToTCP                                          || 0.601  || pass  |
|| 25 || GoogCcScenario              || FastRampupOnRembCapLifted                            || 2.818  || pass  |
|| 26 || GoogCcScenario              || SlowRampupOnRembCapLiftedWithFieldTrial              || 2.012  || pass  |
+-----+------------------------------+-------------------------------------------------------+---------+--------+


Test scenarios
===============================

在 WebRTC 的 test/scenario 模块中有一个称为 Scenario 的类， 它是一个拥有测试场景所有内容的类。 它创建并保存网络节点、呼叫客户端和媒体流。 它还提供了在运行时改变行为的方法。

由于它始终保持所创建组件的所有权，因此它通常返回的指针是不具有拥有仅的，只能由 Scenario 自己来保持其对象的生命，直到它被销毁。

对于接受配置结构体的方法，一般会提供一个修改函数接口。 这样测试者可以简单地覆盖部分默认的配置。



参考资料
===============================
* `WebRTC test suite`_
* `The web-platform-tests Project`_ 

.. _The web-platform-tests Project: https://github.com/web-platform-tests/wpt
.. _WebRTC test suite: https://github.com/web-platform-tests/wpt/tree/master/webrtc/