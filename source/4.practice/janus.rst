###################
Janus Gateway
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Janus gateway
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
========================

Janus是由 Meetecho 设计和开发的一种开源通用WebRTC服务器。 该版本的服务器专为Linux系统量身定制，尽管它也可以为MacOS机器编译和安装。
不支持Windows，但是如果有此要求，Janus可以在Windows 10上的“ Linux的Windows子系统”中运行：
不要信任提供Janus的.exe版本的存储库，它们不是官方的，将不受支持。


Janus 由 Janus CORE、Janus Plugin 以及信令接口三部分组成。

* 信令接口，Janus 支持的信令协议比较多，如 HTTP、WebSocket、RabbitMQ 等。这些信令协议使得 Janus 具有非常好的接入性。因为很多公司喜欢各种不同的协议，如有的喜欢 websocket，有的喜欢http，proto等。因此 Janus 在信令接入方面具有很大的优势。
* Janus Plugin，Janus 的业务管理是按照 Plugin 的方式管理的，因此你可以在Janus中根据自己的需要实现自己的业务插件。实际上，对于一般性的需求 Janus 已经相关的插件。如：
   - VideoRoom，用于多人音视频互动，像音视频会议，在线教育都可以通过该插件来实现。
   - VideoCall，用于 1:1 的音视频通信。
   - SIP，用于与传统电话设备对接。
   - Streaming，用于广播，也就是我们通常所说的一人共享，多人观看的直播模式。
   - TextRoom，它是一个聊天室，通过它可以进行文本聊天。
   - RecordPlay，用于录制和回放。


Janus Core 是Janus的核心，其作用是处理流的转发，各种协议的接入。以浏览器为例，要想让浏览器接入到 WebRTC 流媒体服务器上，那流媒体服务器必须要支持 STUN、DTLS、SRTP、ICE 等协议。


Installation and startup
==================================
# CentOS7 64bit

.. code-block::

    yum install libmicrohttpd-devel jansson-devel \
    openssl-devel libsrtp-devel sofia-sip-devel glib2-devel libnice-devel \
    opus-devel libogg-devel libcurl-devel pkgconfig gengetopt \
    libconfig-devel libtool autoconf automake

    wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz
        tar xfv v2.2.0.tar.gz
        cd libsrtp-2.2.0
        ./configure --prefix=/usr --enable-openssl --libdir=/usr/lib64
        make shared_library && sudo make install

.. code-block::

    git clone https://libwebsockets.org/repo/libwebsockets
    cd libwebsockets
    # If you want the stable version of libwebsockets, uncomment the next line
    # git checkout v3.2-stable
    mkdir build
    cd build
    # See https://github.com/meetecho/janus-gateway/issues/732 re: LWS_MAX_SMP
    cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" ..
    make && sudo make install

.. code-block::

    wget http://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.59.tar.gz
    tar xvf libmicrohttpd-0.9.59.tar.gz
    cd libmicrohttpd-0.9.59
    ./configure --libdir=/usr/lib64
    make 
    sudo make install 
    sudo ldconfig

.. code-block::

    sh autogen.sh
    #to generate the configure file. After that, configure and compile as usual to start the whole compilation process:
    ./configure --prefix=/opt/janus --enable-websockets --enable-rest --enable-docs
    make
    make install
    #Since Janus requires configuration files for both the core and its modules in order to work, you'll probably also want to install the default configuration files to use, which you can do this way:
    #make configs



.. code-block::

    cd /opt/janus
    ./bin/janus &

    yum install nginx
    nginx
    cp -rf /opt/janus/share/janus/demos /usr/share/nginx/html/
    #open http://$host/demos


    # netstat -anp|grep janus
    tcp        0      0 0.0.0.0:8188            0.0.0.0:*               LISTEN      27849/./bin/janus
    tcp6       0      0 :::8088                 :::*                    LISTEN      27849/./bin/janus
    udp6       0      0 :::5002                 :::*                                27849/./bin/janus
    udp6       0      0 :::5004                 :::*                                27849/./bin/janus
    unix  3      [ ]         STREAM     CONNECTED     6894357  27849/./bin/janus
    unix  3      [ ]         STREAM     CONNECTED     6894356  27849/./bin/janus


configuration
===========================

* janus.jcfg

