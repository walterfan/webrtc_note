#################
scapy
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** scapy
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

简介
====================
Scapy is a packet manipulation tool for computer networks, written in Python by Philippe Biondi.

.. code-block::

   pip install scapy
   scapy
   >>> ls(IP)
   version    : BitField (4 bits)                   = (4)
   ihl        : BitField (4 bits)                   = (None)
   tos        : XByteField                          = (0)
   len        : ShortField                          = (None)
   id         : ShortField                          = (1)
   flags      : FlagsField (3 bits)                 = (<Flag 0 ()>)
   frag       : BitField (13 bits)                  = (0)
   ttl        : ByteField                           = (64)
   proto      : ByteEnumField                       = (0)
   chksum     : XShortField                         = (None)
   src        : SourceIPField                       = (None)
   dst        : DestIPField                         = (None)
   options    : PacketListField                     = ([])
   >>> ls(TCP)
   sport      : ShortEnumField                      = (20)
   dport      : ShortEnumField                      = (80)
   seq        : IntField                            = (0)
   ack        : IntField                            = (0)
   dataofs    : BitField (4 bits)                   = (None)
   reserved   : BitField (3 bits)                   = (0)
   flags      : FlagsField (9 bits)                 = (<Flag 2 (S)>)
   window     : ShortField                          = (8192)
   chksum     : XShortField                         = (None)
   urgptr     : ShortField                          = (0)
   options    : TCPOptionsField                     = ([])
   >>> ls(UDP)
   sport      : ShortEnumField                      = (53)
   dport      : ShortEnumField                      = (53)
   len        : ShortField                          = (None)
   chksum     : XShortField                         = (None)

   >>> IP()
   <IP |>
   >>> IP()/TCP()
   <IP frag=0 proto=TCP |<TCP |>>
   >>> Ether()/IP()/TCP()
   <Ether type=0x800 |<IP frag=0 proto=TCP |<TCP |>>>
   >>> IP()/TCP()/"GET / HTTP/1.0\r\n\r\n"
   <IP frag=0 proto=TCP |<TCP |<Raw load='GET / HTTP/1.0\r\n\r\n' |>>>
   >>> Ether()/IP()/IP()/UDP()
   <Ether type=0x800 |<IP frag=0 proto=IP |<IP frag=0 proto=UDP |<UDP |>>>>
   >>> IP(proto=55)/TCP()
   <IP frag=0 proto=55 |<TCP |>>



   >>> raw(IP())
   'E\x00\x00\x14\x00\x01\x00\x00@\x00|\xe7\x7f\x00\x00\x01\x7f\x00\x00\x01'
   >>> IP(_)
   <IP version=4L ihl=5L tos=0x0 len=20 id=1 flags= frag=0L ttl=64 proto=IP
   chksum=0x7ce7 src=127.0.0.1 dst=127.0.0.1 |>
   >>> a=Ether()/IP(dst="www.slashdot.org")/TCP()/"GET /index.html HTTP/1.0 \n\n"
   >>> hexdump(a)
   00 02 15 37 A2 44 00 AE F3 52 AA D1 08 00 45 00  ...7.D...R....E.
   00 43 00 01 00 00 40 06 78 3C C0 A8 05 15 42 23  .C....@.x<....B#
   FA 97 00 14 00 50 00 00 00 00 00 00 00 00 50 02  .....P........P.
   20 00 BB 39 00 00 47 45 54 20 2F 69 6E 64 65 78   ..9..GET /index
   2E 68 74 6D 6C 20 48 54 54 50 2F 31 2E 30 20 0A  .html HTTP/1.0 .
   0A


Commands
===================


| Command | Effect |
|---------|--------|
| raw(pkt) | assemble the packet |
| hexdump(pkt) | have a hexadecimal dump |
| ls(pkt) | have the list of fields values |
| pkt.summary() | for a one-line summary |
| pkt.show() | for a developed view of the packet |
| pkt.show2() | same as show but on the assembled packet (checksum is calculated, for instance) |
| pkt.sprintf()|  fills a format string with fields values of the packet |
| pkt.decode_payload_as()| changes the way the payload is decoded |
| pkt.psdump() | draws a PostScript diagram with explained dissection |
| pkt.pdfdump() | draws a PDF with explained dissection |
| pkt.command()| return a Scapy command that can generate the packet |

抓包
===================

.. code-block::

   from scapy.all import *
   dpkt = sniff(iface = "wlp7s0", count = 100)

参考资料
====================
* https://github.com/phaethon/scapy
* http://phaethon.github.io/scapy/api/
* http://scapy.readthedocs.io/en/latest/usage.html