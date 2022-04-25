########################
SCTP 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** SCTP protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

What
=======================


SCTP packet format
----------------------------------------

.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                        Common Header                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                          Chunk #1                             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                           ...                                 |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                          Chunk #n                             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

SCTP Common Header Format
----------------------------------------

.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |     Source Port Number        |     Destination Port Number   |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                      Verification Tag                         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                           Checksum                            |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


SCTP Chunk fields
-----------------------------------------

.. code-block::

           0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Chunk Type  | Chunk  Flags  |        Chunk Length           |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /                          Chunk Value                          /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

* Chunk Type: 8 bits (unsigned integer)


.. code-block::

      ID Value    Chunk Type
      -----       ----------
      0          - Payload Data (DATA)
      1          - Initiation (INIT)
      2          - Initiation Acknowledgement (INIT ACK)
      3          - Selective Acknowledgement (SACK)
      4          - Heartbeat Request (HEARTBEAT)
      5          - Heartbeat Acknowledgement (HEARTBEAT ACK)
      6          - Abort (ABORT)
      7          - Shutdown (SHUTDOWN)
      8          - Shutdown Acknowledgement (SHUTDOWN ACK)
      9          - Operation Error (ERROR)
      10         - State Cookie (COOKIE ECHO)
      11         - Cookie Acknowledgement (COOKIE ACK)
      12         - Reserved for Explicit Congestion Notification Echo   (ECNE)
      13         - Reserved for Congestion Window Reduced (CWR)
      14         - Shutdown Complete (SHUTDOWN COMPLETE)
      15 to 62   - available
      63         - reserved for IETF-defined Chunk Extensions
      64 to 126  - available
      127        - reserved for IETF-defined Chunk Extensions
      128 to 190 - available
      191        - reserved for IETF-defined Chunk Extensions
      192 to 254 - available
      255        - reserved for IETF-defined Chunk Extensions

Chunk Types are encoded such that the highest-order 2 bits specify the action that must be taken
if the processing endpoint does not recognize the Chunk Type.


.. code-block::

      00 -  Stop processing this SCTP packet and discard it, do not
            process any further chunks within it.

      01 -  Stop processing this SCTP packet and discard it, do not
            process any further chunks within it, and report the
            unrecognized chunk in an 'Unrecognized Chunk Type'.

      10 -  Skip this chunk and continue processing.

      11 -  Skip this chunk and continue processing, but report in an
            ERROR chunk using the 'Unrecognized Chunk Type' cause of
            error.

  - Optional/Variable-Length Parameter Format

Chunk values of SCTP control chunks consist of a chunk-type-specific header of required fields, followed by zero or more parameters.

The optional and variable-length parameters contained in a chunk are defined in a Type-Length-Value format as shown below.


.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |          Parameter Type       |       Parameter Length        |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /                       Parameter Value                         /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



SCTP Chunk data definition
-----------------------------------------


1. Payload Data (DATA) (0)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 0    | Reserved|U|B|E|    Length                     |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                              TSN                              |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |      Stream Identifier S      |   Stream Sequence Number n    |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                  Payload Protocol Identifier                  |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /                 User Data (seq n of Stream S)                 /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



2.  Initiation (INIT) (1)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 1    |  Chunk Flags  |      Chunk Length             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                         Initiate Tag                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |           Advertised Receiver Window Credit (a_rwnd)          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |  Number of Outbound Streams   |  Number of Inbound Streams    |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                          Initial TSN                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /              Optional/Variable-Length Parameters              /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


3.  Initiation Acknowledgement (INIT ACK) (2)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 2    |  Chunk Flags  |      Chunk Length             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                         Initiate Tag                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |              Advertised Receiver Window Credit                |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |  Number of Outbound Streams   |  Number of Inbound Streams    |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                          Initial TSN                          |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /              Optional/Variable-Length Parameters              /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

4.  Selective Acknowledgement (SACK) (3)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 3    |Chunk  Flags   |      Chunk Length             |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                      Cumulative TSN Ack                       |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |          Advertised Receiver Window Credit (a_rwnd)           |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       | Number of Gap Ack Blocks = N  |  Number of Duplicate TSNs = X |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |  Gap Ack Block #1 Start       |   Gap Ack Block #1 End        |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       /                                                               /
       \                              ...                              \
       /                                                               /
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Gap Ack Block #N Start      |  Gap Ack Block #N End         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                       Duplicate TSN 1                         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       /                                                               /
       \                              ...                              \
       /                                                               /
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                       Duplicate TSN X                         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


5.  Heartbeat Request (HEARTBEAT) (4)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 4    | Chunk  Flags  |      Heartbeat Length         |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /            Heartbeat Information TLV (Variable-Length)        /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


