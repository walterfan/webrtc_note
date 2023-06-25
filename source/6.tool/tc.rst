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



.. contents::
   :local:


简介
=========================
Linux 的 netem 模块和 tc 命令常用来控制网络流量，模拟网络中常见的各种问题, 例如丢包，延迟，抖动等。

在网络控制时有两个方向

* inbound 进来的流量 --> uplink 入口
* outbound 出去的流量 --> downlink 出口

tc 可以通过本地的发送队列，很容易地控制出去的流量，而对于进来的流量，需要结合虚拟设备 ifb(Intermediate Functional Block device) 来做流量控制。
可以认为 ifb 是虚拟的网卡设备

执行 `modprobe ifb` 会创建出来两块虚拟的网卡 ifb0 和 ifb1, 可以用 `ip link list` 来查看


IFB is an alternative to tc filters for handling ingress traffic, by redirecting it to a virtual interface and treat is as egress traffic there.
You need one ifb interface per physical interface, to redirect ingress traffic from eth0 to ifb0, eth1 to ifb1 and so on.

When inserting the ifb module, tell it the number of virtual interfaces you need. The default is 2:

`modprobe ifb numifbs=1`

Now, enable all ifb interfaces:

`ip link set dev ifb0 up # repeat for ifb1, ifb2, ...`

And redirect ingress traffic from the physical interfaces to corresponding ifb interface.
For eth0 -> ifb0:

.. code-block::

    tc qdisc add dev eth0 handle ffff: ingress
    tc filter add dev eth0 parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0


TC 中的基本概念
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

* qdiscs : 简单来说，它可以理解为一个队列，以及入队出队的调度器，默认的调度器是 FIFO, 包括可分类和不可分类的 qdisc
* classes: 类存在于 classful qdisc 中，它可以包含多个子类或单个子 qdisc, 可用于极其复杂的场景
* filters： 过滤器 filter 是Linux流量控制系统中最复杂的组件，它提供了一种方便的机制，可以将流量控制的几个关键元素粘合在一起

还有常用的 

* classifier 分类器

分类器是可用作过滤器的一部分以识别数据包特征或数据包元数据的工具。
可以使用 tc 操作的过滤器对象可以使用几种不同的分类机制，其中最常见的是 u32 分类器。 u32 分类器允许用户根据数据包的属性来选择数据包。

* handle

每个 class 和 classful qdisc都需要流量控制结构内的唯一标识符。这个唯一标识符被称为 handle，它有两个组成成员，一个主要编号和一个次要编号。
这些号码可以由用户按照以下规则任意分配。

- major

这个参数对内核完全没有意义。用户可以使用任意编号方案，但是流量控制结构中具有相同父对象的所有对象必须共享一个主句柄编号。
对于直接附加到 root qdisc 的对象，常规编号方案从 1 开始。

- minor

如果 minor 为0，则此参数将对象明确标识为qdisc。任何其他值将对象标识为 class。所有共享 parent 的 clas 都必须具有唯一的次要编号。

特殊 handle - ffff:0 为 ingress qdisc 保留。

handle 在 tc filter 语句的 classid 和 flowid 短语中用作目标。这些 handle 是对象的外部标识符，可供用户级应用程序使用。内核维护每个对象的内部标识符。


QDISCS
---------------------

qdisc 是 "queueing discipline"（排队规则）的缩写，它是理解流量控制的基础。 
每当内核需要向接口发送数据包时，它就会被放入为该接口配置的 qdisc 队列中。 
紧接着，内核尝试从 qdisc 中获取尽可能多的数据包，以便将它们提供给网络适配器驱动程序。

一个简单的 QDISC 是 "pfifo"，它根本不进行任何处理，是一个纯粹的先进先出队列。 
但是，当网络接口暂时无法处理流量时，它会存储流量。

qdisc 分为有类的 classful qdiscs 和无类的 classless qdiscs 

每一个 interface 可以包含出口 egress(outbound traffic) 和入口 ingress(inbound traffic)

我们又称用于出口的 egress qdisc 为 root qdisc, 它可以包含任何具有 class 的 qdiscs.
在 interface 上传送的流量都要通过 egress qdisc 或称 root qdisc

用于入口的流量控制的为 ingress qdisc, 它有一定的限制，不允许创建子类，仅仅作为可以附加 filter 的对象存在。
一个 ingress qdisc 只能支持一个 policer 以限制其接收的流量

简而言之， 我们可以使用 egress qdisc 做更多的控制，因为它包含真正全功能的 qdisc


classful qdiscs
~~~~~~~~~~~~~~~~~~~~~
classful qdiscs 可以包含 class，并提供一个 handle 来附加 filter。

classful qdiscs 当然也可以不包含 class，尽管这样做没有任何好处，只是空转并消耗系统资源。


