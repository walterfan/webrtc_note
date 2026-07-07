
########################
iPerf
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** iPerf
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
=========================

iPerf - The ultimate speed test tool for TCP, UDP and SCTP

iPerf3 is a tool for active measurements of the maximum achievable bandwidth on IP networks. 

It supports tuning of various parameters related to timing, buffers and protocols (TCP, UDP, SCTP with IPv4 and IPv6). 

For each test it reports the bandwidth, loss, and other parameters.



安装
===========================

* iperf2

.. code-block::

    brew install iperf
    apt install iperf

* iperf3

.. code-block::

    wget -O /usr/bin/iperf3 https://iperf.fr/download/ubuntu/iperf3_3.1.3 --no-check-certificate

    chmod +x /usr/bin/iperf3

    ldconfig /usr/local/lib

    /usr/bin/iperf3 -s <source_address> -f M -p <port>

* iperfwindows

http://iperfwindows.com/

用法
==========================


.. code-block::

    Usage: iperf [-s|-c host] [options]
        iperf [-h|--help] [-v|--version]

    Client/Server:
    -b, --bandwidth #[kmgKMG | pps]  bandwidth to read/send at in bits/sec or packets/sec
    -e, --enhanced    use enhanced reporting giving more tcp/udp and traffic information
    -f, --format    [kmgKMG]   format to report: Kbits, Mbits, KBytes, MBytes
        --hide-ips           hide ip addresses and host names within outputs
    -i, --interval  #        seconds between periodic bandwidth reports
    -l, --len       #[kmKM]    length of buffer in bytes to read or write (Defaults: TCP=128K, v4 UDP=1470, v6 UDP=1450)
    -m, --print_mss          print TCP maximum segment size
    -o, --output    <filename> output the report or error message to this specified file
    -p, --port      #        client/server port to listen/send on and to connect
        --permit-key         permit key to be used to verify client and server (TCP only)
        --sum-only           output sum only reports
    -u, --udp                use UDP rather than TCP
    -w, --window    #[KM]    TCP window size (socket buffer size)
    -B, --bind <host>[:<port>][%<dev>] bind to <host>, ip addr (including multicast address) and optional port and device
    -C, --compatibility      for use with older versions does not sent extra msgs
    -M, --mss       #        set TCP maximum segment size using TCP_MAXSEG
    -N, --nodelay            set TCP no delay, disabling Nagle's Algorithm
    -S, --tos       #        set the socket's IP_TOS (byte) field
    -Z, --tcp-congestion <algo>  set TCP congestion control algorithm (Linux only)
    ...

实例
==========================

例 1
--------------------------
* 服务器端

`iperf -s`

* 客户端

`iperf -c 10.224.16.8`


例 2 - TCP
--------------------------


* 服务器端

`iperf -s -i 1 -w 1M`

* 客户端

`iperf -c 10.224.16.8 -i 1 -w 1M`

例 2 - UDP
--------------------------


* 服务器端

`iperf -s -u`

* 客户端

`iperf -c 10.224.16.8 -u -b 900M -i 1 -w 1M -t 60`

Reference
=======================
* https://iperf.fr/iperf-doc.php

