#################
Security
#################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC Security
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==============

WebRTC security is based on TLS/DTLS and SRTP. The key management is also important.

三个基本需求
* Authentication 用户访问需要认证
* Authorization 用户访问需要授权
* Audit 用户的访问应该可被追踪和审查


其中前两项也可以归结为 CIA

1. Confidentiality 机密性：信息需要保密， 访问权限也需要控制
2. Integrity 完整性：信息需要保持完整，在存储和传输过程不被未授权，未预期或无意地篡改或销毁，或者可以快速检测到被篡改
3. Availablity 可用性： 信息可被合法用户访问并向其提供所需的功能和特性，例如拒绝服务攻击就是对可用性的破坏


保护的对象有
1. 保护网络和基础设施： 如主干，有线和无线网络的可用性， 采用 VPN
2. 保护访问的边界：如登录保护，远程访问控制，多级安全
3. 保护计算环境：如终端用户环境，系统应用程序
4. 支撑基础设施：如密钥管理 KMI 和公钥基础设施 PKI, 进行检测与响应


安全防护的基本方法：
1. 检测，分析与评价安全错误与漏洞，采取措施进行修复和风险控制，如打补丁，防病毒，防火墙，入侵检测和应急响应
2. 将安全保护


Simple Authentication and Security Layer
=============================================
Simple Authentication and Security Layer (SASL) is a framework for authentication and data security in Internet protocols. It decouples authentication mechanisms from application protocols, in theory allowing any authentication mechanism supported by SASL to be used in any application protocol that uses SASL.

Authentication mechanisms can also support proxy authorization, a facility allowing one user to assume the identity of another. They can also provide a data security layer offering data integrity and data confidentiality services. DIGEST-MD5 provides an example of mechanisms which can provide a data-security layer. Application protocols that support SASL typically also support Transport Layer Security (TLS) to complement the services offered by SASL.


Security Check list
===================================
#. 原则：未雨绸缪，亡羊补牢

#. 分析方法：

   - 要保护的对象
   - 分析其价值，弱点，威胁
   - 制定对策
   - 降低风险

* 安全对策 PDRRP

  - Protect 保护： 层层设防
  - Detect 检测： 实时，动态
  - React 反应：迅速，连锁
  - Restore 恢复： 及时，升级
  - Punish 处罚：准确，有力，适当



Glossary
==============
* SASL: Simple Authentication and Security Layer




Kerberos
==============
Kerberos (/ˈkɜːrbərɒs/) is a computer-network authentication protocol that works on the basis of tickets to allow nodes communicating over a non-secure network to prove their identity to one another in a secure manner. The protocol was named after the character Kerberos (or Cerberus) from Greek mythology, the ferocious three-headed guard dog of Hades. Its designers aimed it primarily at a client–server model, and it provides mutual authentication—both the user and the server verify each other's identity. Kerberos protocol messages are protected against eavesdropping and replay attacks.

Kerberos builds on symmetric-key cryptography and requires a trusted third party, and optionally may use public-key cryptography during certain phases of authentication.[2] Kerberos uses UDP port 88 by default.



Reference
==============
* https://wiki.owasp.org/index.php/Security_by_Design_Principles
* https://en.wikipedia.org/wiki/Kerberos_(protocol)
* https://web.mit.edu/kerberos/
* https://webrtc-security.github.io/

* `OWASP Security Design Principles <https://wiki.owasp.org/index.php/Security_by_Design_Principles>`_
* `Secure Software Development <https://www.pluralsight.com/courses/software-development-secure>`_
* `Kubernetes Security Best Practices <https://blog.sqreen.com/kubernetes-security-best-practices/>`_
* `SEI CERT Secure C++ Coding Practices <https://resources.sei.cmu.edu/downloads/secure-coding/assets/sei-cert-cpp-coding-standard-2016-v01.pdf>`_
* `Secure Coding in Java <https://app.pluralsight.com/library/courses/defensive-programming-java/table-of-contents>`_
* `Ethical Hacking: Buffer Overflow <https://app.pluralsight.com/library/courses/ethical-hacking-buffer-overflow/table-of-contents>`_
* `C++ Secure Coding Practices Const Correctness <https://app.pluralsight.com/library/courses/modern-c-plus-plus-secure-coding-practices-const-correctness/table-of-contents>`_
