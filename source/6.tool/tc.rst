########################
Linux Traffic Control
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Linux Traffic Control
**Authors**  Walter Fan
**Status**   v1
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:


简介
=========================
Linux 的 netem 模块和 tc 命令常用来控制网络流量，模拟网络中常见的各种问题

tc 命令
=========================
Tc 用于在 Linux 内核中配置流量控制。流量控制包括以下内容：

* SHAPING 整形
  
当流量被整形时，它的传输速率是受控的。 整形可能不仅仅是降低可用带宽 - 它还用于平滑流量突发以获得更好的网络行为。 
整形发生在出口处。

* SCHEDULING 调度

通过调度数据包的传输，可以提高需要它的流量的交互性，同时仍然保证批量传输的带宽。 
重新排序也称为优先级，仅发生在出口处。

* POLICING 监管

整形处理的是流量的传输，而监管则与到达的流量有关。 因此，监管发生在入口处。

* DROPPING 丢弃

超过设定带宽的流量也可以立即被丢弃，丢弃可发生在入口和出口处

流量的处理由三种对象控制：

* qdiscs 
* classes
* filters


QDISCS
---------------------

qdisc 是 "queueing discipline"（排队规则）的缩写，它是理解流量控制的基础。 
每当内核需要向接口发送数据包时，它就会被放入为该接口配置的 qdisc 队列中。 
紧接着，内核尝试从 qdisc 中获取尽可能多的数据包，以便将它们提供给网络适配器驱动程序。

一个简单的 QDISC 是 "pfifo"，它根本不进行任何处理，是一个纯粹的先进先出队列。 
但是，当网络接口暂时无法处理流量时，它会存储流量。

CLASSES
---------------------

一些 qdisc 可以包含类，这些类包含更多的 qdiscs - 然后流量可以在任何内部 qdisc 中排队，这些内部 qdisc 在类中。 
当内核试图从这样一个有类的 qdisc 队列中取出一个数据包时，它可以来自任何类。 

例如，一个 qdisc 可以通过尝试在其他类之前从某些类中出列来对某些类型的流量进行优先级排序。

FILTERS 过滤器
---------------------

包含有 class 的 qdisc 使用 filter 过滤器来确定数据包将在哪个类中排队。 

每当流量到达具有 subclasses 的 class 时，就需要对其进行分类。 可以采用各种方法来做到这一点，其中之一就是过滤器。 

附加到该类的所有过滤器都会被调用，直到其中一个过滤器返回结果。 如果没有作出裁决，则可能有其他标准可用。 这因 qdisc 的不同而不同。

重要的是要注意过滤器驻留在 qdiscs 中——它们从属于 qdisc，是从属者而非掌控者。

可用的过滤器有:

basic
~~~~~~~~~~~~~~~~~

Filter packets based on an ematch expression. See tc-ematch(8) for details.

bpf
~~~~~~~~~~~~~~~~~

Filter packets using (e)BPF, see tc-bpf(8) for details.

cgroup
~~~~~~~~~~~~~~~~~

Filter packets based on the control group of their process. See tc-cgroup(8) for details.

flow, flower
~~~~~~~~~~~~~~~~~

Flow-based classifiers, filtering packets based on their flow (identified by selectable keys). See tc-flow(8) and tc-flower(8) for details.

fw
~~~~~~~~~~~~~~~~~

Filter based on fwmark. Directly maps fwmark value to traffic class. See tc-fw(8).

route
~~~~~~~~~~~~~~~~~

Filter packets based on routing table. See tc-route(8) for  details.

rsvp
~~~~~~~~~~~~~~~~~

Match Resource Reservation Protocol (RSVP) packets.

tcindex
~~~~~~~~~~~~~~~~~

Filter packets based on traffic control index. See tc-tcindex(8).

u32
~~~~~~~~~~~~~~~~~

Generic filtering on arbitrary packet data, assisted by syntax to abstract common operations. See tc-u32(8) for details.

matchall
~~~~~~~~~~~~~~~~~

Traffic control filter that matches every packet. See tc-matchall(8) for details.


QEVENTS
---------------------

当 qdisc 中发生某些有趣的事件时，Qdisc 可能会调用用户配置的操作。 每个 qevent 可以不使用，也可以附加一个块。 然后使用 `tc block BLOCK_IDX` 语法将过滤器附加到该块。

