##########
FFmpeg
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** FFmpeg 音视频处理工具
**Authors**  Walter Fan
**Status**   v1.0
**Updated**  |date|
============ ==========================



.. contents::
   :local:

概述
==============

FFmpeg 是一个跨平台的音视频录制、转换和流式传输的完整解决方案。
在 WebRTC 开发中，FFmpeg 是最常用的辅助工具之一，用于：

- 分析媒体文件的编码信息
- 生成测试音视频素材
- 转码和格式转换
- RTP/RTSP 推拉流测试
- 录制和回放 WebRTC 相关的媒体数据


组件
====

命令行工具
----------

-  `ffmpeg`_: 音视频编码和解码工具
-  `ffplay`_: 媒体播放器
-  `ffprobe`_: 媒体文件特性探查器

共享库
---------------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - 库
     - 说明
   * - libavcodec
     - 编解码库，支持几乎所有音视频编解码器
   * - libavformat
     - 容器格式（封装/解封装），支持 MP4、MKV、WebM、OGG 等
   * - libavfilter
     - 音视频滤镜框架
   * - libavdevice
     - 输入输出设备（摄像头、麦克风、屏幕采集等）
   * - libavutil
     - 通用工具库
   * - libswresample
     - 音频重采样和格式转换
   * - libswscale
     - 视频缩放和像素格式转换
   * - libpostproc
     - 视频后处理


处理流程
==============

FFmpeg 的内部处理流程如下：

.. code-block:: text

   输入文件 → demuxer → 编码数据包 → decoder → 原始帧
                                                  ↓
                                              filter(s)
                                                  ↓
   输出文件 ← muxer  ← 编码数据包 ← encoder ← 处理后的帧

1. ``libavformat`` 读取输入文件，解封装得到编码数据包
2. ``libavcodec`` 解码得到原始帧（raw video / PCM audio）
3. ``libavfilter`` 对原始帧进行滤镜处理（可选）
4. ``libavcodec`` 将处理后的帧重新编码
5. ``libavformat`` 将编码数据包写入输出文件

如果使用 ``-c copy``（stream copy），则跳过解码和编码步骤，直接复制数据包。


基本用法
==============

.. code-block:: bash

   ffmpeg [global_options] [input_options] -i input [output_options] output

查看支持的格式和编解码器：

.. code-block:: bash

   ffmpeg -formats
   ffmpeg -codecs
   ffmpeg -encoders
   ffmpeg -decoders


媒体信息分析
==============

在 WebRTC 开发中，经常需要分析媒体文件的编码参数。``ffprobe`` 是最方便的工具。

查看文件基本信息
--------------------------

.. code-block:: bash

   ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

查看关键帧分布
--------------------------

.. code-block:: bash

   ffprobe -v quiet -select_streams v:0 -show_entries frame=pict_type,pts_time \
     -of csv=p=0 input.mp4 | grep I

查看编解码器详细信息
--------------------------

.. code-block:: bash

   ffprobe -v quiet -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate,sample_rate,channels \
     -of json input.mp4


音频处理
==============

提取音频
--------------------------

.. code-block:: bash

   # 从视频中提取音频为 WAV（PCM 16bit, 单声道, 8kHz）
   ffmpeg -i input.mp4 -vn -acodec pcm_s16le -ar 8000 -ac 1 output.wav

   # 从视频中提取音频为 WAV（保留原始采样率和声道）
   ffmpeg -i input.mp4 -vn -acodec pcm_s16le output.wav

   # 提取为 Opus 格式
   ffmpeg -i input.mp4 -vn -acodec libopus -b:a 64k output.opus

格式转换
--------------------------

.. code-block:: bash

   # MP3 → WAV (8kHz, 16bit, 单声道，适合语音处理)
   ffmpeg -i input.mp3 -acodec pcm_s16le -ac 1 -ar 8000 output.wav

   # WAV → Opus (WebRTC 默认音频编码)
   ffmpeg -i input.wav -acodec libopus -b:a 48k output.opus

   # WAV → OGG Vorbis
   ffmpeg -i input.wav -acodec libvorbis -q:a 4 output.ogg

音频拼接
--------------------------

.. code-block:: bash

   # 创建文件列表
   cat > list.txt << EOF
   file 'part1.wav'
   file 'part2.wav'
   EOF

   # 拼接
   ffmpeg -f concat -safe 0 -i list.txt -c copy output.wav

生成测试音频
--------------------------

.. code-block:: bash

   # 生成 5 秒 440Hz 正弦波 (A4 音符)
   ffmpeg -f lavfi -i "sine=frequency=440:duration=5" -ar 48000 test_tone.wav

   # 生成白噪声
   ffmpeg -f lavfi -i "anoisesrc=d=5:c=white:r=48000" white_noise.wav

   # 生成静音
   ffmpeg -f lavfi -i "anullsrc=r=48000:cl=mono" -t 3 silence.wav


视频处理
==============

格式转换
--------------------------

.. code-block:: bash

   # MP4 → WebM (VP8 + Vorbis，浏览器友好)
   ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -c:a libvorbis output.webm

   # MP4 → WebM (VP9 + Opus，更高效)
   ffmpeg -i input.mp4 -c:v libvpx-vp9 -b:v 1M -c:a libopus output.webm

   # 使用 H.264 重编码（控制码率）
   ffmpeg -i input.mp4 -c:v libx264 -b:v 2M -c:a aac -b:a 128k output.mp4

分辨率和帧率调整
--------------------------

