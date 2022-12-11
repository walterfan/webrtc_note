##########
Fuzzer
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Fuzzer
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:


Overview
================

To operate correctly, the fuzzer requires one or more starting file that contains a good example of the input data normally expected by the targeted application. There are two basic rules:

Keep the files small. Under 1 kB is ideal, although not strictly necessary.
Use multiple test cases only if they are functionally different from each other.

There is no point in using fifty different vacation photos to fuzz an image library.


Getting Started
=====================
1. Install Kitty:

.. code-block:: bash

   pip install kittyfuzzer

2. Read some of the documentation at ReadTheDocs.

3. Take a look at the examples

4. Build your very own fuzzer :-)

Reference
========================
* https://github.com/cisco-sas/kitty
* https://kitty.readthedocs.io/