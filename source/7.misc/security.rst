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

The user access need
* Authentication
* Authorization
* Audit


Simple Authentication and Security Layer
=============================================
Simple Authentication and Security Layer (SASL) is a framework for authentication and data security in Internet protocols. It decouples authentication mechanisms from application protocols, in theory allowing any authentication mechanism supported by SASL to be used in any application protocol that uses SASL.

Authentication mechanisms can also support proxy authorization, a facility allowing one user to assume the identity of another. They can also provide a data security layer offering data integrity and data confidentiality services. DIGEST-MD5 provides an example of mechanisms which can provide a data-security layer. Application protocols that support SASL typically also support Transport Layer Security (TLS) to complement the services offered by SASL.


Security Check list
===================================



Glossary
==============
* SASL: Simple Authentication and Security Layer




Kerberos
==============
Kerberos (/ˈkɜːrbərɒs/) is a computer-network authentication protocol that works on the basis of tickets to allow nodes communicating over a non-secure network to prove their identity to one another in a secure manner. The protocol was named after the character Kerberos (or Cerberus) from Greek mythology, the ferocious three-headed guard dog of Hades. Its designers aimed it primarily at a client–server model, and it provides mutual authentication—both the user and the server verify each other's identity. Kerberos protocol messages are protected against eavesdropping and replay attacks.

Kerberos builds on symmetric-key cryptography and requires a trusted third party, and optionally may use public-key cryptography during certain phases of authentication.[2] Kerberos uses UDP port 88 by default.



Reference
==============
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