.. code-block:: bash

   # 缩放到 720p
   ffmpeg -i input.mp4 -vf "scale=1280:720" -c:a copy output_720p.mp4

   # 限制帧率为 15fps（模拟低帧率场景）
   ffmpeg -i input.mp4 -r 15 output_15fps.mp4

   # 同时调整分辨率和码率（模拟 WebRTC 弱网自适应后的效果）
   ffmpeg -i input.mp4 -vf "scale=640:360" -b:v 500k -r 15 output_low.mp4

查看关键帧和 GOP 结构
--------------------------

.. code-block:: bash

   # 列出所有 I 帧的时间戳
   ffprobe -v quiet -select_streams v:0 -show_entries frame=pict_type,pts_time \
     -of csv=p=0 input.mp4 | grep "I"

   # 强制每 2 秒一个关键帧（WebRTC 场景常用）
   ffmpeg -i input.mp4 -c:v libx264 -g 60 -keyint_min 60 output.mp4

生成测试视频
--------------------------

.. code-block:: bash

   # 彩色条纹测试视频（10秒, 720p, 30fps）
   ffmpeg -f lavfi -i "testsrc2=size=1280x720:rate=30:duration=10" \
     -c:v libx264 -pix_fmt yuv420p test_video.mp4

   # 带时间戳的测试视频（方便测量延迟）
   ffmpeg -f lavfi -i "testsrc2=size=1280x720:rate=30:duration=10" \
     -vf "drawtext=text='%{pts\:hms}':fontsize=48:fontcolor=white:x=10:y=10" \
     -c:v libx264 -pix_fmt yuv420p test_with_timestamp.mp4

   # 测试视频 + 测试音频
   ffmpeg -f lavfi -i "testsrc2=size=1280x720:rate=30:duration=10" \
     -f lavfi -i "sine=frequency=440:duration=10" \
     -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest test_av.mp4


RTP 推拉流
==============

FFmpeg 可以用来模拟 RTP 发送和接收，是测试 WebRTC 传输层的利器。

RTP 发送视频
--------------------------

.. code-block:: bash

   # 发送 H.264 RTP 流
   ffmpeg -re -i input.mp4 -an -c:v libx264 -tune zerolatency -b:v 500k \
     -f rtp rtp://127.0.0.1:5004

   # 发送 VP8 RTP 流
   ffmpeg -re -i input.mp4 -an -c:v libvpx -b:v 500k \
     -f rtp rtp://127.0.0.1:5004

``-re`` 表示按照原始帧率发送（实时模式），``-tune zerolatency`` 降低编码延迟。

RTP 发送音频
--------------------------

.. code-block:: bash

   # 发送 Opus RTP 流
   ffmpeg -re -i input.wav -c:a libopus -b:a 48k \
     -f rtp rtp://127.0.0.1:5006

   # 发送 PCMU (G.711 μ-law) RTP 流
   ffmpeg -re -i input.wav -c:a pcm_mulaw -ar 8000 -ac 1 \
     -f rtp rtp://127.0.0.1:5006

RTP 接收和录制
--------------------------

需要先创建 SDP 文件描述流的参数：

.. code-block::

   # video.sdp
   v=0
   m=video 5004 RTP/AVP 96
   c=IN IP4 127.0.0.1
   a=rtpmap:96 H264/90000

.. code-block:: bash

   # 接收并播放
   ffplay -protocol_whitelist file,rtp,udp -i video.sdp

   # 接收并录制
   ffmpeg -protocol_whitelist file,rtp,udp -i video.sdp -c copy output.mp4

音视频同时发送
--------------------------

.. code-block:: bash

   # 同时发送音频和视频 RTP 流（需要 SDP 描述）
   ffmpeg -re -i input.mp4 \
     -map 0:v -c:v libx264 -tune zerolatency -b:v 500k -f rtp rtp://127.0.0.1:5004 \
     -map 0:a -c:a libopus -b:a 48k -f rtp rtp://127.0.0.1:5006 \
     > sdp_output.sdp


RTSP 推拉流
==============

.. code-block:: bash

   # 拉取 RTSP 流并录制为 MP4
   ffmpeg -rtsp_transport tcp -i rtsp://server/stream -c copy output.mp4

   # 拉取 RTSP 流并转推为 RTP
   ffmpeg -rtsp_transport tcp -i rtsp://server/stream \
     -c:v copy -f rtp rtp://127.0.0.1:5004


YUV 原始视频处理
==============

WebRTC 内部使用 YUV（通常是 I420）作为原始视频格式。FFmpeg 可以方便地处理 YUV 文件。

.. code-block:: bash

   # 将视频解码为 YUV I420
   ffmpeg -i input.mp4 -pix_fmt yuv420p -s 1280x720 output.yuv

   # 播放 YUV 文件（需要指定尺寸和格式）
   ffplay -f rawvideo -pixel_format yuv420p -video_size 1280x720 output.yuv

   # 将 YUV 编码为 H.264
   ffmpeg -f rawvideo -pixel_format yuv420p -video_size 1280x720 -framerate 30 \
     -i input.yuv -c:v libx264 output.mp4


PCM 原始音频处理
==============

.. code-block:: bash

   # 将音频解码为 PCM（16bit, 48kHz, 单声道）
   ffmpeg -i input.opus -f s16le -acodec pcm_s16le -ar 48000 -ac 1 output.pcm

   # 播放 PCM 文件
   ffplay -f s16le -ar 48000 -ac 1 output.pcm

   # 将 PCM 编码为 Opus
   ffmpeg -f s16le -ar 48000 -ac 1 -i input.pcm -c:a libopus output.opus


视频质量对比
==============

在评估 WebRTC 视频质量时，常用 PSNR 和 SSIM 指标：

