########################
wireshark
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** wireshark
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Installation
====================================

* Linux	$PkgManager install wireshark	2.6.8 and below
* Macos	brew install --cask wireshark	3.0.2
* Windows	choco install wireshark


Tools
====================================
* capinfos
* captype
* dftest
* dumpcap
* editcap
* extcap
* idl2wrs
* mergecap
* mmdbresolve
* randpkt
* rawshark
* reordercap
* sharkd
* text2pcap
* tshark

tshark
------------------------------------

tshark is a command line tool of wireshark , we can create a symbol link like below on MacOS

.. code-block::

    ln -s /Applications/Wireshark.app/Contents/MacOS/tshark /usr/local/bin/tshark


Basic Usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
具体用法参见 `tshark --help` 或者 https://www.wireshark.org/docs/man-pages/tshark.html

例如将 pcapng 文件中的前 100 包按以下条件过滤出来，并导出为 json 文件

.. code-block::

   tshark -r 2022-03-30-cc.pcapng -2 -Y "ip.addr == 10.140.202.120 and rtp.p_type == 123" -V -c 100 -T json >
   packet_sample.json


输出结果如下


.. code-block::

        //省略 1 ~ 4 层的信息： 1) frame, 2) eth, 3) ip, 4) udp
        "rtp": {
          "rtp.setup": "",
          "rtp.setup_tree": {
            "rtp.setup-frame": "1",
            "rtp.setup-method": "HEUR RTP"
          },
          "rtp.version": "2",
          "rtp.padding": "0",
          "rtp.ext": "1",
          "rtp.cc": "0",
          "rtp.marker": "0",
          "rtp.p_type": "123",
          "rtp.seq": "8637",
          "rtp.extseq": "74173",
          "rtp.timestamp": "2709737133",
          "rtp.ssrc": "0xe19bcceb",
          "rtp.ext.profile": "0x0000bede",
          "rtp.ext.len": "2",
          "rtp.hdr_exts": {
            "RFC 5285 Header Extension (One-Byte Header)": {
              "rtp.ext.rfc5285.id": "2",
              "rtp.ext.rfc5285.len": "3",
              "rtp.ext.rfc5285.data": "e0:9c:ac"
            },
            "RFC 5285 Header Extension (One-Byte Header)": {
              "rtp.ext.rfc5285.id": "3",
              "rtp.ext.rfc5285.len": "2",
              "rtp.ext.rfc5285.data": "c4:70"
            }
          },
          "rtp.payload": "92:00:60:90:80:c6:67:51:61:00:e4:e0:af:bd:4a:7e:12:c0:7a:02:75:eb:ea:aa:91:81:d2:61:f1:07:d4:01:2c:18:b9:d3:4d:58:c5:ce:9a:6a:c6:43:91:03:d6:ea:aa:aa:28:f9:55:55:54:6d:55:55:54:be:48:57:d5:55:40:99:9e:aa:aa:a4:ba:e5:55:5b:ad:33:a0:be:aa:a9:86:bf:ff:ff:e2:02:d1:ba:55:55:34:92:15:f0:2f:aa:a9:7f:5e:e9:b9:84:95:55:5a:35:26:78:3b:cc:df:f2:03:4a:07:46:76:f9:fe:c6:27:a4:a3:38:fe:11:82:d5:54:24:f5:ec:aa:60:d3:52:d8:d1:8d:f9:29:0f:d0:fd:2a:46:41:d4:aa:a3:0d:83:02:47:da:31:9a:5a:4f:13:e4:a9:c2:e2:17:b4:46:be:e0:13:7c:b6:bb:63:20:94:31:8b:dc:ab:07:a2:3d:31:00:00:0e:9c:45:a5:fb:d0:32:cd:2b:f1:76:0f:fe:fa:5c:89:77:77:99:b5:a1:c3:82:77:eb:0b:05:fb:87:a3:e1:92:e2:70:19:da:dd:25:ec:ba:4b:d9:46:c2:22:7c:70:6c:f0:e4:c2:0f:c7:a2:bf:4f:22:2c:81:00:01:29:c3:c2:ac:1f:df:72:fb:3f:86:b9:79:8f:1c:ce:56:1a:db:d7:52:77:57:84:a7:3b:bd:8b:d9:74:97:b2:e9:2f:65:a5:7e:ae:88:0c:0d:80:5e:cb:a1:44:f0:af:87:7a:97:b2:f3:5c:e2:3e:b4:d9:f8:3f:64:9c:a3:bd:4c:59:dd:6e:c3:7d:f9:d3:12:c7:75:54:46:da:4d:e9:54:bd:e7:7f:8c:e5:ef:65:d2:5e:cb:a4:bd:97:49:d6:a2:2c:b2:ba:4b:a5:6b:c4:20:43:92:5e:cb:a4:b8:94:e8:81:55:9d:ec:5e:cb:a4:ef:fd:49:57:fc:a1:28:9b:54:13:21:20:68:83:06:6f:86:8e:7c:ec:3c:09:05:56:74:a5:c9:42:d4:5d:25:ec:ba:4b:c4:f5:ba:42:04:59:74:97:1e:4f:10:94:9c:c4:ad:fa:04:79:85:33:7e:81:1e:44:1e:c5:ec:ba:4b:8a:55:00:00:55:1c:c9:79:4e:bf:01:18:76:5f:ce:70:07:d5:1e:a8:b8:6b:b8:88:88:67:7a:5c:23:7d:60:a0:6b:f9:78:2e:b2:c2:45:72:c4:aa:7e:31:1f:db:1b:04:01:5a:ae:3b:ee:43:9a:88:a3:1b:59:e4:fb:70:87:64:4d:85:c6:ef:87:24:f5:86:a3:9e:70:f0:b5:6d:e7:99:48:53:94:7f:4a:6c:d0:62:6e:33:c3:bd:3c:c9:cc:3d:e6:26:6a:a1:40:75:c8:c5:8c:60:72:17:81:b6:fb:a9:3c:45:b7:bf:b7:a5:88:5c:14:20:47:c9:55:49:18:c4:62:5e:a5:af:a2:d0:62:aa:54:0d:be:9c:5f:5a:70:b6:49:05:d7:ec:78:5c:9c:74:d0:66:4d:b4:0e:50:11:12:2a:c2:c3:55:e2:99:95:db:b9:45:b0:dd:e2:1e:eb:c4:d9:ad:0b:1b:4d:a9:73:20:4a:fa:27:ec:09:7e:c1:57:f6:0e:7e:a7:79:7a:e6:f8:41:c1:43:e0:30:24:e7:92:0d:60:c8:a3:51:b0:c2:16:1f:3d:91:b9:d0:75:b1:2a:f4:2f:68:85:56:50:b5:24:b9:26:ef:fb:6d:c5:f4:e9:3e:11:f7:86:ef:d9:04:10:50:35:28:cc:69:f2:4b:b2:f2:6a:3c:d0:af:9d:85:cc:3b:e8:b8:53:e2:fc:02:64:88:58:82:ee:39:a1:f9:68:16:e4:75:77:7a:51:50:04:b0:e8:1c:8b:d1:22:6c:57:54:70:d7:dc:a5:a5:53:dd:55:37:d5:dd:d5:55:55:47:d5:55:0a:db:8f:aa:aa:21:e2:da:58:0f:2a:8d:aa:aa:aa:9a:4a:aa:aa:a1:12:aa:aa:a5:1b:ea:aa:a7:ba:aa:aa:a8:fa:aa:aa:a9:aa:aa:aa:aa:1a:aa:aa:a9:a8:e5:8e:d4:df:eb:28:28:1c:e8:32:f7:a2:e0:34:bf:81:cc:e6:7c:0c:1f:39:86:3f:d4:a4:80:8b:0e:84:56:83:3d:4d:50:01:bf:20:c6:28:80:9b:01:a7:bf:ee:2a:fc:be:47:01:bb:35:56:85:7a:a2:b6:81:fd:d9:a7:3d:9e:dc:09:d9:75:80:af:e1:73:85:3f:78:1e:01:25:a1:82:4f:96:f5:b4:50:cb:43:12:c5:c5:72:fd:1b:3d:96:7e:f1:e3:ad:9b:3b:b4:42:f7:6e:00:2d:6a:be:34:10:9a:20:22:22:05:98:c6:81:8c:57:33:a6:30:92:b9:33:2a:e7:de:dc:36:45:a5:65:37:b6:5e:c3:07:54:fb:7f:c7:cb:ce:69:a7:9f:33:23:05:81:3a:c2:4a:22:c2:66:ff:aa:48:bf:35:12:bb:e7:69:da:55:01:e2:d5:19:ba:4a:31:80:11:e0:aa:81:4c:33:bf:ce:07:4c:69:8b:91:e6:19:e4:1e:0c:3b:84:54:d5:6a:4e:17:8a:9a:cb:54:01:e5:21:d9:3b:6c:d6:84:1f:b3:a6:6a:59:58:86:60:f4:86:e9:bb:04:fc:c2:02:6d:72:66:38:b9:22:a7:8b:da:5b:d5:d0:19:b0:bf:d1:12:72:95:c3:61:59:1e:11:cc:4d:04:23:92:ee:54:20:b8:7f:0c:b7:fa:05:9e:fc:5c:8a:00:4c:20:22:2a:ae:9e:60:9c:d9:49:20:ec:1c:4e:90:f5"
        }


