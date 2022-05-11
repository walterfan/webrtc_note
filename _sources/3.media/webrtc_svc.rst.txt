################################
WebRTC SVC
################################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** WebRTC SVC
**Category** Learning note
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:


概述
===========================
temporal scalability is  present in H.264/AVC, as profiles defined in Annex A of [H.264]


Terminology
==========================

* SST: single-session transmission - refer to `RFC6190`_
* MST: multi-session transmission - refer to `RFC6190`_


示例
===========================


.. code-block:: javascript


    const signaling = new SignalingChannel(); // handles JSON.stringify/parse
    const constraints = {audio: true, video: true};
    const configuration = {'iceServers': [{'urls': 'stun:stun.example.org'}]};
    let pc;

    // call start() to initiate
    async function start() {
    pc = new RTCPeerConnection(configuration);

    // let the "negotiationneeded" event trigger offer generation
    pc.onnegotiationneeded = async () => {
        try {
        await pc.setLocalDescription();
        // send the offer to the other peer
        signaling.send({description: pc.localDescription});
        } catch (err) {
        console.error(err);
        }
    };

    try {
        // get a local stream, show it in a self-view and add it to be sent
        const stream = await navigator.mediaDevices.getUserMedia(constraints);
        selfView.srcObject = stream;
        pc.addTransceiver(stream.getAudioTracks()[0], {direction: 'sendonly'});
        pc.addTransceiver(stream.getVideoTracks()[0], {
        direction: 'sendonly',
        sendEncodings: [
            {rid: 'q', scaleResolutionDownBy: 4.0, scalabilityMode: 'L1T3'}
            {rid: 'h', scaleResolutionDownBy: 2.0, scalabilityMode: 'L1T3'},
            {rid: 'f', scalabilityMode: 'L1T3'},
        ]
        });
    } catch (err) {
        console.error(err);
    }
    }

    signaling.onmessage = async ({data: {description, candidate}}) => {
    try {
        if (description) {
        await pc.setRemoteDescription(description);
        // if we got an offer, we need to reply with an answer
        if (description.type == 'offer') {
            await pc.setLocalDescription();
            signaling.send({description: pc.localDescription});
        }
        } else if (candidate) {
        await pc.addIceCandidate(candidate);
        }
    } catch (err) {
        console.error(err);
    }
    };

参考
===========================
* https://www.w3.org/TR/webrtc-svc/
* `RFC6190`_: RTP Payload Format for Scalable Video Coding