.. code-block:: bash

   # 计算 PSNR
   ffmpeg -i degraded.mp4 -i reference.mp4 -lavfi psnr -f null -

   # 计算 SSIM
   ffmpeg -i degraded.mp4 -i reference.mp4 -lavfi ssim -f null -

   # 同时计算 PSNR 和 SSIM，输出到文件
   ffmpeg -i degraded.mp4 -i reference.mp4 \
     -lavfi "[0:v][1:v]psnr=stats_file=psnr.log;[0:v][1:v]ssim=stats_file=ssim.log" \
     -f null -


常用技巧
==============

截取片段
--------------------------

.. code-block:: bash

   # 从第 10 秒开始截取 5 秒（不重新编码）
   ffmpeg -ss 10 -t 5 -i input.mp4 -c copy clip.mp4

提取单帧图片
--------------------------

.. code-block:: bash

   # 提取第 5 秒的一帧
   ffmpeg -ss 5 -i input.mp4 -frames:v 1 frame.png

添加水印
--------------------------

.. code-block:: bash

   ffmpeg -i input.mp4 -i logo.png \
     -filter_complex "overlay=10:10" output.mp4

根据图片和音频制作视频
--------------------------

.. code-block:: bash

   ffmpeg -loop 1 -i image.jpg -i audio.wav -c:v libx264 -tune stillimage \
     -c:a aac -b:a 128k -shortest output.mp4


FFmpeg 库编程
=================

除了命令行工具，FFmpeg 的核心价值在于它的共享库。在 WebRTC 相关项目中，
很多场景需要在代码中直接调用 FFmpeg 库来处理音视频数据，例如：

- 在 SFU/MCU 服务端对媒体流进行转码
- 对 WebRTC 录制文件进行后处理
- 在测试框架中程序化地生成和分析媒体
- 音频重采样（如 48kHz → 16kHz 用于语音识别）

编译和链接
--------------------------

.. code-block:: bash

   # 安装开发库（Ubuntu/Debian）
   sudo apt install libavcodec-dev libavformat-dev libavutil-dev \
       libswresample-dev libswscale-dev libavfilter-dev

   # macOS (Homebrew)
   brew install ffmpeg

   # 编译时链接
   gcc -o my_app my_app.c \
       $(pkg-config --cflags --libs libavcodec libavformat libavutil libswresample libswscale)

   # 或者手动指定
   gcc -o my_app my_app.c \
       -lavcodec -lavformat -lavutil -lswresample -lswscale -lm

核心数据结构
--------------------------

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - 结构体
     - 说明
   * - ``AVFormatContext``
     - 封装/解封装上下文，代表一个媒体文件或流。包含流信息、元数据等
   * - ``AVCodecContext``
     - 编解码器上下文，包含编解码参数（比特率、采样率、分辨率等）
   * - ``AVCodec``
     - 编解码器描述，通过 ``avcodec_find_encoder/decoder`` 获取
   * - ``AVPacket``
     - 编码后的数据包（压缩数据），对应一个或多个帧
   * - ``AVFrame``
     - 原始帧数据（解码后），视频是 YUV/RGB 像素，音频是 PCM 采样
   * - ``SwrContext``
     - 音频重采样上下文（libswresample）
   * - ``SwsContext``
     - 视频缩放/像素格式转换上下文（libswscale）

核心 API 流程
--------------------------

现代 FFmpeg（≥3.1）使用 send/receive 模式进行编解码：

.. code-block:: text

   编码流程:
   AVFrame(原始数据) → avcodec_send_frame() → [编码器] → avcodec_receive_packet() → AVPacket(压缩数据)

   解码流程:
   AVPacket(压缩数据) → avcodec_send_packet() → [解码器] → avcodec_receive_frame() → AVFrame(原始数据)

   解封装（读文件）:
   avformat_open_input() → avformat_find_stream_info() → av_read_frame() → AVPacket

   封装（写文件）:
   avformat_alloc_output_context2() → avformat_new_stream() → avformat_write_header()
   → av_interleaved_write_frame() → av_write_trailer()


例 1：音频解码（文件 → PCM）
=====================================

将音频文件解码为原始 PCM 数据，是 WebRTC 录制回放、语音分析等场景的基础操作。

