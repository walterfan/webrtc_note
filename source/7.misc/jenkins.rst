###################
Jenkins
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Jenkins
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

简介
=====================

Jenkins 是最流行的开源 CI/CD 自动化服务器，在 WebRTC 项目中可用于自动化构建、测试和部署。
WebRTC 项目的构建过程复杂且耗时，通过 Jenkins Pipeline 可以实现全自动化的持续集成流程。


Pipeline 配置
=====================

Jenkins Pipeline 使用 Groovy DSL 定义构建流程，支持 Declarative 和 Scripted 两种语法。
以下是一个 WebRTC 项目的典型 Pipeline 配置：

.. code-block:: groovy

   // Jenkinsfile - WebRTC 项目 CI Pipeline
   pipeline {
     agent {
       label 'webrtc-builder'
     }

     environment {
       DEPOT_TOOLS = "${WORKSPACE}/depot_tools"
       PATH = "${DEPOT_TOOLS}:${PATH}"
     }

     options {
       timeout(time: 2, unit: 'HOURS')
       timestamps()
       buildDiscarder(logRotator(numToKeepStr: '10'))
     }

     stages {
       stage('Checkout') {
         steps {
           sh 'git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git'
           sh 'fetch --nohooks webrtc'
           sh 'gclient sync'
         }
       }

       stage('Build') {
         parallel {
           stage('Debug') {
             steps {
               sh 'gn gen out/Debug --args="is_debug=true"'
               sh 'ninja -C out/Debug'
             }
           }
           stage('Release') {
             steps {
               sh 'gn gen out/Release --args="is_debug=false is_component_build=false"'
               sh 'ninja -C out/Release'
             }
           }
         }
       }

       stage('Unit Test') {
         steps {
           sh './out/Release/rtc_unittests --gtest_output=xml:test_results.xml'
           sh './out/Release/modules_unittests --gtest_output=xml:modules_results.xml'
         }
         post {
           always {
             junit '*.xml'
           }
         }
       }

       stage('Archive') {
         steps {
           archiveArtifacts artifacts: 'out/Release/libwebrtc.a', fingerprint: true
         }
       }
     }

     post {
       failure {
         mail to: 'team@example.com',
              subject: "WebRTC Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
              body: "Check: ${env.BUILD_URL}"
       }
     }
   }


WebRTC 构建自动化
=====================

WebRTC 使用 Google 的 ``depot_tools`` 工具链，构建系统为 GN + Ninja。
在 Jenkins 中自动化构建需要注意以下要点：

构建环境准备
--------------

.. code-block:: bash

   # 安装构建依赖 (Ubuntu)
   sudo apt-get install -y build-essential git python3 pkg-config
   # WebRTC 自带的依赖安装脚本
   ./build/install-build-deps.sh

   # GN 构建参数示例
   gn gen out/Default --args='
     target_os="linux"
     target_cpu="x64"
     is_debug=false
     rtc_include_tests=true
     rtc_use_h264=true
     use_rtti=true
   '

多平台构建
--------------

WebRTC 支持多平台，Jenkins 可以通过 Matrix 构建实现：

.. code-block:: groovy

   matrix {
     axes {
       axis {
         name 'PLATFORM'
         values 'linux', 'mac', 'windows', 'android', 'ios'
       }
     }
     stages {
       stage('Build') {
         agent { label "${PLATFORM}-builder" }
         steps {
           sh "gn gen out/${PLATFORM} --args='target_os=\"${PLATFORM}\"'"
           sh "ninja -C out/${PLATFORM}"
         }
       }
     }
   }


测试集成
=====================

WebRTC 项目包含多种测试类型，都可以集成到 Jenkins Pipeline 中：

单元测试
-----------

.. code-block:: bash

   # 主要的测试目标
   ./out/Release/rtc_unittests           # RTC 核心单元测试
   ./out/Release/modules_unittests       # 模块单元测试
   ./out/Release/video_engine_tests      # 视频引擎测试
   ./out/Release/audio_decoder_unittests # 音频解码器测试

集成测试
-----------

.. code-block:: bash

   # 端到端音视频质量测试
   ./out/Release/video_quality_loopback_test
   ./out/Release/audio_quality_loopback_test

   # 网络模拟测试 (使用 tc 模拟丢包、延迟)
   ./out/Release/webrtc_perf_tests

测试报告
-----------

Jenkins 可以通过插件展示测试结果：

* **JUnit Plugin**: 解析 GTest 输出的 XML 报告
* **HTML Publisher**: 展示代码覆盖率报告
* **Performance Plugin**: 跟踪性能测试指标的趋势

.. code-block:: groovy

   post {
     always {
       junit 'out/Release/test_results/*.xml'
       publishHTML(target: [
         reportDir: 'out/Release/coverage',
         reportFiles: 'index.html',
         reportName: 'Code Coverage'
       ])
     }
   }


常用 Jenkins 插件
=====================

* **Pipeline**: 核心 Pipeline 支持
* **Git**: Git 源码管理
* **Docker Pipeline**: 在 Docker 容器中构建
* **Slack Notification**: 构建结果通知
* **Artifactory**: 构建产物管理
* **Blue Ocean**: 现代化的 Pipeline 可视化界面


参考资料
=====================
* Jenkins 官方文档: https://www.jenkins.io/doc/
* WebRTC 构建指南: https://webrtc.googlesource.com/src/+/main/docs/native-code/development/
