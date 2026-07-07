.. _neteq_deep_dive:

============================
WebRTC NetEQ 深度解析
============================

.. contents:: 目录
   :local:
   :depth: 2

概述
====

NetEQ 是 WebRTC 音频引擎中最精妙的模块之一——它不仅是一个 Jitter Buffer，更是一个集**抖动缓冲、丢包隐藏、时间拉伸、舒适噪声生成**于一体的音频播放引擎。

NetEQ 的名字来源于 "Network Equalizer"，意为"网络均衡器"——将不均匀的网络包流均衡为平滑的音频播放流。

.. mermaid::

   flowchart TD
     A[RTP 包到达] --> B[Packet Buffer<br/>包缓冲 + 排序]
     B --> C[MCU<br/>主控制单元]
     C --> D{决策}
     D -->|正常| E[解码<br/>Normal]
     D -->|缓冲过多| F[加速播放<br/>Accelerate]
     D -->|缓冲不足| G[减速播放<br/>PreemptiveExpand]
     D -->|丢包| H[丢包隐藏<br/>Expand/PLC]
     D -->|静音| I[舒适噪声<br/>CNG]
     D -->|融合| J[Merge<br/>过渡平滑]
     E --> K[DSP<br/>信号处理]
     F --> K
     G --> K
     H --> K
     I --> K
     J --> K
     K --> L[音频输出<br/>10ms 帧]

架构：MCU + DSP
================

NetEQ 的架构分为两个核心部分：

MCU（Main Control Unit）
-------------------------

MCU 是 NetEQ 的"大脑"，负责决策：

1. **缓冲区管理**：维护包缓冲区，按时间戳排序
2. **延迟估计**：计算当前网络延迟和抖动
3. **目标延迟**：根据抖动估计动态调整目标缓冲深度
4. **操作决策**：每 10ms 决定执行哪种操作

决策逻辑（简化）：

.. code-block:: text

   每 10ms 播放回调：
     buffer_level = 当前缓冲区中的音频时长
     target_level = 目标缓冲深度

     if 有可用包:
       if buffer_level > target_level + 阈值:
         → Accelerate（加速播放，消耗缓冲）
       elif buffer_level < target_level - 阈值:
         → PreemptiveExpand（减速播放，积累缓冲）
       else:
         → Normal（正常解码播放）
     else:
       if 刚丢包:
         → Expand（丢包隐藏）
       elif 长时间无包:
         → CNG（舒适噪声）

DSP（Digital Signal Processor）
---------------------------------

DSP 负责执行 MCU 的决策，进行实际的信号处理：

- **Normal**：直接解码输出
- **Accelerate**：时间压缩（加速播放）
- **PreemptiveExpand**：时间拉伸（减速播放）
- **Expand**：丢包隐藏（PLC）
- **Merge**：从 Expand 恢复到 Normal 时的平滑过渡
- **CNG**：舒适噪声生成

时间拉伸算法
=============

NetEQ 的时间拉伸是其核心技术之一——在不改变音调的情况下改变播放速度。

加速（Accelerate）
-------------------

目标：缩短音频时长，降低缓冲区延迟。

算法（基于 WSOLA — Waveform Similarity Overlap-Add）：

1. 在当前帧中找到一个基音周期长度的片段
2. 搜索与该片段最相似的相邻片段（互相关）
3. 将两个片段重叠相加（overlap-add），跳过重复部分
4. 效果：每次操作缩短约一个基音周期（5-15ms）

.. code-block:: text

   原始信号:  |----A----|----B----|----C----|----D----|
   加速后:    |----A----|--B+C--|----D----|
                        ↑ 重叠相加，跳过部分 B 和 C

减速（PreemptiveExpand）
--------------------------

目标：延长音频时长，增加缓冲区深度。

算法：与加速相反——复制一个基音周期的片段并插入：

.. code-block:: text

   原始信号:  |----A----|----B----|----C----|
   减速后:    |----A----|----B----|--B'----|----C----|
                                   ↑ 复制 B 的一部分插入

关键约束：

- 只在语音段（voiced）执行，静音段不需要
- 每次操作的拉伸量不超过一个基音周期
- 需要准确的基音检测（pitch estimation）

丢包隐藏（Expand）
====================

当包丢失时，NetEQ 需要生成替代音频来填补空白。

语音段 PLC
-----------

对于语音信号（浊音），利用语音的准周期性：

