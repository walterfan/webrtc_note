:orphan:

################################
GStreamer WebRTC
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** GStreamer WebRTC
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
======================================


Example
======================================

* install gstreamer and related plugin

.. code-block::

     sudo apt-get install -y gstreamer1.0-tools gstreamer1.0-nice gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good libgstreamer1.0-dev git libglib2.0-dev libgstreamer-plugins-bad1.0-dev libsoup2.4-dev libjson-glib-dev

* download example from https://github.com/imdark/gstreamer-webrtc-demo

.. code-block::

    git clone git@github.com:imdark/gstreamer-webrtc-demo.git 

    cd sendrecv/gst
    make


* go to js folder and start a simple http server

.. code-block::

    #!/usr/bin/python
    import BaseHTTPServer, SimpleHTTPServer
    import ssl

    httpd = BaseHTTPServer.HTTPServer(('0.0.0.0', 8443), SimpleHTTPServer.SimpleHTTPRequestHandler)
    httpd.socket = ssl.wrap_socket(httpd.socket, certfile='./certs_and_key.pem', server_side=True)
    httpd.serve_forever()



Reference
===========================
* https://github.com/pion/example-webrtc-applications    