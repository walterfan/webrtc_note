##############################
libopus
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** libopus
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============


Installation
================

.. code-block::

    wget https://downloads.xiph.org/releases/opus/opus-1.4.tar.gz
    tar xvfz opus-1.4.tar.gz
    cd opus-1.4
    ./configure
    make
    make install

Usage
=====================


initialize encoder
---------------------

.. code-block:: cpp

    int init_encoder(OpusEncoder*& pEncoder, int sampleRate, int numberOfChannels, int bitrate) {

        int err;
        pEncoder = opus_encoder_create(sampleRate, numberOfChannels, OPUS_APPLICATION_VOIP, &err);
        if (err < 0) { return err; }

        opus_encoder_ctl(encoder, OPUS_SET_COMPLEXITY(4));
        opus_encoder_ctl(encoder, OPUS_SET_BITRATE(bitrate));
        opus_encoder_ctl(encoder, OPUS_SET_MAX_BANDWIDTH(OPUS_BANDWIDTH_WIDEBAND));
        opus_encoder_ctl(encoder, OPUS_SET_INBAND_FEC(1));
        opus_encoder_ctl(encoder, OPUS_SET_PACKET_LOSS_PERC(100));
        opus_encoder_ctl(encoder, OPUS_SET_DTX(1));

        return err;
    }

encode
----------------

.. code-block::

    int encode_audio(OpusEncoder* encoder, float* pcm, int frameSize, std::vector<uint8_t>& result) {

        unsigned char output[MAX_PACKET_SIZE];
        int size;

        size = opus_encode_float(encoder, pcm, frameSize, output, MAX_PACKET_SIZE);
        if (size < 0) {
            return size;
        }

        std::vector<uint8_t> encoded_data(output, output + size);
        result.swap(encoded_data);

        return size;
    }

initialize decoder
-------------------------

.. code-block:: cpp

    int initialize_decoder(OpusDecoder*& decoder; int peerId, int sampleRate, int numberOfChannels) {

        int err;
        decoder = opus_decoder_create(sampleRate, numberOfChannels, &err);
        return err;
    }


decode
----------------

.. code-block:: cpp

    int decode_audio(OpusDecoder* decoder, unsigned char* data, int length, int peerId, int numberOfChannels, int maxFrameSize, td::vector<uint8_t>& result) {

        float output[numberOfChannels * maxFrameSize];
        int size;

        size = opus_decode_float(decoder, data, length, output, maxFrameSize, 0);
        if (size < 0) {
            return size;
        }

        std::vector<uint8_t> encoded_data(output, output + size);
        result.swap(encoded_data);

        return size;
    }