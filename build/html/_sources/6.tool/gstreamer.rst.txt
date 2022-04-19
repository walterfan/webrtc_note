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

Tools
---------------
gst-launch
~~~~~~~~~~~~~~~

* test video source

.. code-block::

   gst-launch-1.0 videotestsrc ! videoconvert ! autovideosink


* playback mp4 file

.. code-block::

   gst-launch-1.0 playbin uri=file:///opt/webrtc_primer/material/obama_talk.mp4


gst-inspect
~~~~~~~~~~~~~~

* view plugin videotestsrc

.. code-block::

   gst-inspect-1.0 videotestsrc

gst-discoverer
~~~~~~~~~~~~~~~

* check video file codec

.. code-block::

   gst-discoverer-1.0 ../../../material/obama_talk.mp4



Concepts
=========================





PIPELINE building
=========================
PIPELINE
-------------------------
A pipeline consists elements and links.
Elements can be put into bins of different sorts.
Elements, links and bins can be specified in a pipeline description in any order.

Elements
--------------------------
ELEMENTTYPE [PROPERTY1 ...]

Creates an element of type ELEMENTTYPE and sets the PROPERTIES.

Properties
--------------------------
PROPERTY=VALUE ...

Sets the property to the specified value. You can use gst-inspect-1.0(1) to find out about properties and allowed values of different elements.
Enumeration properties can be set by name, nick or value.

Bins
--------------------------
[BINTYPE.] ( [PROPERTY1 ...] PIPELINE-DESCRIPTION )
Specifies that a bin of type BINTYPE is created and the given properties are set. Every element between the braces is put into the bin. Please note the dot that has to be used after the BINTYPE. You will almost never need this functionality, it is only really useful for applications using the gst_launch_parse() API with 'bin' as bintype. That way it is possible to build partial pipelines instead of a full-fledged top-level pipeline.

Links
--------------------------
[[SRCELEMENT].[PAD1,...]] ! [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] ! CAPS ! [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] : [[SINKELEMENT].[PAD1,...]] [[SRCELEMENT].[PAD1,...]] : CAPS : [[SINKELEMENT].[PAD1,...]]

Links the element with name SRCELEMENT to the element with name SINKELEMENT, using the caps specified in CAPS as a filter. Names can be set on elements with the name property. If the name is omitted, the element that was specified directly in front of or after the link is used. This works across bins. If a padname is given, the link is done with these pads. If no pad names are given all possibilities are tried and a matching pad is used. If multiple padnames are given, both sides must have the same number of pads specified and multiple links are done in the given order.
So the simplest link is a simple exclamation mark, that links the element to the left of it to the element right of it.
Linking using the : operator attempts to link all possible pads between the elements

Caps
--------------------------
MEDIATYPE [, PROPERTY[, PROPERTY ...]]] [; CAPS[; CAPS ...]]

Creates a capability with the given media type and optionally with given properties. The media type can be escaped using " or '. If you want to chain caps, you can add more caps in the same format afterwards.

Properties
--------------------------
NAME=[(TYPE)]VALUE
in lists and ranges: [(TYPE)]VALUE

Sets the requested property in capabilities. The name is an alphanumeric value and the type can have the following case-insensitive values:

- i or int for integer values or ranges
- f or float for float values or ranges
- b, bool or boolean for boolean values
- s, str or string for strings
- fraction for fractions (framerate, pixel-aspect-ratio)
- l or list for lists

If no type was given, the following order is tried: integer, float, boolean, string.
Integer values must be parsable by strtol(), floats by strtod(). FOURCC values may either be integers or strings. Boolean values are (case insensitive) yes, no, true or false and may like strings be escaped with " or '.
Ranges are in this format: [ VALUE, VALUE ]
Lists use this format: { VALUE [, VALUE ...] }


PIPELINE EXAMPLES
============================
The examples below assume that you have the correct plug-ins available. In general, "pulsesink" can be substituted with another audio output plug-in such as "alsasink" or "osxaudiosink" Likewise, "xvimagesink" can be substituted with "ximagesink", "glimagesink", or "osxvideosink". Keep in mind though that different sinks might accept different formats and even the same sink might accept different formats on different machines, so you might need to add converter elements like audioconvert and audioresample (for audio) or videoconvert (for video) in front of the sink to make things work.

Audio playback
--------------------------
Play the mp3 music file "music.mp3" using a libmpg123-based plug-in and output to an Pulseaudio device
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Play an Ogg Vorbis format file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=music.ogg ! oggdemux ! vorbisdec ! audioconvert ! audioresample ! pulsesink

Play an mp3 file or an http stream using GIO
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 giosrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! pulsesink

        gst-launch-1.0 giosrc location=http://domain.com/music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Use GIO to play an mp3 file located on an SMB server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 giosrc location=smb://computer/music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Format conversion
--------------------------

Convert an mp3 music file to an Ogg Vorbis file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! vorbisenc ! oggmux ! filesink location=music.ogg

Convert to the FLAC format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=music.mp3 ! mpegaudioparse ! mpg123audiodec ! audioconvert ! flacenc ! filesink location=test.flac


Plays a .WAV file that contains raw audio data (PCM).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! audioresample ! pulsesink

Convert a .WAV file containing raw audio data into an Ogg Vorbis or mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! vorbisenc ! oggmux ! filesink location=music.ogg

        gst-launch-1.0 filesrc location=music.wav ! wavparse ! audioconvert ! lamemp3enc ! filesink location=music.mp3