.. code-block:: c

   #include <libavcodec/avcodec.h>
   #include <libavformat/avformat.h>
   #include <libavutil/avutil.h>
   #include <stdio.h>

   int decode_audio_to_pcm(const char *input_file, const char *output_file) {
       AVFormatContext *fmt_ctx = NULL;
       AVCodecContext *codec_ctx = NULL;
       const AVCodec *codec = NULL;
       AVPacket *pkt = NULL;
       AVFrame *frame = NULL;
       FILE *out_fp = NULL;
       int ret, audio_stream_idx;

       // 1. 打开输入文件
       ret = avformat_open_input(&fmt_ctx, input_file, NULL, NULL);
       if (ret < 0) {
           fprintf(stderr, "无法打开文件: %s\n", av_err2str(ret));
           return ret;
       }

       // 2. 读取流信息
       ret = avformat_find_stream_info(fmt_ctx, NULL);
       if (ret < 0) {
           fprintf(stderr, "无法获取流信息: %s\n", av_err2str(ret));
           goto end;
       }

       // 3. 找到音频流
       audio_stream_idx = av_find_best_stream(
           fmt_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, &codec, 0);
       if (audio_stream_idx < 0) {
           fprintf(stderr, "找不到音频流\n");
           ret = audio_stream_idx;
           goto end;
       }

       // 4. 创建并配置解码器上下文
       codec_ctx = avcodec_alloc_context3(codec);
       avcodec_parameters_to_context(codec_ctx,
           fmt_ctx->streams[audio_stream_idx]->codecpar);
       ret = avcodec_open2(codec_ctx, codec, NULL);
       if (ret < 0) {
           fprintf(stderr, "无法打开解码器: %s\n", av_err2str(ret));
           goto end;
       }

       printf("音频: %s, %d Hz, %d 声道, 格式: %s\n",
              codec->name, codec_ctx->sample_rate, codec_ctx->ch_layout.nb_channels,
              av_get_sample_fmt_name(codec_ctx->sample_fmt));

       // 5. 解码循环
       pkt = av_packet_alloc();
       frame = av_frame_alloc();
       out_fp = fopen(output_file, "wb");

       while (av_read_frame(fmt_ctx, pkt) >= 0) {
           if (pkt->stream_index != audio_stream_idx) {
               av_packet_unref(pkt);
               continue;
           }

           ret = avcodec_send_packet(codec_ctx, pkt);
           if (ret < 0) {
               av_packet_unref(pkt);
               continue;
           }

           while (avcodec_receive_frame(codec_ctx, frame) == 0) {
               // 写入 PCM 数据
               // 对于 planar 格式(如 fltp)，各声道数据分开存储在 frame->data[ch] 中
               // 对于 interleaved 格式(如 s16)，所有声道数据交错在 frame->data[0] 中
               int data_size = av_get_bytes_per_sample(codec_ctx->sample_fmt);
               if (av_sample_fmt_is_planar(codec_ctx->sample_fmt)) {
                   // planar: 交错写入各声道
                   for (int i = 0; i < frame->nb_samples; i++) {
                       for (int ch = 0; ch < codec_ctx->ch_layout.nb_channels; ch++) {
                           fwrite(frame->data[ch] + data_size * i,
                                  1, data_size, out_fp);
                       }
                   }
               } else {
                   // interleaved: 直接写入
                   fwrite(frame->data[0], 1,
                          data_size * frame->nb_samples * codec_ctx->ch_layout.nb_channels,
                          out_fp);
               }
           }
           av_packet_unref(pkt);
       }

       // 6. flush 解码器（取出缓冲帧）
       avcodec_send_packet(codec_ctx, NULL);
       while (avcodec_receive_frame(codec_ctx, frame) == 0) {
           // 同上写入...
       }

       printf("解码完成: %s → %s\n", input_file, output_file);

   end:
       if (out_fp) fclose(out_fp);
       av_frame_free(&frame);
       av_packet_free(&pkt);
       avcodec_free_context(&codec_ctx);
       avformat_close_input(&fmt_ctx);
       return ret;
   }

   int main(int argc, char *argv[]) {
       if (argc < 3) {
           fprintf(stderr, "用法: %s <输入文件> <输出.pcm>\n", argv[0]);
           return 1;
       }
       return decode_audio_to_pcm(argv[1], argv[2]);
   }

编译运行：

.. code-block:: bash

   gcc -o audio_decode audio_decode.c \
       $(pkg-config --cflags --libs libavcodec libavformat libavutil)
   ./audio_decode input.opus output.pcm

   # 用 ffplay 验证解码结果（需要知道格式，此处假设 float planar 48kHz 立体声）
   ffplay -f f32le -ar 48000 -ac 2 output.pcm

.. tip::

   Opus 解码器输出的采样格式通常是 ``AV_SAMPLE_FMT_FLT``（32 位浮点）。
   如果需要 16 位整数 PCM（大多数语音处理库要求），需要用 libswresample 做格式转换。


例 2：音频编码（PCM → Opus）
=====================================

将 PCM 原始音频编码为 Opus 并写入 OGG 容器：

.. code-block:: c

   #include <libavcodec/avcodec.h>
   #include <libavformat/avformat.h>
   #include <libavutil/opt.h>
   #include <libavutil/channel_layout.h>
   #include <stdio.h>

   int encode_pcm_to_opus(const char *output_file) {
       const AVCodec *codec;
       AVCodecContext *c = NULL;
       AVFormatContext *oc = NULL;
       AVStream *st = NULL;
       AVFrame *frame = NULL;
       AVPacket *pkt = NULL;
       int ret;

       // 1. 创建输出格式上下文（OGG 容器）
       avformat_alloc_output_context2(&oc, NULL, NULL, output_file);
       if (!oc) {
           fprintf(stderr, "无法创建输出上下文\n");
           return -1;
       }

       // 2. 找到 Opus 编码器
       codec = avcodec_find_encoder(AV_CODEC_ID_OPUS);
       if (!codec) {
           fprintf(stderr, "找不到 Opus 编码器\n");
           return -1;
       }

       // 3. 添加音频流
       st = avformat_new_stream(oc, codec);

       // 4. 配置编码器
       c = avcodec_alloc_context3(codec);
       c->sample_rate = 48000;
       c->sample_fmt = AV_SAMPLE_FMT_FLT;  // Opus 接受 float
       c->bit_rate = 64000;
       av_channel_layout_default(&c->ch_layout, 1);  // mono

       if (oc->oformat->flags & AVFMT_GLOBALHEADER)
           c->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;

       ret = avcodec_open2(c, codec, NULL);
       if (ret < 0) {
           fprintf(stderr, "无法打开编码器: %s\n", av_err2str(ret));
           return ret;
       }
       avcodec_parameters_from_context(st->codecpar, c);
       st->time_base = (AVRational){1, c->sample_rate};

       printf("Opus 编码器: frame_size=%d, sample_rate=%d\n",
              c->frame_size, c->sample_rate);

       // 5. 打开输出文件
       ret = avio_open(&oc->pb, output_file, AVIO_FLAG_WRITE);
       if (ret < 0) {
           fprintf(stderr, "无法打开输出文件\n");
           return ret;
       }
       avformat_write_header(oc, NULL);

       // 6. 生成测试音频并编码
       frame = av_frame_alloc();
       frame->nb_samples = c->frame_size;   // Opus: 通常 960 (20ms @48kHz)
       frame->format = c->sample_fmt;
       av_channel_layout_copy(&frame->ch_layout, &c->ch_layout);
       av_frame_get_buffer(frame, 0);

       pkt = av_packet_alloc();

       int total_samples = 48000 * 5;  // 5 秒
       int samples_encoded = 0;

       while (samples_encoded < total_samples) {
           av_frame_make_writable(frame);

           // 生成 1kHz 正弦波
           float *data = (float *)frame->data[0];
           for (int i = 0; i < c->frame_size; i++) {
               double t = (double)(samples_encoded + i) / c->sample_rate;
               data[i] = 0.5f * sinf(2.0f * M_PI * 1000.0 * t);
           }

           frame->pts = samples_encoded;
           samples_encoded += c->frame_size;

           // 编码
           ret = avcodec_send_frame(c, frame);
           if (ret < 0) continue;

           while (avcodec_receive_packet(c, pkt) == 0) {
               av_packet_rescale_ts(pkt, c->time_base, st->time_base);
               pkt->stream_index = st->index;
               av_interleaved_write_frame(oc, pkt);
               av_packet_unref(pkt);
           }
       }

       // 7. flush 编码器
       avcodec_send_frame(c, NULL);
       while (avcodec_receive_packet(c, pkt) == 0) {
           av_packet_rescale_ts(pkt, c->time_base, st->time_base);
           pkt->stream_index = st->index;
           av_interleaved_write_frame(oc, pkt);
           av_packet_unref(pkt);
       }

       av_write_trailer(oc);
       printf("编码完成: %s\n", output_file);

       // 清理
       av_frame_free(&frame);
       av_packet_free(&pkt);
       avcodec_free_context(&c);
       avio_closep(&oc->pb);
       avformat_free_context(oc);
       return 0;
   }

   int main(void) {
       return encode_pcm_to_opus("test_output.ogg");
   }

