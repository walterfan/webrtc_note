######################
WebRTC Entities
######################



.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref


.. contents::
    :local:


概论
============

RTCPeerConnection
------------------------------------
The RTCPeerConnection interface represents a WebRTC connection between the local computer and a remote peer. It provides methods to connect to a remote peer, maintain and monitor the connection, and close the connection once it's no longer needed.



RTCDataChannel
------------------------------------
The RTCDataChannel interface represents a network channel which can be used for bidirectional peer-to-peer transfers of arbitrary data. Every data channel is associated with an RTCPeerConnection, and each peer connection can have up to a theoretical maximum of 65,534 data channels (the actual limit may vary from browser to browser).

To create a data channel and ask a remote peer to join you, call the RTCPeerConnection's createDataChannel() method. The peer being invited to exchange data receives a datachannel event (which has type RTCDataChannelEvent) to let it know the data channel has been added to the connection.



RTCRtpTransceiver
------------------------------------
The WebRTC interface RTCRtpTransceiver describes a permanent pairing of an RTCRtpSender and an RTCRtpReceiver, along with some shared state.

Each SDP media section describes one bidirectional SRTP ("Secure Real Time Protocol") stream (excepting the media section for RTCDataChannel, if present). This pairing of send and receive SRTP streams is significant for some applications, so RTCRtpTransceiver is used to represent this pairing, along with other important state from the media section. Each non-disabled SRTP media section is always represented by exactly one transceiver.

A transceiver is uniquely identified using its mid property, which is the same as the media ID (mid) of its corresponding m-line. An RTCRtpTransceiver is associated with an m-line if its mid is non-null; otherwise it's considered disassociated.


Properties
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* currentDirection Read only

A read-only string which indicates the transceiver's current directionality, or null if the transceiver is stopped or has never participated in an exchange of offers and answers. To change the transceiver's directionality, set the value of the direction property.

* direction

A string which is used to set the transceiver's desired direction.

* mid Read only

The media ID of the m-line associated with this transceiver. This association is established, when possible, whenever either a local or remote description is applied. This field is null if neither a local or remote description has been applied, or if its associated m-line is rejected by either a remote offer or any answer.

* receiver Read only

The RTCRtpReceiver object that handles receiving and decoding incoming media.

* sender Read only

The RTCRtpSender object responsible for encoding and sending data to the remote peer.

* stopped

Indicates whether or not sending and receiving using the paired RTCRtpSender and RTCRtpReceiver has been permanently disabled, either due to SDP offer/answer, or due to a call to stop().


RTCRtpSender
-----------------------------------


RTCRtpEncodingParameters
-----------------------------------

Properties
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* active

If true, the described encoding is currently actively being used. That is, for RTP senders, the encoding is currently being used to send data, while for receivers, the encoding is being used to decode received data. The default value is true.

* codecPayloadType

When describing a codec for an RTCRtpSender, codecPayloadType is a single 8-bit byte (or octet) specifying the codec to use for sending the stream; the value matches one from the owning RTCRtpParameters object's codecs parameter. This value can only be set when creating the transceiver; after that, this value is read only.

* dtx

Only used for an RTCRtpSender whose kind is audio, this property indicates whether or not to use discontinuous transmission (a feature by which a phone is turned off or the microphone muted automatically in the absence of voice activity). The value is taken from the enumerated string type RTCDtxStatus.

* maxBitrate

An unsigned long integer indicating the maximum number of bits per second to allow for this encoding. Other parameters may further constrain the bit rate, such as the value of maxFramerate or transport or physical network limitations.

* maxFramerate

A double-precision floating-point value specifying the maximum number of frames per second to allow for this encoding.

* ptime

An unsigned long integer value indicating the preferred duration of a media packet in milliseconds. This is typically only relevant for audio encodings. The user agent will try to match this as well as it can, but there is no guarantee.

* rid

A DOMString which, if set, specifies an RTP stream ID (RID) to be sent using the RID header extension. This parameter cannot be modified using setParameters(). Its value can only be set when the transceiver is first created.

* scaleResolutionDownBy

Only used for senders whose track's kind is video, this is a double-precision floating-point value specifying a factor by which to scale down the video during encoding. The default value, 1.0, means that the sent video's size will be the same as the original. A value of 2.0 scales the video frames down by a factor of 2 in each dimension, resulting in a video 1/4 the size of the original. The value must not be less than 1.0 (you can't use this to scale the video up).


RTCRtpReceiver
------------------------------------

The RTCRtpReceiver interface of the WebRTC API manages the reception and decoding of data for a MediaStreamTrack on an RTCPeerConnection.


RTCRtpContributingSource
-------------------------------------

The RTCRtpContributingSource dictionary of the WebRTC API is used by getContributingSources() to provide information about a given contributing source (CSRC), including the most recent time a packet that the source contributed was played out.

The information provided is based on the last ten seconds of media received.


* audioLevel Optional

A double-precision floating-point value between 0 and 1 specifying the audio level contained in the last RTP packet played from this source.

* rtpTimestamp Optional

The RTP timestamp of the media played out at the time indicated by timestamp. This value is a source-generated time value which can be used to help with sequencing and synchronization.

* source Optional

A 32-bit unsigned integer value specifying the CSRC identifier of the contributing source.

* timestamp Optional

A DOMHighResTimeStamp indicating the most recent time at which a frame originating from this source was delivered to the receiver's MediaStreamTrack