classless qdiscs
~~~~~~~~~~~~~~~~~~~~~
classless qdiscs 不能包含任何 class, 也不能附着任何 filter， 因为 classless qdiscs 不包含任何类型的子类，所以称之为无类的 qdisc


CLASSES
---------------------

classful qdisc 可以包含类，这些类可包含更多的 qdiscs - 然后流量可以在任何内部 qdisc 中排队，这些内部 qdisc 在类中。 
当内核试图从这样一个有类的 qdisc 队列中取出一个数据包时，它可以来自任何类。 

例如，一个 qdisc 可以通过尝试在其他类之前从某些类中出列来对某些类型的流量进行优先级排序。

任意的 class 也可以附加任意数量的 filter ，这允许选择子类或使用 filter 重新分类或丢弃进入特定类的流量。

叶类 leaf class 是 qdisc 中的终端类。 它包含一个 qdisc（默认 FIFO）并且永远不会包含子类。 任何包含子类的类都是内部类（或根类），而不是叶类。

FILTERS 过滤器
---------------------

过滤器 filter 是Linux流量控制系统中最复杂的组件。 过滤器提供了一种方便的机制，可以将流量控制的几个关键元素粘合在一起。 

过滤器最简单、最明显的作用是对数据包进行分类。 Linux 过滤器允许用户使用几个不同的过滤器或单个过滤器将数据包分类到一个输出队列中。

过滤器可以附加到有类 qdisc 或类，但是入队的数据包总是首先进入根 qdisc。 在遍历了附加到根 qdisc 的过滤器之后，数据包可以被定向到任何子类（可以有自己的过滤器），数据包可以在这些子类中进行进一步的分类。

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


TC 用法
==================================


命令
----------------------------------
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


TC 命令实例
---------------------

Usage
~~~~~~~~~~~~~~~~~~~~~

.. code-block::

    Usage: tc [ OPTIONS ] OBJECT { COMMAND | help }
    where  OBJECT := { qdisc | class | filter }
       OPTIONS := { -s[tatistics] | -d[etails] | -r[aw] }



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

Example 1
~~~~~~~~~~~~~~~~~~~~~

.. code-block::

    # tc qdisc add    \ (1)
    >    dev eth0     \ (2)
    >    root         \ (3)
    >    handle 1:0   \ (4)
    >    htb            (5)

    - (1) Add a queuing discipline. The verb could also be del.
    - (2) Specify the device onto which we are attaching the new queuing discipline.
    - (3) This means "egress" to tc. The word root must be used, however. Another qdisc with limited functionality, the ingress qdisc can be attached to the same device.
    - (4) The handle is a user-specified number of the form major:minor. The minor number for any queueing discipline handle must always be zero (0). An acceptable shorthand for a qdisc handle is the syntax "1:", where the minor number is assumed to be zero (0) if not specified.
    - (5) This is the queuing discipline to attach, HTB in this example. Queuing discipline specific parameters will follow this. In the example here, we add no qdisc-specific parameters.


Example 3
~~~~~~~~~~~~~~~~~~~~~

.. code-block::

    # tc class add    \ (1)
    >    dev eth0     \ (2)
    >    parent 1:1   \ (3)
    >    classid 1:6  \ (4)
    >    htb          \ (5)
    >    rate 256kbit \ (6)
    >    ceil 512kbit   (7)
   
    - (1) Add a class. The verb could also be del.
    - (2) Specify the device onto which we are attaching the new class.
    - (3) Specify the parent handle to which we are attaching the new class.
    - (4) This is a unique handle (major:minor) identifying this class. The minor number must be any non-zero (0) number.
    - (5) Both of the classful qdiscs require that any children classes be classes of the same type as the parent. Thus an HTB qdisc will contain HTB classes.
    - (6)(7) This is a class specific parameter


Example 4
~~~~~~~~~~~~~~~~~~~~~

.. code-block::

    # tc filter add               \ (1)
    >    dev eth0                 \ (2)
    >    parent 1:0               \ (3)
    >    protocol ip              \ (4)
    >    prio 5                   \ (5)
    >    u32                      \ (6)
    >    match ip port 22 0xffff  \ (7)
    >    match ip tos 0x10 0xff   \ (8)
    >    flowid 1:6               \ (9)
    >    police                   \ (10)
    >    rate 32000bps            \ (11)
    >    burst 10240              \ (12)
    >    mpu 0                    \ (13)
    >    action drop/continue       (14)
   
    - (1) Add a filter. The verb could also be del.
    - (2) Specify the device onto which we are attaching the new filter.
    - (3) Specify the parent handle to which we are attaching the new filter.
    - (4) This parameter is required. It's use should be obvious, although I don't know more.
    - (5) The prio parameter allows a given filter to be preferred above another. The pref is a synonym.
    - (6) This is a classifier, and is a required phrase in every tc filter command.
    - (7)(8) These are parameters to the classifier. In this case, packets with a type of service flag (indicating interactive usage) and matching port 22 will be selected by this statement.
    - (9) The flowid specifies the handle of the target class (or qdisc) to which a matching filter should send its selected packets.
    - (10) This is the policer, and is an optional phrase in every tc filter command.
    - (11) The policer will perform one action above this rate, and another action below (see action parameter).
    - (12) The burst is an exact analog to burst in HTB (burst is a buckets concept).
    - (13) The minimum policed unit. To count all traffic, use an mpu of zero (0).
    - (14) The action indicates what should be done if the rate based on the attributes of the policer. The first word specifies the action to take if the policer has been exceeded. The second word specifies action to take otherwise.