capinfos
-----------------------------------

capinfos 2022-03-30-cc.pcapng

.. code-block::

    File name:           2022-03-30-cc.pcapng
    File type:           Wireshark/... - pcapng
    File encapsulation:  Ethernet
    File timestamp precision:  microseconds (6)
    Packet size limit:   file hdr: (not set)
    Number of packets:   7678
    File size:           3759kB
    Data size:           3499kB
    Capture duration:    33.521948 seconds
    First packet time:   2022-03-30 10:35:27.550761
    Last packet time:    2022-03-30 10:36:01.072709
    Data byte rate:      104kBps
    Data bit rate:       835kbps
    Average packet size: 455.83 bytes
    Average packet rate: 229 packets/s
    SHA256:              6f9cee42a2be4b704e150643671d679eca1f6c7438f3a98e45602325191a6de4
    RIPEMD160:           c1daaf4f78d797c31e6491402a2b32875d44950b
    SHA1:                d62393f0fc44e798b572e0f2cbb5ec6d470d647f
    Strict time order:   False
    Capture hardware:    Intel(R) Core(TM) i7-8650U CPU @ 1.90GHz (with SSE4.2)
    Capture oper-sys:    64-bit Windows 10 (2009), build 19042
    Capture application: Dumpcap (Wireshark) 3.4.2 (v3.4.2-0-ga889cf1b1bf9)
    Number of interfaces in file: 1
    ...




