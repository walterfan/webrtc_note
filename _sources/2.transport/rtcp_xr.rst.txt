##############################
RTCP XR
##############################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** RTCP XR
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==========================


RFC3611 RTCP Extended Reports (RTCP XR)

packet-by-packet block types:

* Loss RLE Report Block: Run length encoding of reports concerning the losses and receipts of RTP packets.
* Duplicate RLE Report Block: Run length encoding of reports concerning duplicates of received RTP packets.
* Packet Receipt Times Report Block: A list of reception timestamps of RTP packets.


reference time related block types:

* Receiver Reference Time Report Block: Receiver-end wallclock timestamps. Together with the DLRR Report Block mentioned next, these allow non-senders to calculate round-trip times.
* DLRR Report Block: The delay since the last Receiver Reference Time Report Block was received.

Two summary metric block types:
* Statistics Summary Report Block: Statistics on RTP packet sequence numbers, losses, duplicates, jitter, and TTL or Hop Limit values.
* VoIP Metrics Report Block: Metrics for monitoring Voice over IP (VoIP) calls



XR Packet Format
===========================

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |V=2|P|reserved |   PT=XR=207   |             length            |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                              SSRC                             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :                         report blocks                         :
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


version (V): 2 bits
      Identifies the version of RTP.  This specification applies to
      RTP version two.

padding (P): 1 bit
      If the padding bit is set, this XR packet contains some
      additional padding octets at the end.  The semantics of this
      field are identical to the semantics of the padding field in
      the SR packet, as defined by the RTP specification.

reserved: 5 bits
      This field is reserved for future definition.  In the absence
      of such definition, the bits in this field MUST be set to zero
      and MUST be ignored by the receiver.


packet type (PT): 8 bits
      Contains the constant 207 to identify this as an RTCP XR
      packet.  This value is registered with the Internet Assigned
      Numbers Authority (IANA), as described in Section 6.1.

length: 16 bits
      As described for the RTCP Sender Report (SR) packet (see
      Section 6.4.1 of the RTP specification [9]).  Briefly, the
      length of this XR packet in 32-bit words minus one, including
      the header and any padding.

SSRC: 32 bits
      The synchronization source identifier for the originator of
      this XR packet.

report blocks: variable length.
      Zero or more extended report blocks.  In keeping with the
      extended report block framework defined below, each block MUST
      consist of one or more 32-bit words.


Extended Report Block Framework
==========================================

Extended report blocks are stacked, one after the other, at the end
of an XR packet.  An individual block's length is a multiple of 4
octets.  The XR header's length field describes the total length of
the packet, including these extended report blocks.

Each block has block type and length fields that facilitate parsing.
A receiving application can demultiplex the blocks based upon their
type, and can use the length information to locate each successive
block, even in the presence of block types it does not recognize.

An extended report block has the following format:

.. code-block::

    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |      BT       | type-specific |         block length          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   :             type-specific block contents                      :
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* block type (BT): 8 bits

Identifies the block format.  Seven block types are defined in
Section 4.  Additional block types may be defined in future
specifications.  This field's name space is managed by the
Internet Assigned Numbers Authority (IANA), as described in
Section 6.2.

* type-specific: 8 bits

The use of these bits is determined by the block type definition.

* block length: 16 bits

The length of this report block, including the header, in 32-
bit words minus one.  If the block type definition permits,
zero is an acceptable value, signifying a block that consists
of only the BT, type-specific, and block length fields, with a
null type-specific block contents field.

*  type-specific block contents: variable length

The use of this field is defined by the particular block type,
subject to the constraint that it MUST be a multiple of 32 bits
long.  If the block type definition permits, It MAY be zero
bits long.


.. csv-table:: "RTCP Extended Report Block"
   :header: "类型", "名称", "内容"
   :widths: 30, 30, 40

   1,  "Loss RLE Report Block", "Run Length Chunk, Bit Vector Chunk, Terminating Null Chunk"
   2,  "Duplicate RLE Report Block", ""
   3,  "Packet Receipt Times Report Block", ""
   4,  "Receiver Reference Time Report Block", ""
   5,  "DLRR Report Block", ""
   6,  "Statistics Summary Report Block", ""
   7,  "VoIP Metrics Report Block", "Packet Loss and Discard Metrics, Burst Metrics, Delay Metrics, Signal Related Metrics, Call Quality or Transmission Quality Metrics, Configuration Parameters, Jitter Buffer Parameters"