tc-tbf
========================
tbf 即 Token Bucket Filter 令牌桶过滤器，参见 `tc-tbf <https://man7.org/linux/man-pages/man8/tc-tbf.8.html>`_

令牌桶过滤器是一种分类队列规则，可用于使用 tc(8) 命令进行流量控制。

TBF 是一个纯粹的 shaper 整形者，从不安排流量。

它是非工作守恒 non-work-conserving 的，并且可能会自我节流，以确保不超过配置的速率，即使这时有数据包可用。

它能够以理想的最小突发性塑造高达 1mbit/s 的正常流量，以配置的速率准确发送数据。

更高的速率是可能的，但代价是失去最小的突发性。 在这种情况下，数据平均以配置的速率出队，但在毫秒时间尺度上可能发送得更快。 
由于网络适配器中存在更多队列，这通常不是问题。

用法:

.. code-block::

    tc qdisc ... tbf rate rate burst bytes/cell ( latency ms | limit
    bytes ) [ mpu bytes [ peakrate rate mtu bytes/cell ] ]

    burst is also known as buffer and maxburst. mtu is also known as
    minburst.

实例
-----------------------

附加一个持续最大速率为 0.5 mbit/s, 峰值速率为 1.0 mbit/s, 5 KB 缓冲区的 TBF, 计算了预存储桶队列大小限制, 因此 TBF 导致最多 70 毫秒的延迟，具有完美的峰值速率行为， 命令如下：

.. code-block:: bash

    tc qdisc add dev eth0 handle 10: root tbf rate 0.5mbit \
    burst 5kb latency 70ms peakrate 1mbit       \
    minburst 1540

要附加一个内部 qdisc，例如 sfq，命令如下：

.. code-block:: bash

    tc qdisc add dev eth0 parent 10:1 handle 100: sfq

没有内部 qdisc TBF 队列充当 bfifo。 如果更改了内部 qdisc，则限制/延迟不再有效。

tc-netem
========================
NetEm 即 Network Emulator 网络模拟器， 参见 `tc-netem <https://man7.org/linux/man-pages/man8/tc-netem.8.html>`_

NetEm 是 Linux 流量控制工具的增强版，它允许为从选定网络接口传出的数据包添加延迟、数据包丢失、重复和更多其他特征。 
NetEm 是使用 Linux 内核中现有的服务质量 (QoS) 和差异化服务 (diffserv) 工具构建的。

用法:

.. code-block::

       tc qdisc ... dev DEVICE ] add netem OPTIONS

       OPTIONS := [ LIMIT ] [ DELAY ] [ LOSS ] [ CORRUPT ] [ DUPLICATION
       ] [ REORDERING ] [ RATE ] [ SLOT ]

       LIMIT := limit packets

       DELAY := delay TIME [ JITTER [ CORRELATION ]]]
              [ distribution { uniform | normal | pareto |  paretonormal
       } ]

       LOSS := loss { random PERCENT [ CORRELATION ]  |
                      state p13 [ p31 [ p32 [ p23 [ p14]]]] |
                      gemodel p [ r [ 1-h [ 1-k ]]] }  [ ecn ]

       CORRUPT := corrupt PERCENT [ CORRELATION ]]

       DUPLICATION := duplicate PERCENT [ CORRELATION ]]

       REORDERING := reorder PERCENT [ CORRELATION ] [ gap DISTANCE ]

       RATE := rate RATE [ PACKETOVERHEAD [ CELLSIZE [ CELLOVERHEAD ]]]]

       SLOT := slot { MIN_DELAY [ MAX_DELAY ] |
                      distribution { uniform | normal | pareto |
       paretonormal | FILE } DELAY JITTER }
                    [ packets PACKETS ] [ bytes BYTES ]

例如,以 5kbit 的速率延迟设备 eth0 上的所有传出数据包，每个数据包开销为 20 字节，单元大小为 100 字节，每个单元开销为 5 字节：

.. code-block:: bash

    tc qdisc add dev eth0 root netem rate 5kbit 20 100 5





netimpair
==========================
tc 实在太强大，也太复杂了，netimpair 是对 tc 命令进行封装的一个 python 脚本
https://github.com/urbenlegend/netimpair

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