当与连接点关联的 qevent 发生时，执行该块。 例如，数据包可能会被丢弃或延迟等，具体取决于所讨论的 qdisc 和 qevent。

例如:

.. code-block::

        tc qdisc add dev eth0 root handle 1: red limit 500K avpkt
        1K \
            qevent early_drop block 10
        tc filter add block 10 matchall action mirred egress
        mirror dev eth1


CLASSLESS QDISCS 不可分类 QDISCS
---------------------------------------

choke
~~~~~~~~~~~~~~~~~~

CHOKe (CHOose and Keep for responsive flows, CHOose and
Kill for unresponsive flows) is a classless qdisc designed
to both identify and penalize flows that monopolize the
queue. CHOKe is a variation of RED, and the configuration
is similar to RED.

codel
~~~~~~~~~~~~~~~~~~

CoDel (pronounced "coddle") is an adaptive "no-knobs"
active queue management algorithm (AQM) scheme that was
developed to address the shortcomings of RED and its
variants.

[p|b]fifo
~~~~~~~~~~~~~~~~~~

Simplest usable qdisc, pure First In, First Out behaviour.
Limited in packets or in bytes.

fq
~~~~~~~~~~~~~~~~~~

Fair Queue Scheduler realises TCP pacing and scales to
millions of concurrent flows per qdisc.

fq_codel
~~~~~~~~~~~~~~~~~~

Fair Queuing Controlled Delay is queuing discipline that
combines Fair Queuing with the CoDel AQM scheme. FQ_Codel
uses a stochastic model to classify incoming packets into
different flows and is used to provide a fair share of the
bandwidth to all the flows using the queue. Each such flow
is managed by the CoDel queuing discipline. Reordering
within a flow is avoided since Codel internally uses a
FIFO queue.

fq_pie
~~~~~~~~~~~~~~~~~~

FQ-PIE (Flow Queuing with Proportional Integral controller
Enhanced) is a queuing discipline that combines Flow
Queuing with the PIE AQM scheme. FQ-PIE uses a Jenkins
hash function to classify incoming packets into different
flows and is used to provide a fair share of the bandwidth
to all the flows using the qdisc. Each such flow is
managed by the PIE algorithm.

gred
~~~~~~~~~~~~~~~~~~

Generalized Random Early Detection combines multiple RED
queues in order to achieve multiple drop priorities. This
is required to realize Assured Forwarding (RFC 2597).

hhf
~~~~~~~~~~~~~~~~~~

Heavy-Hitter Filter differentiates between small flows and
the opposite, heavy-hitters. The goal is to catch the
heavy-hitters and move them to a separate queue with less
priority so that bulk traffic does not affect the latency
of critical traffic.

ingress
~~~~~~~~~~~~~~~~~~

This is a special qdisc as it applies to incoming traffic
on an interface, allowing for it to be filtered and
policed.

mqprio
~~~~~~~~~~~~~~~~~~

The Multiqueue Priority Qdisc is a simple queuing
discipline that allows mapping traffic flows to hardware
queue ranges using priorities and a configurable priority
to traffic class mapping. A traffic class in this context
is a set of contiguous qdisc classes which map 1:1 to a
set of hardware exposed queues.

multiq
~~~~~~~~~~~~~~~~~~

Multiqueue is a qdisc optimized for devices with multiple
Tx queues. It has been added for hardware that wishes to
avoid head-of-line blocking.  It will cycle though the
bands and verify that the hardware queue associated with
the band is not stopped prior to dequeuing a packet.

**netem**
~~~~~~~~~~~~~~~~~~

Network Emulator is an enhancement of the Linux traffic
control facilities that allow to add delay, packet loss,
duplication and more other characteristics to packets
outgoing from a selected network interface.

pfifo_fast
~~~~~~~~~~~~~~~~~~

Standard qdisc for 'Advanced Router' enabled kernels.
Consists of a three-band queue which honors Type of
Service flags, as well as the priority that may be
assigned to a packet.

pie
~~~~~~~~~~~~~~~~~~

Proportional Integral controller-Enhanced (PIE) is a
control theoretic active queue management scheme. It is
based on the proportional integral controller but aims to
control delay.

red
~~~~~~~~~~~~~~~~~~

