##############################
libopenh264
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** libopenh264
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
===================

OpenH264 is a codec library which supports H.264 encoding and decoding. It is suitable for use in real time applications such as WebRTC. See http://www.openh264.org/ for more details.


Installation
===================
先要安装下列工具

* gcc/clang
* NASM

windows 平台需要额外安装
* Visual Studio C++ 2019
* MinGW    https://osdn.net/projects/mingw/releases/

执行下列步骤从源码编译安装

.. code-block::

    git clone git@github.com:cisco/openh264.git
    cd openh264
    make clean
    make gtest-bootstrap

    # architecture: arm, arm64, x86 or x86_64
    make OS=linux ARCH=**ARCH**

* linux

.. code-block::

    make [OS=linux] [BUILDTYPE=Release/Debug]  [ARCH=x86_64/x86] [CC=gcc] [CXX=g++] [USE_ASM=Yes/No] [ENABLEPIC=Yes]

* mac

.. code-block::

    make [OS=darwin] [BUILDTYPE=Release/Debug]  [ARCH=x86_64/x86] [CC=gcc] [CXX=g++] [USE_ASM=Yes/No] [ENABLEPIC=Yes]


* windows

.. code-block::

    AutoBuildForWPAndWindows.bat <Win32|Win64-Debug|Release-C|ASM>


Usage
=====================

initialize encoder
----------------------

.. code-block:: cpp

    int initialize_encoder(ISVCEncoder*& encoder, int width, int height, int fps, int bitrate) {

        int err;
        ISVCEncoder* encoder;
        err = WelsCreateSVCEncoder(&encoder);
        if (err) { return err; }

        SEncParamBase param;
        memset(&param, 0, sizeof(SEncParamBase));
        param.iUsageType = CAMERA_VIDEO_REAL_TIME;
        param.iPicWidth = width;
        param.iPicHeight = height;
        param.iTargetBitrate = bitrate / 2;
        param.iRCMode = RC_BITRATE_MODE;
        param.fMaxFrameRate = fps;

        err = encoder->Initialize(&param);
        if (err) { return err; }

        int videoFormat = videoFormatI420;
        err = encoder->SetOption(ENCODER_OPTION_DATAFORMAT, &videoFormat);
        if (err) { return err; }

        SBitrateInfo bitrateInfo;
        bitrateInfo.iLayer = SPATIAL_LAYER_ALL;
        bitrateInfo.iBitrate = bitrate;
        err = encoder->SetOption(ENCODER_OPTION_MAX_BITRATE, &bitrateInfo);

        return err;
    }


encode video frame
---------------------------

.. code-block:: c++

    int encode_frame(ISVCEncoder* encoder, unsigned char* yuv, int width, int height, long timestamp, SFrameBSInfo& enc_info;) {

        if (!encoder) { return -1; }
        int err = 0;

        memset(&enc_info, 0, sizeof(SFrameBSInfo));

        SSourcePicture frame;
        memset(&frame, 0, sizeof(SSourcePicture));
        frame.iPicWidth = width;
        frame.iPicHeight = height;
        frame.iColorFormat = videoFormatI420;
        frame.iStride[0] = width;
        frame.iStride[1] = frame.iStride[2] = width >> 1;
        frame.pData[0] = yuv;
        frame.pData[1] = frame.pData[0] + width * height;
        frame.pData[2] = frame.pData[1] + (width * height >> 2);
        frame.uiTimeStamp = timestamp;

        err = encoder->EncodeFrame(&frame, &enc_info);

        return err;
    }


initialize decoder
---------------------------

.. code-block:: c++

    int initialize_decoder(ISVCDecoder*& decoder) {

        int err = WelsCreateDecoder(&decoder);
        if (err) { return err; }

        SDecodingParam param;
        memset(&param, 0, sizeof(SDecodingParam));
        param.uiTargetDqLayer = UCHAR_MAX;
        param.eEcActiveIdc = ERROR_CON_SLICE_COPY;
        param.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_DEFAULT;
        err = decoder->Initialize(&param);

        return err;
    }

decode video frame
-------------------------------

.. code-block:: c++

    int decode_frame(ISVCDecoder* decoder, unsigned char* data, int length, vector<uint8_t> frameData, SBufferInfo& frameInfo) {

        memset(yuv_out, 0, sizeof(yuv_out));

        memset(&info_out, 0, sizeof(SBufferInfo));

        int err = decoder->DecodeFrame2(data, length, yuv_out, &frameInfo);

        return err;
    }

Reference
=============
* http://www.nasm.us/
* https://github.com/cisco/openh264