编译运行：

.. code-block:: bash

   gcc -o audio_encode audio_encode.c -lm \
       $(pkg-config --cflags --libs libavcodec libavformat libavutil)
   ./audio_encode
   ffplay test_output.ogg


例 3：音频重采样（libswresample）
=====================================

WebRTC 音频通常是 48kHz，但语音识别引擎常要求 16kHz。
用 libswresample 可以在代码中完成重采样和格式转换。

.. code-block:: c

   #include <libswresample/swresample.h>
   #include <libavutil/channel_layout.h>
   #include <libavutil/samplefmt.h>
   #include <stdio.h>

   /**
    * 将 float 48kHz 立体声 → int16 16kHz 单声道
    * 这是 WebRTC Opus 解码输出 → 语音识别引擎输入的典型转换
    */
   int resample_audio(void) {
       SwrContext *swr = NULL;
       int ret;

       // 1. 配置重采样上下文
       AVChannelLayout in_layout  = AV_CHANNEL_LAYOUT_STEREO;
       AVChannelLayout out_layout = AV_CHANNEL_LAYOUT_MONO;

       ret = swr_alloc_set_opts2(&swr,
           &out_layout,  AV_SAMPLE_FMT_S16,  16000,   // 输出: mono, s16, 16kHz
           &in_layout,   AV_SAMPLE_FMT_FLT,  48000,   // 输入: stereo, float, 48kHz
           0, NULL);
       if (ret < 0 || !swr) {
           fprintf(stderr, "无法创建重采样上下文\n");
           return -1;
       }
       swr_init(swr);

       // 2. 准备输入数据（模拟 20ms @48kHz 立体声 = 960 samples）
       int in_samples = 960;
       float in_buf[960 * 2];  // 960 samples * 2 channels
       for (int i = 0; i < in_samples; i++) {
           float val = 0.5f * sinf(2.0f * 3.14159f * 1000.0f * i / 48000.0f);
           in_buf[i * 2] = val;      // left
           in_buf[i * 2 + 1] = val;  // right
       }

       // 3. 计算输出采样数
       // 48kHz → 16kHz, 960 输入 → ~320 输出
       int out_samples = av_rescale_rnd(
           swr_get_delay(swr, 48000) + in_samples,
           16000, 48000, AV_ROUND_UP);

       int16_t out_buf[out_samples];

       // 4. 执行重采样
       const uint8_t *in_data[1]  = { (const uint8_t *)in_buf };
       uint8_t       *out_data[1] = { (uint8_t *)out_buf };

       int converted = swr_convert(swr,
           out_data, out_samples,
           in_data,  in_samples);

       printf("重采样: %d samples (48kHz stereo float) → %d samples (16kHz mono s16)\n",
              in_samples, converted);

       // 5. out_buf 现在包含 16kHz 单声道 int16 PCM，可送入语音识别引擎
       // 例如: whisper_full(ctx, params, out_buf, converted);

       swr_free(&swr);
       return 0;
   }

.. note::

   ``swr_alloc_set_opts2`` 是 FFmpeg 6.0+ 的新 API，替代了弃用的 ``swr_alloc_set_opts``。
   旧版本请使用旧 API 或通过 ``av_opt_set_*`` 逐项设置。


例 4：视频解码（文件 → YUV 帧）
=====================================

从视频文件中解码出原始 YUV 帧，用于质量分析或后续处理：

