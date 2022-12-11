##########
selenium
##########


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** selenium
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
==============


.. code-block::


    FROM selenium/standalone-chrome-debug:3.141.59-20210607

    #copy local video to container
    COPY ./video/reference_video_640x360_30fps.y4m /home/seluser