.. code-block::

    diff --git a/janus.jcfg.sample b/janus.jcfg
    index f2c71e8..15d4c1d 100644
    --- a/janus.jcfg.sample
    +++ b/janus.jcfg
    @@ -13,7 +13,7 @@ general: {
            # The next settings configure logging
            #log_to_stdout = false                                  # Whether the Janus output should be written
                                                                                            # to stdout or not (default=true)
    -       #log_to_file = "/path/to/janus.log"             # Whether to use a log file or not
    +       log_to_file = "/opt/janus/logs/janus.log"               # Whether to use a log file or not
            debug_level = 4                                                 # Debug/logging level, valid values are 0-7
            #debug_timestamps = true                                # Whether to show a timestamp for each log line
            #debug_colors = false                                   # Whether colors should be disabled in the log
    @@ -47,7 +47,7 @@ general: {
                                                                            # without this, the Admin API MUST
                                                                            # be enabled, as tokens are added and removed
                                                                            # through messages sent there.
    -       admin_secret = "janusoverlord"  # String that all Janus requests must contain
    +       admin_secret = "P@ss1234"        # String that all Janus requests must contain
                                                                            # to be accepted/authorized by the admin/monitor.
                                                                            # only needed if you enabled the admin API
                                                                            # in any of the available transports.
    @@ -300,7 +300,7 @@ nat: {
            # Multiple public IP addresses can be specified as a comma separated list
            # if the Janus is deployed in a DMZ between two 1-1 NAT for internal and
            # external users.
    -       #nat_1_1_mapping = "1.2.3.4"
    +       nat_1_1_mapping = "10.224.122.36"
            #keep_private_host = true

            # You can configure a TURN server in two different ways: specifying a
    @@ -351,7 +351,7 @@ nat: {
            #     ice_enforce_list = "eth0,192.168."
            #     ice_enforce_list = "eth0,192.168.0.1"
            # By default, no interface is enforced, meaning Janus will try to use them all.
    -       #ice_enforce_list = "eth0"
    +       ice_enforce_list = "ens3,10.224.122.36"


* janus.transport.http.jcfg

.. code-block::

    diff --git a/janus.transport.http.jcfg.sample b/janus.transport.http.jcfg
    index 37923c6..a5539cd 100644
    --- a/janus.transport.http.jcfg.sample
    +++ b/janus.transport.http.jcfg
    @@ -15,8 +15,8 @@ general: {
            port = 8088                                             # Web server HTTP port
            #interface = "eth0"                             # Whether we should bind this server to a specific interface only
            #ip = "192.168.0.1"                             # Whether we should bind this server to a specific IP address (v4 or v6) only
    -       https = false                                   # Whether to enable HTTPS (default=false)
    -       #secure_port = 8089                             # Web server HTTPS port, if enabled
    +       https = true                                    # Whether to enable HTTPS (default=false)
    +       secure_port = 8089                              # Web server HTTPS port, if enabled
            #secure_interface = "eth0"              # Whether we should bind this server to a specific interface only
            #secure_ip = "192.168.0.1"              # Whether we should bind this server to a specific IP address (v4 or v6) only
            #acl = "127.,192.168.0."                # Only allow requests coming from this comma separated list of addresses
    @@ -37,12 +37,12 @@ general: {
    # endpoint is disabled by default, enable it by setting admin_http=true.
    admin: {
            admin_base_path = "/admin"                      # Base path to bind to in the admin/monitor web server (plain HTTP only)
    -       admin_http = false                                      # Whether to enable the plain HTTP interface
    +       admin_http = true                                       # Whether to enable the plain HTTP interface
            admin_port = 7088                                       # Admin/monitor web server HTTP port
            #admin_interface = "eth0"                       # Whether we should bind this server to a specific interface only
            #admin_ip = "192.168.0.1"                       # Whether we should bind this server to a specific IP address (v4 or v6) only
    -       admin_https = false                                     # Whether to enable HTTPS (default=false)
    -       #admin_secure_port = 7889                       # Admin/monitor web server HTTPS port, if enabled
    +       admin_https = true                                      # Whether to enable HTTPS (default=false)
    +       admin_secure_port = 7889                        # Admin/monitor web server HTTPS port, if enabled
            #admin_secure_interface = "eth0"        # Whether we should bind this server to a specific interface only
            #admin_secure_ip = "192.168.0.1         # Whether we should bind this server to a specific IP address (v4 or v6) only
            #admin_acl = "127.,192.168.0."          # Only allow requests coming from this comma separated list of addresses
    @@ -67,8 +67,8 @@ cors: {
    # You can also disable insecure protocols and ciphers by configuring the
    # 'ciphers' property accordingly (no limitation by default).
    certificates: {
    -       #cert_pem = "/path/to/cert.pem"
    -       #cert_key = "/path/to/key.pem"
    +       cert_pem = "/opt/lampp/etc/ssl.crt/server.crt"
    +       cert_key = "/opt/lampp/etc/ssl.key/server.key"
            #cert_pwd = "secretpassphrase"
            #ciphers = "PFS:-VERS-TLS1.0:-VERS-TLS1.1:-3DES-CBC:-ARCFOUR-128"
    }


* janus.websockets.jcfg

.. code-block::

    diff --git a/janus.transport.websockets.jcfg.sample b/janus.transport.websockets.jcfg
    index 073b8d1..49c6154 100644
    --- a/janus.transport.websockets.jcfg.sample
    +++ b/janus.transport.websockets.jcfg
    @@ -12,8 +12,8 @@ general: {
            #ws_interface = "eth0"                  # Whether we should bind this server to a specific interface only
            #ws_ip = "192.168.0.1"                  # Whether we should bind this server to a specific IP address only
            #ws_unix = "/run/ws.sock"               # Use WebSocket server over UNIX socket instead of TCP
    -       wss = false                                             # Whether to enable secure WebSockets
    -       #wss_port = 8989                                # WebSockets server secure port, if enabled
    +       wss = true                                              # Whether to enable secure WebSockets
    +       wss_port = 8989                         # WebSockets server secure port, if enabled
            #wss_interface = "eth0"                 # Whether we should bind this server to a specific interface only
            #wss_ip = "192.168.0.1"                 # Whether we should bind this server to a specific IP address only
            #wss_unix = "/run/wss.sock"             # Use WebSocket server over UNIX socket instead of TCP
    @@ -61,8 +61,8 @@ cors: {
    # 'ciphers' property accordingly (no limitation by default).
    # Examples of recommended cipher strings at https://cheatsheetseries.owasp.org/cheatsheets/TLS_Cipher_String_Cheat_Sheet.html
    certificates: {
    -       #cert_pem = "/path/to/cert.pem"
    -       #cert_key = "/path/to/key.pem"
    +       cert_pem = "/opt/lampp/etc/ssl.crt/server.crt"
    +       cert_key = "/opt/lampp/etc/ssl.key/server.key"
            #cert_pwd = "secretpassphrase"
            #ciphers = "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"
    }

usage and testing
===========================

EchoTest
---------------------------
This Echo Test demo just blindly sends you back whatever you send to it.
You're basically attached to yourself, and so your audio and video you send to Janus are echoed back to you.

The same is done for RTCP packets as well, with the information properly updated.

client: 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

open http://10.224.85.233/demos/echotest.html by firefox

Janus Object init 

1) POST /janus
* response: sessionId is the data.id

.. code-block::

    {
    "janus": "success",
    "transaction": "iqHi029hsJF3",
    "data": {
        "id": 1730150663723177
    }
    }


JSEP

.. code-block::

    [
    {
        "janus": "event",
        "session_id": 76377000668057,
        "transaction": "AlvApIFrqWBE",
        "sender": 4176087136988668,
        "plugindata": {
            "plugin": "janus.plugin.echotest",
            "data": {
                "echotest": "event",
                "result": "ok"
            }
        },
        "jsep": {
            "type": "answer",
            "sdp": "v=0\r\n
            o=mozilla...THIS_IS_SDPARTA-63.0.3 1603271024498389 1 IN IP4 10.224.85.233\r\n
            s=-\r\n
            t=0 0\r\n
            a=group:BUNDLE 0 1\r\n
            a=msid-semantic: WMS janus\r\n
            m=audio 9 UDP/TLS/RTP/SAVPF 109\r\n
            c=IN IP4 10.224.85.233\r\n
            a=sendrecv\r\n
            a=mid:0\r\n
            a=rtcp-mux\r\n
            a=ice-ufrag:AUe7\r\n
            a=ice-pwd:XgM3SlRrtjdv+kDY5T1ITI\r\n
            a=ice-options:trickle\r\n
            a=fingerprint:sha-256 44:98:B3:C6:A8:88:ED:50:22:0F:2E:1A:58:65:A3:CB:46:65:2F:8A:AB:E1:BF:D5:32:85:3E:95:9E:CF:48:63\r\n
            a=setup:active\r\na=rtpmap:109 opus/48000/2\r\n
            a=fmtp:109 useinbandfec=1\r\n
            a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\n
            a=extmap:3 urn:ietf:params:rtp-hdrext:sdes:mid\r\n
            a=msid:janus janusa0\r\n
            a=ssrc:705498670 cname:janus\r\n
            a=ssrc:705498670 msid:janus janusa0\r\n
            a=ssrc:705498670 mslabel:janus\r\n
            a=ssrc:705498670 label:janusa0\r\n
            a=candidate:1 1 udp 2013266431 10.224.85.233 37266 typ host\r\n
            a=end-of-candidates\r\n
            m=video 9 UDP/TLS/RTP/SAVPF 120\r\n
            c=IN IP4 10.224.85.233\r\n
            a=sendrecv\r\n
            a=mid:1\r\n
            a=rtcp-mux\r\n
            a=ice-ufrag:AUe7\r\n
            a=ice-pwd:XgM3SlRrtjdv+kDY5T1ITI\r\n
            a=ice-options:trickle\r\n
            a=fingerprint:sha-256 44:98:B3:C6:A8:88:ED:50:22:0F:2E:1A:58:65:A3:CB:46:65:2F:8A:AB:E1:BF:D5:32:85:3E:95:9E:CF:48:63\r\n
            a=setup:active\r\n
            a=rtpmap:120 VP8/90000\r\n
            a=rtcp-fb:120 ccm fir\r\n
            a=rtcp-fb:120 nack\r\n
            a=rtcp-fb:120 nack pli\r\n
            a=rtcp-fb:120 goog-remb\r\n
            a=rtcp-fb:120 transport-cc\r\n
            a=extmap:3 urn:ietf:params:rtp-hdrext:sdes:mid\r\n
            a=fmtp:120 max-fs=12288;max-fr=60\r\n
            a=msid:janus janusv0\r\n
            a=ssrc:3463695356 cname:janus\r\n
            a=ssrc:3463695356 msid:janus janusv0\r\n
            a=ssrc:3463695356 mslabel:janus\r\n
            a=ssrc:3463695356 label:janusv0\r\n
            a=candidate:1 1 udp 2013266431 10.224.85.233 37266 typ host\r\n
            a=end-of-candidates\r\n
            m=application 0 UDP/DTLS/SCTP webrtc-datachannel\r\n
            c=IN IP4 10.224.85.233\r\n
            a=inactive\r\n"
        }
    }
    ]


* server: 

code structure
===========================

Janus 的 Plugin 机制是它扩展功能的核心机制

dependencies
===========================

To install it, you'll need to satisfy the following dependencies:

* Jansson
* libconfig
* libnice (at least v0.1.16 suggested, master recommended)
* OpenSSL (at least v1.0.1e)
* libsrtp (at least v2.x suggested)
* usrsctp (only needed if you are interested in Data Channels)
* libmicrohttpd (at least v0.9.59; only needed if you are interested in REST support for the Janus API)
* libwebsockets (only needed if you are interested in WebSockets support for the Janus API)
* cmake (only needed if you are interested in WebSockets and/or BoringSSL support, as they make use of it)
* rabbitmq-c (only needed if you are interested in RabbitMQ support for the Janus API or events)
* paho.mqtt.c (only needed if you are interested in MQTT support for the Janus API or events)
* nanomsg (only needed if you are interested in Nanomsg support for the Janus API)
* libcurl (only needed if you are interested in the TURN REST API support)

A couple of plugins depend on a few more libraries:

* Sofia-SIP (only needed for the SIP plugin)
* libopus (only needed for the AudioBridge plugin)
* libogg (needed for the VoiceMail plugin and/or post-processor, and optionally AudioBridge and Streaming plugins)
* libcurl (only needed if you are interested in RTSP support in the Streaming plugin or in the sample Event Handler plugin)
* Lua (only needed for the Lua plugin)

Additionally, you'll need the following libraries and tools:

* GLib
* zlib
* pkg-config
* gengetopt


Janus JS API
------------------

In general, when using the Janus features, you would normally do the following:

* include the Janus JavaScript library in your web page;
* initialize the Janus JavaScript library and (optionally) passing its dependencies;
* connect to the server and create a session;
* create one or more handles to attach to a plugin (e.g., echo test and/or streaming);
* interact with the plugin (sending/receiving messages, negotiating a PeerConnection);
* eventually, close all the handles and shutdown the related PeerConnections;
* destroy the session.


Example
------------------

* EchoTest




* Ping: http://10.224.85.233:8188/ping?


Reference
------------------
* Janus google group: https://groups.google.com/g/meetecho-janus

