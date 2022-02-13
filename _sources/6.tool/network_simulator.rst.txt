######################
Network Simulator
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Network Simulator
**Authors**  Walter Fan
**Category** Learning note
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

简介
====================
ns-3 is a discrete-event network simulator for Internet systems, targeted primarily for research and educational use. 
ns-3 is free, open-source software, licensed under the GNU GPLv2 license, and maintained by a worldwide community.


安装
====================

.. code-block::

    wget https://www.nsnam.org/release/ns-allinone-3.35.tar.bz2
    tar xjf ns-allinone-3.35.tar.bz2
    cd ns-allinone-3.35
    ./build.py --enable-examples --enable-tests
    ./test.py


或者

.. code-block::

    cd ns-allinone-3.35/ns-3.35   
   ./waf configure --enable-examples --enable-tests
   ./waf build

或者

.. code-block::

    git clone https://gitlab.com/nsnam/ns-3-dev.git
    ./ns3 configure --enable-examples
    ./ns3

run in docker
-----------------

* Dockerfile:


.. code-block::

    FROM ubuntu:latest
    MAINTAINER Ryan Kurte <ryankurte@gmail.com>
    LABEL Description="Docker image for NS-3 Network Simulator"

    RUN apt-get update

    # General dependencies
    RUN apt-get install -y \
    git \
    mercurial \
    wget \
    vim \
    autoconf \
    bzr \
    cvs \
    unrar \
    build-essential \
    clang \
    valgrind \
    gsl-bin \
    libgsl2 \
    libgsl-dev \
    flex \
    bison \
    libfl-dev \
    tcpdump \
    sqlite \
    sqlite3 \
    libsqlite3-dev \
    libxml2 \
    libxml2-dev \
    vtun \
    lxc

    # QT4 components
    RUN apt-get install -y \
    qtbase5-dev

    # Python components
    RUN apt-get install -y \
    python \
    python-dev \
    python-setuptools \
    cmake \
    libc6-dev \
    libc6-dev-i386 \
    g++-multilib

    # NS-3

    # Create working directory
    RUN mkdir -p /usr/ns3
    WORKDIR /usr

    # Fetch NS-3 source
    RUN wget http://www.nsnam.org/release/ns-allinone-3.26.tar.bz2
    RUN tar -xf ns-allinone-3.26.tar.bz2

    # Configure and compile NS-3
    RUN cd ns-allinone-3.26 && ./build.py --enable-examples --enable-tests

    RUN ln -s /usr/ns-allinone-3.26/ns-3.26/ /usr/ns3/

    # Cleanup
    RUN apt-get clean && \
    rm -rf /var/lib/apt && \
    rm /usr/ns-allinone-3.26.tar.bz2

.. code-block::

    git clone git@github.com:ryankurte/docker-ns3.git
    cd docker-ns3
    docker run --rm -it -v `pwd`:/work ryankurte/docker-ns3
    > ./test.py -c core

测试
=====================

.. code-block::

    ./waf --run hello-simulator

waf usage
---------------------

waf is a python build tool

基本概念
==========================
* Node 节点

* Application 应用程序

* Channel 通道

* Net Device 网络设备

* Topology 拓扑结构


示例程序
==========================

.. code-block::

    ./ns3 --run simple-global-routing
    tcpdump -tt -r simple-global-routing-1-1.pcap


first.cc
--------------------------

.. code-block::

    int main (int argc, char *argv[])
    {
        CommandLine cmd (__FILE__);
        cmd.Parse (argc, argv);
        
        Time::SetResolution (Time::NS);
        LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_INFO);
        LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_INFO);

        NodeContainer nodes;
        nodes.Create (2);

        PointToPointHelper pointToPoint;
        pointToPoint.SetDeviceAttribute ("DataRate", StringValue ("5Mbps"));
        pointToPoint.SetChannelAttribute ("Delay", StringValue ("2ms"));

        NetDeviceContainer devices;
        devices = pointToPoint.Install (nodes);

        InternetStackHelper stack;
        stack.Install (nodes);

        Ipv4AddressHelper address;
        address.SetBase ("10.1.1.0", "255.255.255.0");

        Ipv4InterfaceContainer interfaces = address.Assign (devices);

        UdpEchoServerHelper echoServer (9);

        ApplicationContainer serverApps = echoServer.Install (nodes.Get (1));
        serverApps.Start (Seconds (1.0));
        serverApps.Stop (Seconds (10.0));

        UdpEchoClientHelper echoClient (interfaces.GetAddress (1), 9);
        echoClient.SetAttribute ("MaxPackets", UintegerValue (1));
        echoClient.SetAttribute ("Interval", TimeValue (Seconds (1.0)));
        echoClient.SetAttribute ("PacketSize", UintegerValue (1024));

        ApplicationContainer clientApps = echoClient.Install (nodes.Get (0));
        clientApps.Start (Seconds (2.0));
        clientApps.Stop (Seconds (10.0));

        Simulator::Run ();
        Simulator::Destroy ();
        return 0;
    }

参考资料
===============
* https://www.nsnam.org/docs/release/3.35/tutorial/html/getting-started.html#getting-started