Capturing RTP streams
====================================
1. Select the network interface currently used for RTP traffic and start a capture.

2. Right click on any package in the capture view and select Decode as.

3. Make sure Both (src/dst port <> src/dst port) is selected in the drop-down menu.

4. On the right scroll down to and select RTP then click OK.

5. RTP packets should now be visible with SSRC details in the info column.

   - If Unknown RTP version 0 appears its most likely not a RTP packet.

   - If Unknown RTP version 1 appears it’s most likely RTP encapsulated in a TURN packet, see the Capturing TURN RTP streams section on how to capture them properly.

6. Go to the Telephony menu and select RTP then Show All Streams.

7. A popup window should appear with lots of RTP streams.

8. The RTP payload types indicate which codec is in use. For payload types between 96 and 128, they are assigned in the SDP negotiation setting up the RTP streams, but browsers typically have preferred values.

The ones we are interested in typically have a payload type 96 (VP8 in Chrome), 111 (Opus in Chrome) and 127 (VP8 with RED in Chrome). Firefox and Opera may have different payload types for VP8 etc.

Sorting by number of packets is usually a good approach to filter out the relevant streams.

9. If an rtcdump file is desired select a stream and click Save As.

Capturing TURN RTP streams
======================================

1. First we need to enable the Try to decode RTP outside of conversations option.

  1) In Wireshark press Shift+Ctrl+p to bring up the preferences window.

  2) In the menu to the left, expand protocols.

  3) Scroll down to RTP.

  4) Check the Try to decode RTP outside of conversations checkbox.

  5) Click OK.

7. Now perform the steps in Capturing RTP streams section but skip the Decode As steps (2-4)


text2cap
=================

Text2pcap understands a hexdump of the form generated by od -Ax -tx1 -v. In other words, each byte is individually displayed, with spaces separating the bytes from each other. Each line begins with an offset describing the position in the packet, each new packet starts with an offset of 0 and there is a space separating the offset from the following bytes. The offset is a hex number (can also be octal or decimal - see -o), of more than two hex digits.

Here is a sample dump that text2pcap can recognize:

000000 00 0e b6 00 00 02 00 0e b6 00 00 01 08 00 45 00
000010 00 28 00 00 00 00 ff 01 37 d1 c0 00 02 01 c0 00
000020 02 02 08 00 a6 2f 00 01 00 01 48 65 6c 6c 6f 20
000030 57 6f 72 6c 64 21
000036


FAQ
=================

how to convert pcap to text
--------------------------------------

.. code-block::

    tcpdump -r input.pcap > output.txt
    # it works for text2pcap of wireshare
    tshark -V -r input.pcap > output.txt

how to convert text to pcap
--------------------------------------

.. code-block::

   tshark -i - < "c:\filename.cap" > "c:\output.txt


How to list interfaces
------------------------

.. code-block::

    tshark -D


Reference
=================
* https://webrtc.github.io/webrtc-org/testing/wireshark/
* https://www.wireshark.org/docs/man-pages/text2pcap.html
* https://tshark.dev/edit/text2pcap/
* https://wiki.wireshark.org/RTP_statistics