Random Early Detection simulates physical congestion by
randomly dropping packets when nearing configured
bandwidth allocation. Well suited to very large bandwidth
applications.

rr
~~~~~~~~~~~~~~~~~~

Round-Robin qdisc with support for multiqueue network
devices. Removed from Linux since kernel version 2.6.27.

sfb
~~~~~~~~~~~~~~~~~~

Stochastic Fair Blue is a classless qdisc to manage
congestion based on packet loss and link utilization
history while trying to prevent non-responsive flows (i.e.
flows that do not react to congestion marking or dropped
packets) from impacting performance of responsive flows.
Unlike RED, where the marking probability has to be
configured, BLUE tries to determine the ideal marking
probability automatically.

sfq
~~~~~~~~~~~~~~~~~~

Stochastic Fairness Queueing reorders queued traffic so
each 'session' gets to send a packet in turn.

tbf
~~~~~~~~~~~~~~~~~~

The Token Bucket Filter is suited for slowing traffic down
to a precisely configured rate. Scales well to large
bandwidths.


配置 CLASSLESS QDISCS 
-----------------------------------

In the absence of classful qdiscs, classless qdiscs can only be
attached at the root of a device. Full syntax:

.. code-block::

    tc qdisc add dev DEV root QDISC QDISC-PARAMETERS

To remove, issue

.. code-block::

    tc qdisc del dev DEV root

The pfifo_fast qdisc is the automatic default in the absence of a configured qdisc.

CLASSFUL QDISCS 可分类 QDISCS
----------------------------------
可分类的 qdiscs 有:

ATM
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Map flows to virtual circuits of an underlying asynchronous transfer mode device.

CBQ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Class Based Queueing implements a rich linksharing hierarchy of classes.  
It contains shaping elements as well as prioritizing capabilities. 

Shaping is performed using link idle time calculations based on average packet size and underlying link bandwidth. 

The latter may be ill-defined for some interfaces.

DRR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Deficit Round Robin Scheduler is a more flexible replacement for Stochastic Fairness Queuing. 

Unlike SFQ,there are no built-in queues -- you need to add classes and then set up filters to classify packets accordingly.
This can be useful e.g. for using RED qdiscs with different settings for particular traffic. 

There is no default class -- if a packet cannot be classified, it is dropped.

DSMARK
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Classify packets based on TOS field, change TOS field of  packets based on classification.

ETS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ETS qdisc is a queuing discipline that merges functionality of PRIO and DRR qdiscs in one scheduler. 

ETS makes it easy to configure a set of strict and bandwidth-sharing bands to implement the transmission selection described in 802.1Qaz.

HFSC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Hierarchical Fair Service Curve guarantees precise bandwidth and delay allocation for leaf classes and
allocates excess bandwidth fairly. 

Unlike HTB, it makes use of packet dropping to achieve low delays which interactive sessions benefit from.

HTB
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Hierarchy Token Bucket implements a rich linksharing hierarchy of classes with an emphasis on conforming to existing practices. 

HTB facilitates guaranteeing bandwidth to classes, while also allowing specification of upper limits to inter-class sharing. 

It contains shaping elements, based on TBF and can prioritize classes.

PRIO
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The PRIO qdisc is a non-shaping container for a configurable number of classes which are dequeued in        order. 

This allows for easy prioritization of traffic, where lower classes are only able to send if higher ones        have no packets available. 

To facilitate configuration, Type Of Service bits are honored by default.

QFQ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Quick Fair Queueing is an O(1) scheduler that provides near-optimal guarantees, and is the first to achieve that goal with a constant cost also with respect to the number of groups and the packet length. 

The QFQ algorithm has no loops, and uses very simple instructions and data structures that lend themselves very well to a hardware implementation.


TC COMMANDS 
------------------------

以下命令可用于 qdiscs、类和过滤器:

add
~~~~~~~~~~~~

Add a qdisc, class or filter to a node. For all entities,
a parent must be passed, either by passing its ID or by
attaching directly to the root of a device.  When creating
a qdisc or a filter, it can be named with the handle
parameter. A class is named with the classid parameter.

delete
~~~~~~~~~~~~

A qdisc can be deleted by specifying its handle, which may
also be 'root'. All subclasses and their leaf qdiscs are
automatically deleted, as well as any filters attached to
them.

change
~~~~~~~~~~~~

