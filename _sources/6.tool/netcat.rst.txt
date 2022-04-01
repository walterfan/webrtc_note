#################
netcat
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** netcat
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

简介
====================
netcat 


Samples
====================

chat
--------------------
.. code-block::

    nc -l 2008
    nc 127.0.0.1 2008


file transfer
--------------------
.. code-block::

    # Server
    nc -l 1567 < file.txt

    # Client
    nc -n 172.31.100.7 1567 > file.txt




侦听80端口并将收到的请求记录下来
----------------------------------------------------------
1) 在 192.268.3.4 上运行

nc -l 80 >> test.log

2) 在 192.268.3.5 上运行

.. code-block::

    curl --form file=@./005.wav --form "metadata={'userName':'walter', deployScope': 'All', description:'audio clips'}" http://192.268.3.4/api/v1/packages -v

3) 在192.268.3.4可以看到从192.268.3.5上发过的请求
   
.. code-block::

    cat test.log

接收和发送文件
----------------------------------------------------------
1) 在 192.268.3.4 上运行

netcat -l 8888 > received_file

2) 在 192.268.3.5 上运行
   
netcat 192.268.3.4 8888 < received_file

作为一个简单的web server
----------------------------------------------------------

.. code-block::

    { echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c <index.html)\r\n\r\n"; cat index.html; } | nc -l -p 8080

Reference
===============

* Offical site: http://sourceforge.net/projects/nc110/
* Wiki: https://en.wikipedia.org/wiki/Netcat#Test_if_UDP_port_is_open:_simple_UDP_server_and_client
