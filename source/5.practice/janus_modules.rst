######################
Janus Modules
######################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Janus Plugins
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


Overview
========================

* Core 核心模块	Core implementation of the server

  - Protocols	Implementations of the WebRTC protocols

* Plugins 插件模块 Janus plugins available out of the box

  - Plugin API	Plugin API (aka, how to write your own plugin)
  - Lua plugin API	Lua plugin (aka, how to write your own plugin in Lua)
  - Duktape plugin API	Duktape plugin (aka, how to write your own plugin in JavaScript)

* Transports 传输模块 Transport plugins available out of the box

  - Transport API	Transport API (aka, how to write your own transport plugin)

* Event Handlers 事件处理模块 Event handler plugins available out of the box

  - Event Handler API	Event Handler API (aka, how to write your own event handler plugin)

* Loggers 日志模块	Logger plugins available out of the box

  - Logger API	Logger API (aka, how to write your own logger plugin)

* Tools and utilities 实用工具模块	Tools and utilities

  - Recordings post-processing utility	Recordings post-processing utility


入口函数
==========================
* main in janus.c