.. code-block:: c

   #include <libavcodec/avcodec.h>
   #include <libavformat/avformat.h>
   #include <libavutil/imgutils.h>
   #include <stdio.h>

   int decode_video_frames(const char *input_file, int max_frames) {
       AVFormatContext *fmt_ctx = NULL;
       AVCodecContext *codec_ctx = NULL;
       const AVCodec *codec = NULL;
       AVPacket *pkt = NULL;
       AVFrame *frame = NULL;
       int ret, video_stream_idx, frame_count = 0;

       // 1. 打开输入文件
       ret = avformat_open_input(&fmt_ctx, input_file, NULL, NULL);
       if (ret < 0) return ret;
       avformat_find_stream_info(fmt_ctx, NULL);

       // 2. 找到视频流并打开解码器
       video_stream_idx = av_find_best_stream(
           fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &codec, 0);
       if (video_stream_idx < 0) return video_stream_idx;

       codec_ctx = avcodec_alloc_context3(codec);
       avcodec_parameters_to_context(codec_ctx,
           fmt_ctx->streams[video_stream_idx]->codecpar);
       avcodec_open2(codec_ctx, codec, NULL);

       printf("视频: %s, %dx%d, 像素格式: %s\n",
              codec->name, codec_ctx->width, codec_ctx->height,
              av_get_pix_fmt_name(codec_ctx->pix_fmt));

       // 3. 解码循环
       pkt = av_packet_alloc();
       frame = av_frame_alloc();

       while (av_read_frame(fmt_ctx, pkt) >= 0 && frame_count < max_frames) {
           if (pkt->stream_index != video_stream_idx) {
               av_packet_unref(pkt);
               continue;
           }

           ret = avcodec_send_packet(codec_ctx, pkt);
           av_packet_unref(pkt);
           if (ret < 0) continue;

           while (avcodec_receive_frame(codec_ctx, frame) == 0) {
               frame_count++;
               printf("帧 #%d: pts=%ld, type=%c, size=%dx%d\n",
                      frame_count, frame->pts,
                      av_get_picture_type_char(frame->pict_type),
                      frame->width, frame->height);

               // 访问 YUV 数据:
               // frame->data[0] = Y 平面, frame->linesize[0] = Y 行字节数
               // frame->data[1] = U 平面, frame->linesize[1] = U 行字节数
               // frame->data[2] = V 平面, frame->linesize[2] = V 行字节数
               //
               // 注意: linesize 可能包含 padding（对齐），不一定等于 width

               // 例如写入 YUV 文件:
               // write_yuv_frame(fp, frame);

               av_frame_unref(frame);
           }
       }

       printf("共解码 %d 帧\n", frame_count);

       av_frame_free(&frame);
       av_packet_free(&pkt);
       avcodec_free_context(&codec_ctx);
       avformat_close_input(&fmt_ctx);
       return 0;
   }

编译运行：

.. code-block:: bash

   gcc -o video_decode video_decode.c \
       $(pkg-config --cflags --libs libavcodec libavformat libavutil)
   ./video_decode test_video.mp4 10


例 5：视频编码（YUV → H.264）
=====================================

将原始 YUV 帧编码为 H.264 并写入 MP4 容器。
这在 WebRTC 录制后处理（如将 RTP dump 重新编码为标准文件）中很常见。

.. code-block:: c

   #include <libavcodec/avcodec.h>
   #include <libavformat/avformat.h>
   #include <libavutil/imgutils.h>
   #include <libavutil/opt.h>
   #include <stdio.h>

   int encode_video_to_h264(const char *output_file) {
       const AVCodec *codec;
       AVCodecContext *c = NULL;
       AVFormatContext *oc = NULL;
       AVStream *st = NULL;
       AVFrame *frame = NULL;
       AVPacket *pkt = NULL;
       int ret;

       // 1. 创建输出上下文
       avformat_alloc_output_context2(&oc, NULL, NULL, output_file);
       codec = avcodec_find_encoder(AV_CODEC_ID_H264);

       // 2. 添加视频流
       st = avformat_new_stream(oc, codec);

       // 3. 配置编码器
       c = avcodec_alloc_context3(codec);
       c->width = 1280;
       c->height = 720;
       c->pix_fmt = AV_PIX_FMT_YUV420P;
       c->time_base = (AVRational){1, 30};
       c->framerate = (AVRational){30, 1};
       c->bit_rate = 2000000;  // 2 Mbps
       c->gop_size = 30;       // 每秒一个关键帧
       c->max_b_frames = 0;    // WebRTC 场景通常不用 B 帧

       // WebRTC 友好的 H.264 参数
       av_opt_set(c->priv_data, "preset", "ultrafast", 0);
       av_opt_set(c->priv_data, "tune", "zerolatency", 0);
       av_opt_set(c->priv_data, "profile", "baseline", 0);

       if (oc->oformat->flags & AVFMT_GLOBALHEADER)
           c->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;

       avcodec_open2(c, codec, NULL);
       avcodec_parameters_from_context(st->codecpar, c);
       st->time_base = c->time_base;

       // 4. 打开输出文件
       avio_open(&oc->pb, output_file, AVIO_FLAG_WRITE);
       avformat_write_header(oc, NULL);

       // 5. 生成测试帧并编码
       frame = av_frame_alloc();
       frame->format = c->pix_fmt;
       frame->width = c->width;
       frame->height = c->height;
       av_frame_get_buffer(frame, 0);

       pkt = av_packet_alloc();

       for (int i = 0; i < 150; i++) {  // 5 秒 @30fps
           av_frame_make_writable(frame);

           // 生成渐变测试图案
           for (int y = 0; y < c->height; y++) {
               for (int x = 0; x < c->width; x++) {
                   frame->data[0][y * frame->linesize[0] + x] =
                       (x + y + i * 3) & 0xFF;  // Y: 动态渐变
               }
           }
           for (int y = 0; y < c->height / 2; y++) {
               for (int x = 0; x < c->width / 2; x++) {
                   frame->data[1][y * frame->linesize[1] + x] = 128 + y + i * 2;  // U
                   frame->data[2][y * frame->linesize[2] + x] = 64 + x + i;       // V
               }
           }

           frame->pts = i;

           avcodec_send_frame(c, frame);
           while (avcodec_receive_packet(c, pkt) == 0) {
               av_packet_rescale_ts(pkt, c->time_base, st->time_base);
               pkt->stream_index = st->index;
               av_interleaved_write_frame(oc, pkt);
               av_packet_unref(pkt);
           }
       }

       // 6. flush
       avcodec_send_frame(c, NULL);
       while (avcodec_receive_packet(c, pkt) == 0) {
           av_packet_rescale_ts(pkt, c->time_base, st->time_base);
           pkt->stream_index = st->index;
           av_interleaved_write_frame(oc, pkt);
           av_packet_unref(pkt);
       }

       av_write_trailer(oc);
       printf("编码完成: %s (%dx%d, H.264 baseline, 5s @30fps)\n",
              output_file, c->width, c->height);

       av_frame_free(&frame);
       av_packet_free(&pkt);
       avcodec_free_context(&c);
       avio_closep(&oc->pb);
       avformat_free_context(oc);
       return 0;
   }

