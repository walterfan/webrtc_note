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

We can use webrtcbin to setup connection with other peer

.. code-block::

    sudo apt-get install -y libgstreamer1.0-dev \
    gstreamer1.0-libav libglib2.0-dev \
    gstreamer1.0-tools gstreamer1.0-nice gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-plugins-good \
    libgstreamer-plugins-bad1.0-dev libsoup2.4-dev libjson-glib-dev


    gst-inspect-1.0 webrtcbin


详细描述参见 https://gstreamer.freedesktop.org/documentation/webrtc/?gi-language=c


.. code-block::

    +----GInitiallyUnowned
        +----GstObject
                +----GstElement
                    +----GstBin
                            +----GstWebRTCBin

它的一进一出由以下两个 Pad 控制
* GstWebRTCBinSinkPad
* GstWebRTCBinSrcPad


Signals
======================================
on-data-channel
--------------------------------------
.. code=block:: c

    on_data_channel_callback (GstElement * object,
                          GstWebRTCDataChannel * channel,
                          gpointer udata)

on-ice-candidate
--------------------------------------
.. code=block:: c

    on_ice_candidate_callback (GstElement * object,
                           guint mline_index,
                           gchararray candidate,
                           gpointer udata)

on-negotiation-needed
--------------------------------------
.. code=block:: c


    on_negotiation_needed_callback (GstElement * object,
                                gpointer udata)                       

    
on-new-transceiver 
--------------------------------------
.. code=block:: c

    on_new_transceiver_callback (GstElement * object,
                             GstWebRTCRTPTransceiver * candidate,
                             gpointer udata)


prepare-data-channel
--------------------------------------
.. code=block:: c

    prepare_data_channel_callback (GstElement * object,
                               GstWebRTCDataChannel * channel,
                               gboolean is_local,
                               gpointer udata)
    
request-aux-sender 
--------------------------------------
.. code=block:: c

    GstElement *
    request_aux_sender_callback (GstElement * object,
                                GstWebRTCDTLSTransport * dtls-transport,
                                gpointer udata)

Action Signals
======================================
add-ice-candidate
...



Properties
======================================
bundle-policy 
...


Example
======================================
详细代码参见  https://gitlab.freedesktop.org/gstreamer/gst-examples/-/tree/master/webrtc


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