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