1. **基音检测**：从最近的正常帧中估计基音周期
2. **外推**：用基音周期重复最近的语音波形
3. **随机化**：对外推信号加入少量随机扰动，避免机械感
4. **衰减**：随着丢包持续，逐渐衰减信号幅度

.. code-block:: text

   正常帧:  |~~~~∿~~~~∿~~~~∿~~~~|
   丢包帧:  |~~~~∿~~~~∿~~~~∿~~~~|  ← 基于基音周期外推
   继续丢:  |~~~∿~~~∿~~~∿~~~|      ← 幅度衰减
   继续丢:  |~~∿~~∿~~|              ← 继续衰减
   继续丢:  |~noise~|               ← 退化为噪声

噪声段 PLC
-----------

对于噪声/静音信号，生成与之前噪声特性匹配的随机信号：

1. 估计噪声的频谱包络（LPC 分析）
2. 用白噪声激励 LPC 滤波器
3. 匹配能量级别

Merge 操作
-----------

从 Expand（PLC）恢复到 Normal 时，需要平滑过渡：

.. code-block:: text

   Expand 输出:  |~~~~∿~~~~∿~~~~|
   Normal 解码:                    |----正常音频----|
   Merge 过渡:   |~~~~∿~~~~∿~--过渡--正常音频----|
                              ↑ 交叉淡入淡出

Merge 使用互相关找到最佳拼接点，然后用交叉淡入淡出（crossfade）平滑过渡。

延迟控制
========

目标延迟计算
-------------

NetEQ 的目标延迟基于网络抖动的统计分布：

.. code-block:: text

   target_level = f(jitter_histogram)

   NetEQ 维护一个抖动直方图（histogram），
   记录最近 N 个包的到达时间偏差分布。

   目标延迟 = 直方图的第 P 百分位值
   P 通常取 95-97%，即覆盖 95-97% 的抖动

   例如：
   - 95% 的包在 50ms 内到达 → 目标延迟 = 50ms
   - 网络改善，95% 在 30ms 内 → 目标延迟降至 30ms

延迟调整速度
-------------

目标延迟的调整不是瞬时的：

- **增加延迟**：快速响应（网络变差时立即增加缓冲）
- **减少延迟**：缓慢收敛（网络改善后逐步降低缓冲）

这种不对称设计避免了频繁的缓冲区调整导致的音频质量波动。

源码结构
========

NetEQ 的源码位于 WebRTC 的 ``modules/audio_coding/neteq/`` 目录：

.. code-block:: text

   neteq/
   ├── neteq_impl.cc              # NetEQ 主实现
   ├── decision_logic.cc          # MCU 决策逻辑
   ├── buffer_level_filter.cc     # 缓冲区水位滤波
   ├── delay_manager.cc           # 延迟管理器
   ├── delay_peak_detector.cc     # 延迟峰值检测
   ├── packet_buffer.cc           # 包缓冲区
   ├── accelerate.cc              # 加速播放
   ├── preemptive_expand.cc       # 减速播放
   ├── expand.cc                  # 丢包隐藏
   ├── merge.cc                   # 过渡融合
   ├── comfort_noise.cc           # 舒适噪声
   ├── normal.cc                  # 正常播放
   ├── time_stretch.cc            # 时间拉伸基类
   ├── dsp_helper.cc              # DSP 工具函数
   └── statistics_calculator.cc   # 统计计算

性能指标
========

NetEQ 的效果可以通过以下指标评估：

.. list-table::
   :header-rows: 1
   :widths: 30 30 40

   * - 指标
     - 含义
     - 理想值
   * - Concealment Rate
     - PLC 帧占比
     - < 2%
   * - Accelerate Rate
     - 加速帧占比
     - < 5%
   * - PreemptiveExpand Rate
     - 减速帧占比
     - < 5%
   * - Average Buffer Delay
     - 平均缓冲延迟
     - 20-80 ms
   * - Buffer Underrun Rate
     - 缓冲区欠载率
     - < 0.1%

这些指标可以通过 WebRTC 的 ``getStats()`` API 获取。

小结
====

NetEQ 是 WebRTC 音频质量的幕后英雄。它的设计体现了实时通信中"延迟 vs 质量"权衡的精髓：

- 用自适应缓冲吸收抖动，但不过度增加延迟
- 用时间拉伸无感知地调整缓冲深度
- 用高质量 PLC 掩盖丢包
- 用平滑过渡避免听感突变

理解 NetEQ 的工作原理，对于排查音频质量问题（卡顿、延迟大、机器音）非常有帮助。
