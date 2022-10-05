########################
tcpdump
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** tcpdump
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================



.. contents::
   :local:


简介
=========================

.. code-block::


    tcpdump [-aAbdDefhHIJKlLnNOpqStuUvxX#] [ -B size ] [ -c count ]
            [ -C file_size ] [ -E algo:secret ] [ -F file ] [ -G seconds ]
            [ -i interface ] [ -j tstamptype ] [ -M secret ] [ --number ]
            [ -Q in|out|inout ]
            [ -r file ] [ -s snaplen ] [ --time-stamp-precision precision ]
            [ --immediate-mode ] [ -T type ] [ --version ] [ -V file ]
            [ -w file ] [ -W filecount ] [ -y datalinktype ] [ -z postrotate-command ]
            [ -Z user ] [ expression ]


This dumps everything from eth0 into a file with details useful with wireshark.

.. code-block::

    tcpdump -i ens192 -Xvnp -s0 -w /tmp/tcpdump1116.pcap

                     

To capture 10 instances of a particular mini-carousel:

.. code-block::
    
    tcpdump -i eth0 -Xvnp -c 10 -s 0 dst host 232.1.0.15

 

To capture all traffic to and from a particular QAM and save to a capture file:

.. code-block::

    tcpdump  -i eth1 -Xvnp -s 0 host 172.16.4.45 -w /tmp/QAMLongCap.pcap

                          

To see a particular port:

.. code-block::

    tcpdump -i eth0 port 677

                      

To capture 10 - 5 M files for discovery services:

.. code-block::

    tcpdump -ni eth0 -s0 udp dst port 13819 -c5 -w10 -w /tmp/wireshark.pcap

-G # will also set the time for the recording in seconds

-S will not convert the port number to the most commonly used assignment  (this means the host/dest will display as 10.18.11.20.995 instead of 10.18.11.20.pop3s)

Example
====================

short examples:

.. code-block::

    tcpdump -i any # Capture from all interfaces
    tcpdump -i eth0 # Capture from specific interface ( Ex Eth0)
    tcpdump -i eth0 -c 10 # Capture first 10 packets and exit
    tcpdump -D # Show available interfaces
    tcpdump -i eth0 -A # Print in ASCII
    tcpdump -i eth0 -w tcpdump.txt # To save capture to a file
    tcpdump -r tcpdump.txt # Read and analyze saved capture file
    tcpdump -n -i eth0 # Do not resolve host names
    tcpdump -nn -i eth0 # Stop Domain name translation and lookups
    tcpdump -i eth0 -c 10 -w tcpdump.pcap tcp # Capture TCP packets only
    tcpdump -i eth0 port 80 # Capture traffic from a defined port only
    tcpdump host 192.168.1.100 # Capture packets from specific host
    tcpdump net 10.1.1.0/16 # Capture files from network subnet
    tcpdump src 10.1.1.100 # Capture from a specific source address
    tcpdump dst 10.1.1.100 # Capture from a specific destination address
    tcpdump port 80 # Filter traffic based on a port
    tcpdump portrange 21-125 # Filter based on port range
    tcpdump IPV6 # Show only IPV6 packets

    tcpdump -n src 192.168.1.1 and dst port 21 # Combine filtering options
    tcpdump dst 10.1.1.1 or !icmp # Either of the condition can match
    tcpdump dst 10.1.1.1 and not icmp # Negation of the condition
    tcpdump <32 # Shows packets size less than 32
    tcpdump >=32 # Shows packets size greater than 32




Reference
====================
* `TCPDump Primer`_
* `TCPDump Manual`_


.. _TCPDump Primer:  https://danielmiessler.com/study/tcpdump/
.. _TCPDump Manual: https://www.tcpdump.org/manpages/tcpdump.1.html