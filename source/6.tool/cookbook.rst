######################
WebRTC 常用工具
######################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC 常用工具
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


binutils
==================

* addr2line 把程序地址转换为文件名和行号。在命令行中给它一个地址和一个可执行文件名，它就会使用这个可执行文件的调试信息指出在给出的地址上是哪个文件以及行号。

* ar 建立、修改、提取归档文件。归档文件是包含多个文件内容的一个大文件，其结构保证了可以恢复原始文件内容。

* as 主要用来编译GNU C编译器gcc输出的汇编文件，产生的目标文件由连接器ld连接。

* c++filt 连接器使用它来过滤 C++ 和 Java 符号，防止重载函数冲突。

* gprof 显示程序调用段的各种数据。

* ld 是连接器，它把一些目标和归档文件结合在一起，重定位数据，并链接符号引用。通常，建立一个新编译程序的最后一步就是调用ld。

* nm 列出目标文件中的符号。

* objcopy把一种目标文件中的内容复制到另一种类型的目标文件中.

* objdump 显示一个或者更多目标文件的信息。显示一个或者更多目标文件的信息。使用选项来控制其显示的信息。它所显示的信息通常只有编写编译工具的人才感兴趣。

* ranlib 产生归档文件索引，并将其保存到这个归档文件中。在索引中列出了归档文件各成员所定义的可重分配目标文件。

* readelf 显示ebf格式可执行文件的信息。

* size 列出目标文件每一段的大小以及总体的大小。默认情况下，对于每个目标文件或者一个归档文件中的每个模块只产生一行输出。

* strings 打印某个文件的可打印字符串，这些字符串最少4个字符长，也可以使用选项-n设置字符串的最小长度。默认情况下，它只打印目标文件初始化和可加载段中的可打印字符；对于其它类型的文件它打印整个文件的可打印字符，这个程序对于了解非文本文件的内容很有帮助。

* strip 丢弃目标文件中的全部或者特定符号。

* libiberty 包含许多GNU程序都会用到的函数，这些程序有： getopt, obstack, strerror, strtol 和 strtoul.

* libbfd 二进制文件描述库.

* libopcodes 用来处理opcodes的库, 在生成一些应用程序的时候也会用到它, 比如objdump.Opcodes是文本格式可读的处理器操作指令.



如何阻塞端口
==========================================


packet filter 
-----------------------------------------
在 macos 系统中， pfctl 可以用来阻塞端口

1. 编辑配置文件，添加规则
   
.. code-block::

   $ sudo cp /etc/pf.conf /etc/pf_bak.conf

   $ vim /etc/pf_bak.conf

   block on en0 proto udp from any to any port 9000    # block UDP port 9000
   block on en0 proto tcp from any to any port 80      # block TCP port 80
   block on en0 proto tcp from any to any port 5004    # block TCP port 5004


2. 启用这些规则

.. code-block::

   $ sudo pfctl -ef /etc/pf_bak.conf
   
3. 检查启用的规则

.. code-block::
   
   $ sudo pfctl -sr


4. 删除这些规则 

.. code-block::

   $ sudo pfctl -d
   
5. 重新启用默认的规则

.. code-block::

   $ sudo pfctl -ef /etc/pf.conf


其他常用工具
=============================

Mosh(mobile shell)
------------------------------
Remote terminal application that allows roaming, supports intermittent connectivity, and provides intelligent local echo and line editing of user keystrokes.

Mosh is a replacement for interactive SSH terminals. It's more robust and responsive, especially over Wi-Fi, cellular, and long-distance links.

Mosh is free software, available for GNU/Linux, BSD, macOS, Solaris, Android, Chrome, and iOS.

refer to https://mosh.org/

common steps
~~~~~~~~~~~~~~~~~~~
在服务器安装 mosh

1.  `apt install mosh`
2.  ufw allow 60000:61000/udp

打开了服务器的端口限制，在客户端安装 mosh

3.  brew install mosh
4.  mosh walter@www.fanyamin.com


Better Touch Tool
-------------------------------
https://folivora.ai/

Midnight Commander
-------------------------------
https://midnight-commander.org/





参考资料
=============================
* Windows Defender Firewall with Advanced Security
* https://murusfirewall.com/Documentation/OS%20X%20PF%20Manual.pdf
* http://krypted.com/mac-security/a-cheat-sheet-for-using-pf-in-os-x-lion-and-up/
* https://www.oneperiodic.com/products/handsoff/
* https://webrtcforthecurious.com/docs/09-debugging/