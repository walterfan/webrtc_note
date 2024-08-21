########################
BFCP 协议
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** BFCP protocol
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=======================
BFCP 就是 Binary Floor Control Protocol 的缩写，即二进制发言权控制协议。
例如在礼堂里做演讲，讲台上的座席通常只能有一个人在演讲，另外的人如果想要发言，得走上讲台，抢过发言权，抢过麦克风。

BFCP 这个协议在 `RFC4582`_ 中有详细的阐述。
实践中， 我们有 BFCP 控制者以及 BFCP 参与者的概念之分，好比辩论比赛的主持人(BFCP chair)和辩手(BFCP participant)。

`RFC8855`_ 后来废弃了 `RFC4582`_, 在传输层可以使用 TCP 或者 UDP 来承载 BFCP, 在协议 `RFC8856`_: Session Description Protocol (SDP) Format for Binary Floor Control Protocol (BFCP) Streams 中定义了 BFCP 的 SDP 格式

例如

.. code-block::

    m=application 50000 UDP/BFCP *


Role
-----------
* c-only: The endpoint is willing to act as a floor control client. - 好比主持人
* s-only: The endpoint is willing to act as a floor control server only - 好比辩手


Packet Format
=======================
BFCP packets consist of a 12-octet COMMON-HEADER followed by attributes.
All the protocol values MUST be sent in network byte order.

COMMON-HEADER Format
---------------------------------
The following is the format of the COMMON-HEADER.


.. code-block::

        0                   1                   2                   3
        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        | Ver |R|F| Res |  Primitive    |        Payload Length         |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |                         Conference ID                         |
        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        |         Transaction ID        |            User ID            |
     +> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |  | Fragment Offset (if F is set) | Fragment Length (if F is set) |
     +> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |
     +---- These fragment fields are never present
           when using reliable transports


BFCP Primitive
~~~~~~~~~~~~~~~~~~~~~~~~~~~
This 8-bit field identifies the main purpose of the message.
The following primitive values are defined:

.. csv-table:: "BFCP Primitive"
   :header: "Value", "Primitive", "Direction"
   :widths: 30, 30, 40

    1, FloorRequest, P -> S
    2, FloorRelease, P -> S
    3, FloorRequestQuery, P -> S ; Ch -> S
    4, FloorRequestStatus, P <- S ; Ch <- S
    5, UserQuery, P -> S ; Ch -> S
    6, UserStatus, P <- S ; Ch <- S
    7, FloorQuery, P -> S ; Ch -> S
    8, FloorStatus, P <- S ; Ch <- S
    9, ChairAction, Ch -> S
    10, ChairActionAck, Ch <- S
    11, Hello, P -> S ; Ch -> S
    12, HelloAck, P <- S ; Ch <- S
    13, Error, P <- S ; Ch <- S
    14, FloorRequestStatusAck, P -> S ; Ch -> S
    15, FloorStatusAck, P -> S ; Ch -> S
    16, Goodbye, P -> S ; Ch -> S ; P <- S ; Ch <- S
    17, GoodbyeAck, P -> S ; Ch -> S ; P <- S ; Ch <- S

* S: Floor Control Server
* P: Floor Participant
* Ch: Floor Chair



Attribute Format
----------------------------
BFCP attributes are encoded in TLV (Type-Length-Value) format. Attributes are 32-bit aligned.

.. code-block::

   0                   1                   2                   3
   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |    Type     |M|    Length     |                               |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               |
  |                                                               |
  /                       Attribute Contents                      /
  /                                                               /
  |                                                               |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


BFCP Attributes
~~~~~~~~~~~~~~~~~~~~~~

.. csv-table:: "BFCP Primitive"
   :header: "Value", "Attribute", "Format"
   :widths: 30, 30, 40

    1, BENEFICIARY-ID, Unsigned16
    2, FLOOR-ID, Unsigned16
    3, FLOOR-REQUEST-ID, Unsigned16
    4, PRIORITY, OctetString16
    5, REQUEST-STATUS, OctetString16
    6, ERROR-CODE, OctetString
    7, ERROR-INFO, OctetString
    8, PARTICIPANT-PROVIDED-INFO, OctetString
    9, STATUS-INFO, OctetString
    10, SUPPORTED-ATTRIBUTES, OctetString
    11, SUPPORTED-PRIMITIVES, OctetString
    12, USER-DISPLAY-NAME, OctetString
    13, USER-URI, OctetString
    14, BENEFICIARY-INFORMATION, Grouped
    15, FLOOR-REQUEST-INFORMATION, Grouped
    16, REQUESTED-BY-INFORMATION, Grouped
    17, FLOOR-REQUEST-STATUS, Grouped
    18, OVERALL-REQUEST-STATUS, Grouped



TBD...