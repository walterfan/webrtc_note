##########
GStreamer
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** GStreamer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================

.. |date| date::

.. contents::
   :local:

Overview
==============
GStreamer is a the multi-platform, modular, open-source, media streaming framework.


Multiplatform
----------------------
GStreamer works on all major operating systems such as Linux, Android, Windows, Max OS X, iOS, as well as most BSDs, commercial Unixes, Solaris, and Symbian. It has been ported to a wide range of operating systems, processors and compilers. It runs on all major hardware architectures including x86, ARM, MIPS, SPARC and PowerPC, on 32-bit as well as 64-bit, and little endian or big endian.

GStreamer can bridge to other multimedia frameworks in order to reuse existing components (e.g. codecs) and use platform input/output mechanisms:

* Linux/Unix: OpenMAX-IL (via gst-omx)
* Windows: DirectShow
* Mac OS X: QuickTime

Comprehensive Core Library
--------------------------------------------

* Graph-based structure allows arbitrary pipeline construction
* Based on GLib 2.0 object model for object-oriented design and inheritance
* Compact core library of less than 500KB, about 65 K lines of code
* Multi-threaded pipelines are trivial and transparent to construct
* Clean, simple and stable API for both plugin and application developers
* Extremely lightweight data passing means very high performance/low latency
* Complete debugging system for both core and plugin/app developers
* Clocking to ensure global inter-stream synchronization (a/v sync)
* Quality of service (qos) to ensure best possible quality under high CPU load


Intelligent Plugin Architecture
--------------------------------------------

* Dynamically loaded plugins provide elements and media types, demand-loaded via a registry cache, similar to ld.so.cache
* Element interface handles all known types of sources, filters and sinks
* Capabilities system allows verification of element compatibility using MIME types and media-specific properties
* Autoplugging uses capabilities system to complete complex paths automatically
* Pipelines can be visualised by dumping them to a .dot file and creating a PNG image from that
* Resource friendly plugins don't waste memory


Broad Coverage of Multimedia Technologies
--------------------------------------------

GStreamers capabilities can be extended through new plugins. The features listed below are just a rough overview what is available using the GStreamers own plugins, not counting any 3rd party offerings.

* container formats: asf, avi, 3gp/mp4/mov, flv, mpeg-ps/ts, mkv/webm, mxf, ogg
* streaming: http, mms, rtsp
* codecs: FFmpeg, various codec libraries, 3rd party codec packs
* metadata: native container formats with a common mapping between them
* video: various colorspaces, support for progressive and interlaced video
* audio: integer and float audio in various bit depths and multichannel configurations


Extensive Development Tools
--------------------------------------------
* gst-launch command-line tool for quick prototyping and testing, similar to ecasound
* A lot of documentation, including partially completed manual and plugin writer's guide
* Large selection of test programs and example code in each module
* Access to GStreamer API with various programming languages



Installation
===============

MacOS
---------------
Download and install gstreamer from https://gstreamer.freedesktop.org/documentation/installing/on-mac-osx.html?gi-language=c

There are the following files installed:

* /Library/Frameworks/GStreamer.framework/: Framework's root path
* /Library/Frameworks/GStreamer.framework/Versions: path with all the versions of the framework
* /Library/Frameworks/GStreamer.framework/Versions/Current: link to the current version of the framework
* /Library/Frameworks/GStreamer.framework/Headers: path with the development headers
* /Library/Frameworks/GStreamer.framework/Commands: link to the commands provided by the framework, such as gst-inspect-1.0 or gst-launch-1.0

.. code-block::

   #include_path=/Library/Frameworks/GStreamer.framework/Headers
   export PATH=$PATH:/Library/Frameworks/GStreamer.framework/Versions/1.0/bin
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/Library/Frameworks/GStreamer.framework/Versions/1.0/lib


Get started
===============

* view plugin videotestsrc

.. code-block::

   gst-inspect-1.0 videotestsrc


* check video file codec

.. code-block::

   gst-discoverer-1.0 https://media.w3.org/2010/05/sintel/trailer_hd.mp4


* playback

.. code-block::

   gst-launch-1.0 playbin uri=https://media.w3.org/2010/05/sintel/trailer_hd.mp4


Documentation
==============

git clone https://gitlab.freedesktop.org/gstreamer/gst-docs.git


Reference
==============
https://gitlab.freedesktop.org/gstreamer/gst-docs.git