6.  Heartbeat Acknowledgement (HEARTBEAT ACK) (5)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 5    | Chunk  Flags  |    Heartbeat Ack Length       |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /            Heartbeat Information TLV (Variable-Length)        /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



7.  Abort Association (ABORT) (6)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 6    |Reserved     |T|           Length              |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /                   zero or more Error Causes                   /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

8.  Shutdown Association (SHUTDOWN) (7)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 7    | Chunk  Flags  |      Length = 8               |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |                      Cumulative TSN Ack                       |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


9.  Shutdown Acknowledgement (SHUTDOWN ACK) (8)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 8    |Chunk  Flags   |      Length = 4               |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


10.  Operation Error (ERROR) (9)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 9    | Chunk  Flags  |           Length              |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       \                                                               \
       /                    one or more Error Causes                   /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


* Cause Code: 16 bits (unsigned integer)

.. code-block::



      Defines the type of error conditions being reported.

         Cause Code
         Value           Cause Code
         ---------      ----------------
          1              Invalid Stream Identifier
          2              Missing Mandatory Parameter
          3              Stale Cookie Error
          4              Out of Resource
          5              Unresolvable Address
          6              Unrecognized Chunk Type
          7              Invalid Mandatory Parameter
          8              Unrecognized Parameters
          9              No User Data
         10              Cookie Received While Shutting Down
         11              Restart of an Association with New Addresses
         12              User Initiated Abort
         13              Protocol Violation


* Restart of an Association with New Addresses (11)


.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |         Cause Code=11         |      Cause Length=Variable    |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       /                       New Address TLVs                        /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


*  User-Initiated Abort (12)


.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |         Cause Code=12         |      Cause Length=Variable    |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       /                    Upper Layer Abort Reason                   /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


1.   Cookie Echo (COOKIE ECHO) (10)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 10   |Chunk  Flags   |         Length                |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       /                     Cookie                                    /
       \                                                               \
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


1.   Cookie Acknowledgement (COOKIE ACK) (11)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 11   |Chunk  Flags   |     Length = 4                |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


1.   Shutdown Complete (SHUTDOWN COMPLETE) (14)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.. code-block::


        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
       |   Type = 14   |Reserved     |T|      Length = 4               |
       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


SCTP Association State Diagram
------------------------------------

.. code-block::


                      -----          -------- (from any state)
                    /       \      /  rcv ABORT      [ABORT]
   rcv INIT        |         |    |   ----------  or ----------
   --------------- |         v    v   delete TCB     snd ABORT
   generate Cookie  \    +---------+                 delete TCB
   snd INIT ACK       ---|  CLOSED |
                         +---------+
                          /      \      [ASSOCIATE]
                         /        \     ---------------
                        |          |    create TCB
                        |          |    snd INIT
                        |          |    strt init timer
         rcv valid      |          |
       COOKIE  ECHO     |          v
   (1) ---------------- |      +------------+
       create TCB       |      | COOKIE-WAIT| (2)
       snd COOKIE ACK   |      +------------+
                        |          |
                        |          |    rcv INIT ACK
                        |          |    -----------------
                        |          |    snd COOKIE ECHO
                        |          |    stop init timer
                        |          |    strt cookie timer
                        |          v
                        |      +--------------+
                        |      | COOKIE-ECHOED| (3)
                        |      +--------------+
                        |          |
                        |          |    rcv COOKIE ACK
                        |          |    -----------------
                        |          |    stop cookie timer
                        v          v
                      +---------------+
                      |  ESTABLISHED  |
                      +---------------+
                                  |
                                  |
                         /--------+--------\
     [SHUTDOWN]         /                   \
     -------------------|                   |
     check outstanding  |                   |
     DATA chunks        |                   |
                        v                   |
                   +---------+              |
                   |SHUTDOWN-|              | rcv SHUTDOWN
                   |PENDING  |              |------------------
                   +---------+              | check outstanding
                        |                   | DATA chunks
   No more outstanding  |                   |
   ---------------------|                   |
   snd SHUTDOWN         |                   |
   strt shutdown timer  |                   |
                        v                   v
                   +---------+        +-----------+
               (4) |SHUTDOWN-|        | SHUTDOWN- |  (5,6)
                   |SENT     |        | RECEIVED  |
                   +---------+        +-----------+
                        |  \                |
   (A) rcv SHUTDOWN ACK  |   \               |
   ----------------------|    \              |
   stop shutdown timer   |     \rcv:SHUTDOWN |
   send SHUTDOWN COMPLETE|      \  (B)       |
   delete TCB            |       \           |
                         |        \          | No more outstanding
                         |         \         |-----------------
                         |          \        | send SHUTDOWN ACK
   (B)rcv SHUTDOWN       |           \       | strt shutdown timer
   ----------------------|            \      |
   send SHUTDOWN ACK     |             \     |
   start shutdown timer  |              \    |
   move to SHUTDOWN-     |               \   |
   ACK-SENT              |                |  |
                         |                v  |
                         |             +-----------+
                         |             | SHUTDOWN- | (7)
                         |             | ACK-SENT  |
                         |             +----------+-
                         |                   | (C)rcv SHUTDOWN COMPLETE
                         |                   |-----------------
                         |                   | stop shutdown timer
                         |                   | delete TCB
                         |                   |
                         |                   | (D)rcv SHUTDOWN ACK
                         |                   |--------------
                         |                   | stop shutdown timer
                         |                   | send SHUTDOWN COMPLETE
                         |                   | delete TCB
                         |                   |
                         \    +---------+    /
                          \-->| CLOSED  |<--/
                              +---------+

