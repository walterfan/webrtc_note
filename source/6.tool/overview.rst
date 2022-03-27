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

.. |date| date::

.. contents::
   :local:


binutils
====================

The GNU Binutils are a collection of binary tools. The main ones are:

* ld - the GNU linker.
* as - the GNU assembler.

But they also include:

* addr2line - Converts addresses into filenames and line numbers.
* ar - A utility for creating, modifying and extracting from archives.
* c++filt - Filter to demangle encoded C++ symbols.
* dlltool - Creates files for building and using DLLs.
* gold - A new, faster, ELF only linker, still in beta test.
* gprof - Displays profiling information.
* nlmconv - Converts object code into an NLM.
* nm - Lists symbols from object files.
* objcopy - Copies and translates object files.
* objdump - Displays information from object files.
* ranlib - Generates an index to the contents of an archive.
* readelf - Displays information from any ELF format object file.
* size - Lists the section sizes of an object or archive file.
* strings - Lists printable strings from files.
* strip - Discards symbols.
* windmc - A Windows compatible message compiler.
* windres - A compiler for Windows resource files.


example
-----------------------

.. code-block

   ar -t libwebrtc.a

   nm -C libwebrtc.a | less


Linux Tools
====================

seq 生成数字序列
wc -l 计算行数
sed
awk
cut
head
tail
sort
jq
split
tee
tr
uniq
* vim: 输入 `:%! xxd` 用来编辑二进制文件 


例如:

.. code-block:: python

   def localip(eth="en0"):
      cmd = "ifconfig %s | grep inet | awk '$1==\"inet\" {print $2}'" % eth
      local(cmd)



gprof
---------------------

cc -g -c myprog.c utils.c -pg
cc -o myprog myprog.o utils.o -pg



refer to https://sourceware.org/binutils/docs/gprof/index.html


Python Tools
=====================

psutil
---------------------
.. code-block:: python

   import psutil

   #refer to https://psutil.readthedocs.io/en/latest/#processes

   def localres(times=10, type="cpu", app="safari"):
      for i in range(int(times)):
         if type == 'cpu':
               print(psutil.cpu_percent(interval=1, percpu=True))
               continue
         
         print(psutil.net_if_stats())
         
         for proc in psutil.process_iter(['pid', 'name', 'username']):
               if app in proc.info["name"].lower():
                  print(proc.info)