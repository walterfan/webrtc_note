###################
WebRTC RTCP Usage
##################

.. toctree::
   :maxdepth: 1
   :caption: 目录

   rtcp_sr
   rtcp_rr
   rtcp_xr


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC RTCP Usage
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



Overview
===================

RTCP specifies report PDUs exchanged between sources and destinations of multimedia information

  * receiver reception report
  * sender report
  * source description report

* Reports contain statistics such as the number of RTP-PDUs sent, number of RTP-PDUs lost, inter-arrival jitter
* Used by application to modify sender transmission rates and for diagnostics purposes



.. csv-table:: RTCP Packet
   :header: "类型", "缩写", "名称“， ”参考文档"
   :widths: 20, 20, 30, 30

    200, SR, Sender Report, `RFC3550`_
    201, RR, Receiver Report, `RFC3550`_
    202, SDES, Source Description, `RFC3550`_
    203, BYE, Goodbye, `RFC3550`_
    204, APP, Application defined, `RFC3550`_
    205, RTPFB, Generic RTP feedback, `RFC4585`_
    206, PSFB, Payload specfic feedback, `RFC4585`_
    207, XR, Extended Report, `RFC3611`_


200 Sender Report
-----------------------------------------------

`RTCP SR <rtcp_sr.html>`_



201 Receiver Report
-----------------------------------------------

`RTCP RR <rtcp_rr.html>`_


202 Source Description RTCP Packets (SDES)
------------------------------------------------

A SDES packet consists of a SDES header and a variable number of chunks for the described sources. Each chunk in turn consists of a SSRC/CSRC identifier and a collection of SDES items. SDES items themselves consists of a SDES item type code (8 bits), a length field (8 bits) and as much text octets as the length field indicates.

SDES Header

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|    SC   |  PT=SDES=202  |            length L           |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |                          SSRC/CSRC_1                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SDES items                          |
    |                              ...                              |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |                          SSRC/CSRC_2                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SDES items                          |
    |                              ...                              |
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

* V, P, PT, L: As described for SR packets, with the packet type code set to 202.
* SC: 5 bits, The number of SSRC/CSRC chunks contained in this SDES packet.

The different SDES items are encoded according to a type-length-value scheme. Currently, CNAME, NAME, EMAIL, PHONE, LOC, TOOL, NOTE, and PRIV items are defined in [RFC1889].
The CNAME item is mandatory in every SDES packet, which in turn is mandatory part of every compound RTCP packet.
Like the SSRC identifier, a CNAME must differ from the CNAMEs of every other session participants. But instead of choosing the CNAME identifier randomly, the CNAME should allow both a person or a program to locate the source by means of the CNAME contents.


.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |    CNAME=1    |     length    | user and domain name         ...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+




203 Goodbye RTCP Packets (BYE)
-----------------------------------

A participant sends a BYE packet to indicate that one or more sources are no longer active, optionally giving a reason for leaving.

.. code-block::

    0               1               2               3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |V=2|P|    SC   |   PT=BYE=203  |            length L           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           SSRC/CSRC                           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    :                              ...                              :
    +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    |     length    |               reason for leaving (opt)       ...
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* V, P, PT, L, SSRC/CSRC: As described for SR packets, with the packet type code 202 set.
* SC:5 bits, The number of SSRC/CSRC identifiers contained in this BYE packet.