########################
HTTP Live Streaming
########################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** HTTP Live Streaming
**Authors**  Walter Fan
**Status**   WIP as draft
**Updated**  |date|
============ ==========================



.. contents::
   :local:

简介
=======================================

HTTP Live Streaming (also known as HLS) is an HTTP-based adaptive bitrate streaming communications protocol developed by Apple Inc. and released in 2009. Support for the protocol is widespread in media players, web browsers, mobile devices, and streaming media servers. As of 2019, an annual video industry survey has consistently found it to be the most popular streaming format.[2]

HLS resembles MPEG-DASH in that it works by breaking the overall stream into a sequence of small HTTP-based file downloads, each downloading one short chunk of an overall potentially unbounded transport stream. A list of available streams, encoded at different bit rates, is sent to the client using an extended M3U playlist.

Based on standard HTTP transactions, HTTP Live Streaming can traverse any firewall or proxy server that lets through standard HTTP traffic, unlike UDP-based protocols such as RTP. This also allows content to be offered from conventional HTTP servers and delivered over widely available HTTP-based content delivery networks. The standard also includes a standard encryption mechanism[5] and secure-key distribution using HTTPS, which together provide a simple DRM system. Later versions of the protocol also provide for trick-mode fast-forward and rewind and for integration of subtitle


Performance
==========================
HLS may have 10s above delay, need low latency HLS


Reference
=======================================
* https://en.wikipedia.org/wiki/HTTP_Live_Streaming
* https://www.dacast.com/blog/hls-streaming-protocol/
* https://developer.apple.com/documentation/http_live_streaming/preparing_audio_for_http_live_streaming
* HTTP Live Streaming: https://datatracker.ietf.org/doc/html/rfc8216