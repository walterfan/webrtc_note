# WebRTC 学习笔记

[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

系统性的 WebRTC 实时通信技术学习笔记，涵盖从基础概念到源码分析的完整知识体系。

📖 **在线阅读**: [https://walterfan.github.io/webrtc_note/](https://walterfan.github.io/webrtc_note/)

## 📚 目录

### 0. WebRTC 简明教程
- 概述 | 学习路线 | 第1-4周学习计划

### 1. WebRTC 基础
- 浏览器架构 | WebRTC 规范 | WebRTC API
- 基本元素 | 实体关系 | 通信流程
- 媒体捕获 | 屏幕共享 | 媒体录制
- RTP 扩展 | 能力协商 | 信令 | SDP | 统计

### 2. WebRTC 传输
- WebSocket | STUN | TURN | ICE
- QUIC | RTMP | TLS | DTLS | SCTP | SRTP | WHIP
- BFCP | RTP | RTCP | DataChannel
- RTP 头扩展 | 多路复用 | BUNDLE

### 3. WebRTC 媒体
- **音频**: 基础 | 处理流水线 | 音量 | API | QoS | AEC | VAD | AGC | ANS | Jitter Buffer | AudioWorklet | 质量 | Opus
- **视频**: 基础 | 编解码 | H.264 | AV1 | 自适应 | 流水线 | 唇同步 | YUV
- **QoS**: 拥塞控制 | GCC | REMB | TWCC | 带宽探测 | FEC | RTX | RED | Simulcast | SVC
- **新特性**: Insertable Streams | WebCodecs | WebTransport

### 4. WebRTC 源码分析
- 构建工具 | 编译浏览器 | WebRTC 构建与测试
- Demux | Thread | Call 模块
- GCC 实现 | BWE (GCC/Probe/REMB/Loss)
- Pacer | DTLS | SCTP | RTP/RTCP 模块
- Packet Buffer | RTX | NACK
- PeerConnection | SDP Offer/Answer | Video Flow
- Janus | aiortc | libopus | libopenh264

### 5. WebRTC 实践
- FAQ | WebAssembly | CoTURN | AppRTC
- SFU 架构 | OWT | Janus | MediaSoup | Pion | SRS
- 音视频质量 | 远程共享与控制 | 安全

### 6. WebRTC 工具
- DevTools | Netcat | Scapy | SoX
- FFmpeg | GStreamer | OpenSSL
- VNC | TC | iPerf | Perf | tcpdump | Wireshark
- 网络模拟器 | 分析工具 | Docker | Selenium | Fuzzer

### 7. 关联技术
- 信号处理 | DSP | 卡尔曼滤波 | 安全
- MATLAB | 多媒体 | 数学 | 统计 | 科学计算

## 🛠 安装与构建

### 环境准备

```bash
# macOS
brew install python3 graphviz plantuml
make setup
```

### PlantUML (可选)

默认优先使用系统里的 `plantuml` 可执行文件。

```bash
# macOS
brew install plantuml graphviz
```

如果你希望显式指定命令，也可以在构建前设置 `PLANTUML` 环境变量。

### 构建 HTML

```bash
make build
# 输出在 build/html/ 目录
```

### 本地预览

```bash
cd build/html && python -m http.server 8000
# 访问 http://localhost:8000
```

### 发布到 GitHub Pages

```bash
make publish
```

`make publish` 会先执行本地构建，然后推送当前分支。
GitHub Pages workflow 会在推送到 `master` 或 `main` 时自动部署站点。
首次启用时，请在仓库设置中将 Pages 的部署来源配置为 GitHub Actions。

## 📊 项目统计

- **文件数**: 204 个 RST 文件
- **内容量**: ~1.3 MB 文本
- **图片数**: 110+ 张
- **章节数**: 8 大章节
- **起始时间**: 2021 年 2 月

## 📝 许可证

本作品采用 [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) 许可证。

## 👤 作者

**Walter Fan** - [walterfan.github.io](https://walterfan.github.io)