Rips all tracks from compact disc and convert them into a single mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 cdparanoiasrc mode=continuous ! audioconvert ! lamemp3enc ! mpegaudioparse ! id3v2mux ! filesink location=cd.mp3

Rips track 5 from the CD and converts it into a single mp3 file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 cdparanoiasrc track=5 ! audioconvert ! lamemp3enc ! mpegaudioparse ! id3v2mux ! filesink location=track5.mp3

Using gst-inspect-1.0(1), it is possible to discover settings like the above for cdparanoiasrc that will tell it to rip the entire cd or only tracks of it. Alternatively, you can use an URI and gst-launch-1.0 will find an element (such as cdparanoia) that supports that protocol for you, e.g.:
       gst-launch-1.0 cdda://5 ! lamemp3enc vbr=new vbr-quality=6 ! filesink location=track5.mp3

Records sound from your audio input and encodes it into an ogg file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 pulsesrc ! audioconvert ! vorbisenc ! oggmux ! filesink location=input.ogg

Video
----------------------
Display only the video portion of an MPEG-1 video file, outputting to an X display window
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=JB_FF9_TheGravityOfLove.mpg ! dvddemux ! mpegvideoparse ! mpeg2dec ! xvimagesink

Display the video portion of a .vob file (used on DVDs), outputting to an SDL window
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=/flflfj.vob ! dvddemux ! mpegvideoparse ! mpeg2dec ! sdlvideosink

Play both video and audio portions of an MPEG movie
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=movie.mpg ! dvddemux name=demuxer  demuxer. ! queue ! mpegvideoparse ! mpeg2dec ! sdlvideosink  demuxer. ! queue ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

Play an AVI movie with an external text subtitle stream
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=movie.mpg ! mpegdemux name=demuxer demuxer. ! queue ! mpegvideoparse ! mpeg2dec ! videoconvert ! sdlvideosink   demuxer. ! queue ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink

This example also shows how to refer to specific pads by name if an element (here: textoverlay) has multiple sink or source pads.

        gst-launch-1.0 textoverlay name=overlay ! videoconvert ! videoscale !  autovideosink   filesrc location=movie.avi ! decodebin ! videoconvert ! overlay.video_sink   filesrc location=movie.srt ! subparse ! overlay.text_sink

Play an AVI movie with an external text subtitle stream using playbin
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 playbin uri=file:///path/to/movie.avi suburi=file:///path/to/movie.srt

Network streaming
-------------------------

Stream video using RTP and network elements.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This command would be run on the transmitter

        gst-launch-1.0 v4l2src ! video/x-raw,width=128,height=96,format=UYVY ! videoconvert ! ffenc_h263 ! video/x-h263 ! rtph263ppay pt=96 ! udpsink host=192.168.1.1 port=5000

Use this command on the receiver

        gst-launch-1.0 udpsrc port=5000 ! application/x-rtp, clock-rate=90000,payload=96 ! rtph263pdepay queue-delay=0 ! ffdec_h263 ! xvimagesink

Diagnostic
-------------------------
Generate a null stream and ignore it (and print out details).
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 -v fakesrc num-buffers=16 ! fakesink

Generate a pure sine tone to test the audio output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 audiotestsrc ! audioconvert ! audioresample ! pulsesink

Generate a familiar test pattern to test the video output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 videotestsrc ! xvimagesink

        gst-launch-1.0 videotestsrc ! ximagesink

Automatic linking
------------------------------
You can use the decodebin element to automatically select the right elements to get a working pipeline.

Play any supported audio format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 filesrc location=musicfile ! decodebin ! audioconvert ! audioresample ! pulsesink

Play any supported video format with video and audio output.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Threads are used automatically. To make this even easier, you can use the playbin element:

        gst-launch-1.0 filesrc location=videofile ! decodebin name=decoder decoder. ! queue ! audioconvert ! audioresample ! pulsesink   decoder. !  videoconvert ! xvimagesink

        gst-launch-1.0 playbin uri=file:///home/joe/foo.avi

Filtered connections
--------------------------------

These examples show you how to use filtered caps.

Show a test image and use the YUY2 or YV12 video format for this.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        gst-launch-1.0 videotestsrc ! 'video/x-raw,format=YUY2;video/x-raw,format=YV12' ! xvimagesink

Record audio and write it to a .wav file.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Force usage of signed 16 to 32 bit samples and a sample rate between 32kHz and 64KHz.

        gst-launch-1.0 pulsesrc !  'audio/x-raw,rate=[32000,64000],format={S16LE,S24LE,S32LE}' ! wavenc ! filesink location=recording.wav


FAQ
===============

How to make a gstreamer plugin
-----------------------------------------
1) build develop environment

.. code-block::

   docker run --name gst_dev --rm -i -t -v `pwd`:/workspace restreamio/gstreamer:latest-dev-with-source /bin/bash

2) 定义存储数据的元素的结构
3) 定义这个元素的类
4) 定义这个元素的标准宏
5) 定义返回类型信息的标准函数
6) 注册这个元素


Reference
==============
* GStreamer document: https://gitlab.freedesktop.org/gstreamer/gst-docs.git
* GStreamer plugin guide: https://gstreamer.freedesktop.org/documentation/plugin-development/index.html?gi-language=c