.. tip::

   WebRTC 中 H.264 通常使用 Baseline profile + ``zerolatency`` 调优 + 无 B 帧，
   以最小化编码延迟。``max_b_frames=0`` 和 ``tune=zerolatency`` 是关键设置。


例 6：视频缩放和像素格式转换（libswscale）
================================================

在 WebRTC 中，可能需要将摄像头采集的 NV12/YUYV 转为 I420，或对视频进行缩放：

.. code-block:: c

   #include <libswscale/swscale.h>
   #include <libavutil/imgutils.h>
   #include <libavutil/pixfmt.h>
   #include <stdio.h>

   int scale_video_frame(void) {
       int src_w = 1920, src_h = 1080;
       int dst_w = 640,  dst_h = 360;

       // 1. 创建缩放上下文: 1080p NV12 → 360p I420
       struct SwsContext *sws = sws_getContext(
           src_w, src_h, AV_PIX_FMT_NV12,     // 输入: 摄像头常见格式
           dst_w, dst_h, AV_PIX_FMT_YUV420P,   // 输出: WebRTC 内部格式
           SWS_BILINEAR, NULL, NULL, NULL);
       if (!sws) {
           fprintf(stderr, "无法创建缩放上下文\n");
           return -1;
       }

       // 2. 分配输入/输出缓冲区
       uint8_t *src_data[4], *dst_data[4];
       int src_linesize[4], dst_linesize[4];

       av_image_alloc(src_data, src_linesize, src_w, src_h, AV_PIX_FMT_NV12, 16);
       av_image_alloc(dst_data, dst_linesize, dst_w, dst_h, AV_PIX_FMT_YUV420P, 16);

       // 3. 填充测试数据（模拟摄像头采集的 NV12 帧）
       memset(src_data[0], 128, src_linesize[0] * src_h);      // Y plane
       memset(src_data[1], 128, src_linesize[1] * src_h / 2);  // UV interleaved

       // 4. 执行缩放 + 格式转换
       sws_scale(sws,
           (const uint8_t *const *)src_data, src_linesize, 0, src_h,
           dst_data, dst_linesize);

       printf("缩放: %dx%d NV12 → %dx%d I420\n", src_w, src_h, dst_w, dst_h);
       printf("输出 Y plane: %d bytes/line, U: %d, V: %d\n",
              dst_linesize[0], dst_linesize[1], dst_linesize[2]);

       // dst_data[0/1/2] 现在包含 I420 格式的 640x360 帧
       // 可直接送入 WebRTC 编码器

       av_freep(&src_data[0]);
       av_freep(&dst_data[0]);
       sws_freeContext(sws);
       return 0;
   }


例 7：完整转码流程（解封装 → 解码 → 重采样 → 编码 → 封装）
====================================================================

将任意音频文件转码为 WebRTC 友好的 Opus 48kHz 单声道，
展示 FFmpeg 各库协同工作的完整流程：

