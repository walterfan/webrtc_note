:orphan:

############
傅立叶变换
############

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** DSP
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:



傅立叶变换 FT
================

傅立叶变换是指以时间为自变量的信号和以频率为自变量的频谱函数之间的某种变换关系。

连续傅立叶变换 FT

离散傅立叶变换 DFT

快速傅立叶变换 FFT
--------------------------------

快速傅里叶变换 (fast Fourier transform),即利用计算机计算离散傅里叶变换（DFT)的高效、快速计算方法的统称，简称FFT。快速傅里叶变换是1965年由J.W.库利和T.W.图基提出的。采用这种算法能使计算机计算离散傅里叶变换所需要的乘法次数大为减少，特别是被变换的抽样点数N越多，FFT算法计算量的节省就越显著。

FFT 是根据离散傅氏变换的奇、偶、虚、实等特性，对离散傅立叶变换的算法进行改进获得的。它是针对一个数组的运算，数组的长度 N 通常是 2 的整数次幂，例如 64， 128， 256 等，数值可以是实数或复数，通常的时域信号都是实数，以实数为例，

离散余弦变换 DCT
===============================

离散余弦变换 (Discrete Cosine Transform)本质上也是离散傅里叶变换 (Discrete Fourier Transform)，但是只有实数部分。 有这样一个性质：如果信号 在给定区间内满足狄利赫里条件，且为实对称函数，则可以展开成仅含有余弦项的傅里叶级数，即离散余弦变换。


参考资料
===============================

* `傅里叶变换、拉普拉斯变换、Z 变换的联系是什么？`_
* `傅里叶变换推导详解`_
* `离散傅里叶变换DFT详解及应用`_


.. _傅里叶变换、拉普拉斯变换、Z 变换的联系是什么？:  https://www.zhihu.com/question/22085329/answer/774074211
.. _傅里叶变换推导详解: https://zhuanlan.zhihu.com/p/77345128
.. _离散傅里叶变换DFT详解及应用: https://zhuanlan.zhihu.com/p/77347644