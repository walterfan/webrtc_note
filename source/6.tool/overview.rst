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