.. code-block:: c

   #include <libavcodec/avcodec.h>
   #include <libavformat/avformat.h>
   #include <libswresample/swresample.h>
   #include <libavutil/opt.h>
   #include <libavutil/channel_layout.h>
   #include <stdio.h>

   int transcode_to_opus(const char *input, const char *output) {
       // === 输入端 ===
       AVFormatContext *ifmt = NULL;
       AVCodecContext *dec_ctx = NULL;
       int audio_idx;

       avformat_open_input(&ifmt, input, NULL, NULL);
       avformat_find_stream_info(ifmt, NULL);

       const AVCodec *dec;
       audio_idx = av_find_best_stream(ifmt, AVMEDIA_TYPE_AUDIO, -1, -1, &dec, 0);
       dec_ctx = avcodec_alloc_context3(dec);
       avcodec_parameters_to_context(dec_ctx, ifmt->streams[audio_idx]->codecpar);
       avcodec_open2(dec_ctx, dec, NULL);

       printf("输入: %s, %dHz, %d ch\n",
              dec->name, dec_ctx->sample_rate, dec_ctx->ch_layout.nb_channels);

       // === 重采样器 ===
       SwrContext *swr = NULL;
       AVChannelLayout out_layout = AV_CHANNEL_LAYOUT_MONO;
       swr_alloc_set_opts2(&swr,
           &out_layout, AV_SAMPLE_FMT_FLT, 48000,
           &dec_ctx->ch_layout, dec_ctx->sample_fmt, dec_ctx->sample_rate,
           0, NULL);
       swr_init(swr);

       // === 输出端 ===
       AVFormatContext *ofmt = NULL;
       avformat_alloc_output_context2(&ofmt, NULL, NULL, output);
       const AVCodec *enc = avcodec_find_encoder(AV_CODEC_ID_OPUS);
       AVStream *ost = avformat_new_stream(ofmt, enc);

       AVCodecContext *enc_ctx = avcodec_alloc_context3(enc);
       enc_ctx->sample_rate = 48000;
       enc_ctx->sample_fmt = AV_SAMPLE_FMT_FLT;
       enc_ctx->bit_rate = 48000;
       av_channel_layout_default(&enc_ctx->ch_layout, 1);
       if (ofmt->oformat->flags & AVFMT_GLOBALHEADER)
           enc_ctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
       avcodec_open2(enc_ctx, enc, NULL);
       avcodec_parameters_from_context(ost->codecpar, enc_ctx);
       ost->time_base = (AVRational){1, 48000};

       avio_open(&ofmt->pb, output, AVIO_FLAG_WRITE);
       avformat_write_header(ofmt, NULL);

       // === 转码循环 ===
       AVPacket *in_pkt = av_packet_alloc();
       AVPacket *out_pkt = av_packet_alloc();
       AVFrame *dec_frame = av_frame_alloc();
       AVFrame *enc_frame = av_frame_alloc();

       enc_frame->nb_samples = enc_ctx->frame_size;
       enc_frame->format = enc_ctx->sample_fmt;
       av_channel_layout_copy(&enc_frame->ch_layout, &enc_ctx->ch_layout);
       av_frame_get_buffer(enc_frame, 0);

       int64_t pts = 0;

       while (av_read_frame(ifmt, in_pkt) >= 0) {
           if (in_pkt->stream_index != audio_idx) {
               av_packet_unref(in_pkt);
               continue;
           }

           avcodec_send_packet(dec_ctx, in_pkt);
           av_packet_unref(in_pkt);

           while (avcodec_receive_frame(dec_ctx, dec_frame) == 0) {
               // 重采样
               av_frame_make_writable(enc_frame);
               int out_count = swr_convert(swr,
                   enc_frame->data, enc_frame->nb_samples,
                   (const uint8_t **)dec_frame->data, dec_frame->nb_samples);

               if (out_count <= 0) continue;
               enc_frame->nb_samples = out_count;
               enc_frame->pts = pts;
               pts += out_count;

               // 编码
               avcodec_send_frame(enc_ctx, enc_frame);
               while (avcodec_receive_packet(enc_ctx, out_pkt) == 0) {
                   av_packet_rescale_ts(out_pkt, enc_ctx->time_base, ost->time_base);
                   out_pkt->stream_index = ost->index;
                   av_interleaved_write_frame(ofmt, out_pkt);
                   av_packet_unref(out_pkt);
               }
           }
       }

       av_write_trailer(ofmt);
       printf("转码完成: %s → %s (Opus 48kHz mono 48kbps)\n", input, output);

       // 清理（省略详细释放代码）
       swr_free(&swr);
       av_frame_free(&dec_frame);
       av_frame_free(&enc_frame);
       av_packet_free(&in_pkt);
       av_packet_free(&out_pkt);
       avcodec_free_context(&dec_ctx);
       avcodec_free_context(&enc_ctx);
       avformat_close_input(&ifmt);
       avio_closep(&ofmt->pb);
       avformat_free_context(ofmt);
       return 0;
   }


常见陷阱与最佳实践
============================

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - 陷阱
     - 说明
   * - Planar vs Interleaved
     - Opus/AAC 解码输出通常是 planar float (``fltp``)，各声道数据在 ``data[0]``、``data[1]``...。
       直接把 ``data[0]`` 当成交错数据会得到错误结果
   * - linesize ≠ width
     - 视频帧的 ``linesize`` 包含内存对齐 padding，不能直接用 ``width * bytes_per_pixel`` 计算行大小
   * - 忘记 flush
     - 编解码器内部会缓冲数据。处理完输入后必须发送 ``NULL`` 帧/包来 flush，否则会丢失末尾数据
   * - 时间基转换
     - 不同阶段的时间基不同（解码器 vs 流 vs 编码器）。
       必须用 ``av_packet_rescale_ts`` 或 ``av_rescale_q`` 正确转换
   * - 内存泄漏
     - ``AVPacket`` 和 ``AVFrame`` 使用后必须 ``unref``，上下文必须用对应的 ``free`` 函数释放
   * - 线程安全
     - ``AVCodecContext`` 不是线程安全的。多线程环境中每个线程需要独立的上下文


参考资料
========

- 官网: https://ffmpeg.org/
- 官方文档: https://ffmpeg.org/documentation.html
- FFmpeg Wiki: https://trac.ffmpeg.org/wiki
- FFmpeg Filters 文档: https://ffmpeg.org/ffmpeg-filters.html
- FFmpeg API 示例: https://ffmpeg.org/doxygen/trunk/examples.html
- libavcodec 编解码 API: https://ffmpeg.org/doxygen/trunk/group__lavc__encdec.html
- libswresample 重采样: https://ffmpeg.org/doxygen/trunk/group__lswr.html
- libswscale 缩放: https://ffmpeg.org/doxygen/trunk/group__libsws.html

.. _ffmpeg: https://ffmpeg.org/ffmpeg.html
.. _ffplay: https://ffmpeg.org/ffplay.html
.. _ffprobe: https://ffmpeg.org/ffprobe.html
