##########
lal
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** lal
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==============
A strict, language-agnostic build system and dependency manager.

* Use existing tools: lal build only shells out to an executable BUILD script in a configured docker container. Install what you want in your build environments: cmake, autotools, cargo, go, python.
* Cache large builds: publish built libraries for later use down the dependency tree.
* Strict with environments and versions: lal verify enforces that all your dependencies are built in the same environment and use the same version down the tree (and it runs before your build).
* Builds on existing package manager ideas: versions in a manifest, fetch dependencies first, verify them, then build however you want, lal autogenerates lockfiles during build.
* Transparent use of docker for build environments with configurable mounts and direct view of the docker run commands used. lal shell or lal script provides additional easy ways to use the build environments.


Reference
==============
* https://github.com/cisco/lal-build-manager
* https://developer.cisco.com/codeexchange/github/repo/cisco/lal-build-manager