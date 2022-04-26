
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



Usage
===========================

.. code-block::

    wget -O /usr/bin/iperf3 https://iperf.fr/download/ubuntu/iperf3_3.1.3 --no-check-certificate

    chmod +x /usr/bin/iperf3

    ldconfig /usr/local/lib

    /usr/bin/iperf3 -s <source_address> -f M -p <port>


Reference
=======================
* https://iperf.fr/iperf-doc.php

