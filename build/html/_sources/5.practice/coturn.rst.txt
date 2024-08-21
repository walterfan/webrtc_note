######################
coturn
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** coturn
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Installation
========================

* 参考 https://github.com/coturn/coturn/blob/master/INSTALL

.. code-block:: cpp

   git clone https://github.com/coturn/coturn.git
   cd coturn

* 编辑 install_deps.sh

.. code-block:: bash

   yum install -y openssl-devel
   yum install -y  sqlite
   yum install -y  sqlite-devel
   yum install -y  libevent
   yum install -y  libevent-devel
   #yum install postgresql-devel
   #yum install postgresql-server
   #yum install mysql-devel
   #yum install mysql-server
   #yum install hiredis
   #yum install hiredis-devel

* 安装依赖

.. code-block::

   $ source install_deps.sh


* 配置

.. code-block::

   $ ./configure
   install is /bin/install
   pkill is /bin/pkill
   sqlite3 is /bin/sqlite3
   Use TMP dir /var/tmp
   ….
   install -d sqlite
   rm -rf sqlite/turndb
   sqlite3 sqlite/turndb < turndb/schema.sql


* 安装

.. code-block::

   $ make install
   install -d /usr/local
   install -d /usr/local/bin


配置
----------------------

* 设置帐号和域名

.. code-block:: bash

   $ turnadmin -a -u walter -p pass1234 -r fanyamin.com


* 也可以通过配置文件进行配置


.. code-block:: bash

   $ cp /usr/local/etc/turnserver.conf.default /usr/local/etc/turnserver.conf
   $ vi /usr/local/etc/turnserver.conf
   listening-port=3478 #监听端口
   listening-device=eth0 #监听的网卡

   external-ip=121.4.184.225 #公网ip
   user=walter:pass1234 #用户名:密码
   realm=fanyamin.com #一般与turnadmin创建用户时指定的realm一致


Refer to https://www.cnblogs.com/yjmyzz/p/how-to-install-coturn-on-ubuntu.html


运行
---------------------

.. code-block:: bash

   # turnserver -o -a -f -v -r fanyamin.com