SCTP over DTLS
--------------------------

.. code-block::

            +----------+
            |   SCTP   |
            +----------+
            |   DTLS   |
            +----------+
            | ICE/UDP  |
            +----------+

   Figure 1: Basic Stack Diagram



This document uses SCTP [RFC4960] with the following restrictions, which are required to reflect that the lower layer is DTLS
instead of IPv4 and IPv6 and that SCTP does not deal with the IP addresses or the transport protocol used below DTLS:

o  A DTLS connection MUST be established before an SCTP association can be set up.

o  Multiple SCTP associations MAY be multiplexed over a single DTLS connection.

The SCTP port numbers are used for multiplexing and demultiplexing the SCTP associations carried over a single DTLS connection.

o  All SCTP associations are single-homed, because DTLS does not expose any address management to its upper layer.

Therefore, it is RECOMMENDED to set the SCTP parameter path.max.retrans to association.max.retrans.

o  The INIT and INIT-ACK chunk MUST NOT contain any IPv4 Address or IPv6 Address parameters.

The INIT chunk MUST NOT contain the Supported Address Types parameter.

o  The implementation MUST NOT rely on processing ICMP or ICMPv6 packets, since the SCTP layer most likely is unable to access the
   SCTP common header in the plain text of the packet, which triggered the sending of the ICMP or ICMPv6 packet.

   This applies in particular to path MTU discovery when performed by SCTP.




Tuexen, et al.               Standards Track                    [Page 5]

RFC 8261                     SCTP over DTLS                November 2017


   o  If the SCTP layer is notified about a path change by its lower
      layers, SCTP SHOULD retest the path MTU and reset the congestion
      state to the initial state.  The window-based congestion control
      method specified in [RFC4960] resets the congestion window and
      slow-start threshold to their initial values.


Why
=======================


SCTP over DTLS
-----------------------

DTLS/SCTP supports:

*  preservation of message boundaries.
*  a large number of unidirectional and bidirectional streams.
*  ordered and unordered delivery of SCTP user messages.
*  the partial reliability extension as defined in [RFC3758].
*  the dynamic address reconfiguration extension as defined in [RFC5061].

However, the following limitations still apply:

*  The maximum user message size is 2^14 bytes, which is the DTLS limit.
*  The DTLS user cannot perform the SCTP-AUTH key management because  this is done by the DTLS layer.


How
=======================


SDP
-----------------------

.. code-block::


   m=application 9 UDP/DTLS/SCTP webrtc-datachannel
   c=IN IP4 0.0.0.0
   a=ice-ufrag:u8aT
   a=ice-pwd:nTH+98fL7o+XacAd//X7uStI
   a=ice-options:trickle
   a=fingerprint:sha-256 6E:FD:8F:7C:E7:6B:DF:2B:6F:D6:32:B6:A6:00:62:D5:7E:4E:11:91:91:37:95:BE:2C:00:3F:B2:67:6F:DF:3C
   a=setup:actpass
   a=mid:4
   a=sctp-port:5000
   a=max-message-size:262144

Example
=======================



Conclusion
=======================



Reference
========================
RFC4960: Stream Control Transmission Protocol

RFC6083: Datagram Transport Layer Security (DTLS) for Stream Control Transmission Protocol (SCTP)

RFC8261: Datagram Transport Layer Security (DTLS) Encapsulation of SCTP Packets
RFC8841: Session Description Protocol (SDP) Offer/Answer Procedures for Stream Control Transmission Protocol (SCTP) over Datagram Transport Layer Security (DTLS) Transport
RFC8831: WebRTC Data Channels", RFC 8831
RFC8832: WebRTC Data Channel Establishment Protocol
RFC8864: Negotiation Data Channels Using the Session Description Protocol (SDP)