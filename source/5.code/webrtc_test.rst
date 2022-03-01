####################
WebRTC test suite
####################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC test suite
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
=============


测试
====================

* Chrome command line flags that are useful for WebRTC-related testing:

.. code-block::
      
   --allow-file-access-from-files allows getUserMedia() to be called from file:// URLs.

   --disable-gesture-requirement-for-media-playback removes the need to tap a <video> element to start it playing on Android.

   --use-fake-ui-for-media-stream avoids the need to grant camera/microphone permissions.

   --use-fake-device-for-media-stream feeds a test pattern to getUserMedia() instead of live camera input.

   --use-file-for-fake-video-capture=path/to/file.y4m feeds a Y4M test file to getUserMedia() instead of live camera input.



* enable logging::
  
   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --enable-logging --v=1
   
   /Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary  --enable-logging --v=1


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




参考资料
===============================
* `WebRTC test suite`_
* `The web-platform-tests Project`_ 

.. _The web-platform-tests Project: https://github.com/web-platform-tests/wpt
.. _WebRTC test suite: https://github.com/web-platform-tests/wpt/tree/master/webrtc/