Some entities can be modified 'in place'. Shares the
syntax of 'add', with the exception that the handle cannot
be changed and neither can the parent. In other words,
change cannot move a node.

replace
~~~~~~~~~~~~

Performs a nearly atomic remove/add on an existing node
id. If the node does not exist yet it is created.

get
~~~~~~~~~~~~

Displays a single filter given the interface DEV, qdisc-
id, priority, protocol and filter-id.

show
~~~~~~~~~~~~

Displays all filters attached to the given interface. A
valid parent ID must be passed.

link
~~~~~~~~~~~~

Only available for qdiscs and performs a replace where the
node must exist already.


TC 常用命令
-------------------------

* 延迟 100 ms:    :code:`tc qdisc add dev eth0 root netem delay 100ms`

* 延迟 100ms ± 10ms (90 ~ 110 ms ):    :code:`tc qdisc add dev eth0 root netem delay 100ms 10ms`

* 随机丢包 1%:    :code:`tc qdisc add dev eth0 root netem loss 1%`

* 模拟包重复:    :code:`tc qdisc add dev eth0 root netem duplicate 1%`

* 模拟数据包损坏:    :code:`tc qdisc add dev eth0 root netem corrupt 0.2%`

* 模拟数据包乱序：    :code:`tc qdisc change dev eth0 root netem delay 10ms reorder 25% 50%`

* 查看已经配置的网络条件：   :code:`tc qdisc show dev eth0`

* 删除网卡上面的相关配置:    :code:`tc qdisc del dev enp0s3 root`

* 对指定 ip 做限制:

.. code-block:: bash

    tc qdisc del dev enp0s3 root

    tc qdisc add dev enp0s3  root handle 1: prio

    tc filter add dev enp0s3 parent 1:0 protocol ip prio 1 u32 match ip dst 172.27.25.3 flowid 2:1

    tc qdisc add dev enp0s3  parent 1:1 handle 2: netem delay 1500ms  loss 1%


netimpair
==========================
tc 实在太强大，也太复杂了，netimpair 是对 tc 命令进行封装的一个 python 脚本

Features
------------------------

netimpair.py can do the following things:

* Simulate packet loss, duplication, jitter, reordering, and rate limiting
* Selective impairment based on ip/port
* Inbound or outbound impairment
* Automatically cleans up any impairment on exit or Ctrl-C

netimpair.py supports both Python 2 and 3.

Jitter
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
    
    # Add 200ms jitter
    sudo ./netimpair.py -n eth0 netem --jitter 200
    

Delay
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Add 200ms delay
    sudo ./netimpair.py -n eth0 netem --delay 200


Loss
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Add 5% loss
    sudo ./netimpair.py -n eth0 netem --loss_ratio 5


Rate Control
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Limit rate to 1mbit
    sudo ./netimpair.py -n eth0 rate --limit 1000


Impair inbound traffic
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Append --inbound flag before the impairment keyword to apply inbound impairment
    # For example, this applies 5% loss on inbound eth0
    sudo ./netimpair.py -n eth0 --inbound netem --loss_ratio 5


Selectively impair certain traffic
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Add 5% loss on packets with source IP of 10.194.247.50 and destination port 9001
    # NOTE: Specifying include flag overrides the default include, which impairs everything
    sudo ./netimpair.py -n eth0 --include src=10.194.247.50,dport=9001 netem --loss_ratio 5
    # Exclude packets with destination IP 10.194.247.50 and source port 10000
    sudo ./netimpair.py -n eth0 --exclude dst=10.194.247.50,sport=10000 netem --loss_ratio 5
    # Exclude SSH 
    sudo ./netimpair.py -n eth0 --exclude dport=22 netem --loss_ratio 5
    # Exclude a certain source IP on all ports
    sudo ./netimpair.py -n eth0 --exclude src=10.194.247.50 netem --loss_ratio 5


Additional parameters can be found with the help option
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    # Basic help
    ./netimpair.py -h
    # Help for the netem subcommand
    ./netimpair.py netem -h
    # Help for the rate subcommand
    ./netimpair.py rate -h
    



参考资料
==========================
* https://netbeez.net/blog/how-to-use-the-linux-traffic-control/
* https://man7.org/linux/man-pages/man8/tc.8.html
* https://www.cs.unm.edu/~crandall/netsfall13/TCtutorial.pdf