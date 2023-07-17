##############################
WebRTC SCTP library
##############################

.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** WebRTC SCTP library
**Authors**  Walter Fan
**Category** LearningNote
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
=============
WebRTC 的 data channel 使用了 SCTP 协议, 提供数据传输通道, 为安全起见, 其 SCTP 依赖 DTLS 进行安全加密传输。

SCTP 是一种面向消息的可靠传输协议, 直接支持在 IP 或 UDP 之上运行的多宿主, 并支持 v4 和 v6 版本。

与 TCP 一样, SCTP 提供可靠的、面向连接的数据传输和拥塞控制。 与 TCP 不同, SCTP 还提供消息边界保存、有序和无序消息传递、多流和多宿主。 通过使用校验和和序列号来检测数据损坏、数据丢失和数据重复。 应用选择性重传机制来纠正数据的丢失或损坏。


SCTP 相关的协议和扩展很多, 最主要的有两个

* `RFC6458`_: Sockets API Extensions for the Stream Control Transmission Protocol (SCTP)

* `RFC4960`_: Stream Control Transmission Protocol



起先, WebRTC 使用了开源的 `usrsctp <https://github.com/sctplab/usrsctp>`_, 后期改成了自己实现的 `dcsctp <https://bugs.chromium.org/p/webrtc/issues/detail?id=12614>`_

.. pull-quote::

   Starting with Chrome M95 for the Canary and Dev channels, we’re going to start to rollout the DcSCTP library for the SCTP transport used by WebRTC’s Data Channels.

   It is a new implementation with a focus on security and compatibility with the previous implementation. No action should be required on your part and the transition should be transparent for users. Please have a look at the previous PSA for more information.


   To force enable the feature in Chrome, use the command line flag --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Enabled/“, and --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Disabled/" to force disable it and revert to the previous implementation.

   -- Florent Castelli


   WebRTC is starting to experiment with a new SCTP implementation called dcSCTP with the goal to migrate from usrsctp in the second half of this year.

   The new implementation is an in-tree C++ implementation that is consistent with all other code in WebRTC. It’s designed to only implement the parts of SCTP that are used by Data Channels in WebRTC and with security as the highest priority.

   By having a small, modern and well integrated SCTP implementation, it will be possible to provide a better experience for both media and data, more quickly iterate and experiment with new features and provide a better security architecture with much less cost of maintenance compared to the current setup.

   In the initial release, the library is considered to be feature complete with some known limitations:

   The congestion control algorithm hasn’t been fully tuned, so performance may be slightly worse compared to usrsctp, but should generally be on par.

   No support for I-DATA (RFC8260). This has never been enabled in Chromium/Chrome for usrsctp and this is negotiated in the SCTP association setup.

   Both will be fixed in future releases.

   The library is located in //net/dcsctp and is used by the SCTP Transport at //media/sctp/dcsctp_transport.h, but please note that API stability is not yet guaranteed.

   It is also available in Chrome using the feature flag --force-fieldtrials="WebRTC-DataChannel-Dcsctp/Enabled/" in Chrome Canary from version 92.0.4502.0.

   We appreciate any bug reports to be filed at bugs.webrtc.org (DataChannel component) for the dcSCTP library and its transport, and at crbug.com (Blink>WebRTC>DataChannel) for bugs visible through the Chrome/Chromium JS API.

   We would like to thank Michael Tüxen for all his past and current support for the usrsctp library, which has been a core component for WebRTC. We would not be the platform we are today without all of Michael's efforts.


相关代码
================
* DcSctpTransport
* DcSctpSocketInterface
  - DcSctpSocket (`dcsctp_socket.cc`_)

.. _dcsctp_socket.cc: https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/net/dcsctp/socket/dcsctp_socket.cc


https://source.chromium.org/chromium/chromium/src/+/main:third_party/webrtc/net/dcsctp/socket/



可以从 WebRTC 源码中单独编译出 libdcsctp, 方法是在 BUILD.gn 中添加如下这段

.. code-block::

   rtc_static_library("dcsctp") {
      visibility = [
         "//:default",
      ]
      sources = []
      complete_static_lib = true
      suppressed_configs += [ "//build/config/compiler:thin_archive" ]
      deps = [
         "rtc_base",
         "net/dcsctp/public:socket",
         "net/dcsctp/public:types",
         "net/dcsctp/public:factory",
         "net/dcsctp/socket:dcsctp_socket",
         "net/dcsctp/timer:task_queue_timeout",
      ]
   }


core class
-------------------------

.. code-block::


   // Represents an immutable (received or to-be-sent) SCTP packet.
   class SctpPacket {
   public:
      static constexpr size_t kHeaderSize = 12;

      struct ChunkDescriptor {
         ChunkDescriptor(uint8_t type,
                        uint8_t flags,
                        rtc::ArrayView<const uint8_t> data)
            : type(type), flags(flags), data(data) {}
         uint8_t type;
         uint8_t flags;
         rtc::ArrayView<const uint8_t> data;
      };

      SctpPacket(SctpPacket&& other) = default;
      SctpPacket& operator=(SctpPacket&& other) = default;
      SctpPacket(const SctpPacket&) = delete;
      SctpPacket& operator=(const SctpPacket&) = delete;

      // Used for building SctpPacket, as those are immutable.
      class Builder {
         public:
         Builder(VerificationTag verification_tag, const DcSctpOptions& options);

         Builder(Builder&& other) = default;
         Builder& operator=(Builder&& other) = default;

         // Adds a chunk to the to-be-built SCTP packet.
         Builder& Add(const Chunk& chunk);

         // The number of bytes remaining in the packet for chunk storage until the
         // packet reaches its maximum size.
         size_t bytes_remaining() const;

         // Indicates if any packets have been added to the builder.
         bool empty() const { return out_.empty(); }

         // Returns the payload of the build SCTP packet. The Builder will be cleared
         // after having called this function, and can be used to build a new packet.
         std::vector<uint8_t> Build();

         private:
         VerificationTag verification_tag_;
         uint16_t source_port_;
         uint16_t dest_port_;
         // The maximum packet size is always even divisible by four, as chunks are
         // always padded to a size even divisible by four.
         size_t max_packet_size_;
         std::vector<uint8_t> out_;
      };

      // Parses `data` as an SCTP packet and returns it if it validates.
      static absl::optional<SctpPacket> Parse(
            rtc::ArrayView<const uint8_t> data,
            bool disable_checksum_verification = false);

      // Returns the SCTP common header.
      const CommonHeader& common_header() const { return common_header_; }

      // Returns the chunks (types and offsets) within the packet.
      rtc::ArrayView<const ChunkDescriptor> descriptors() const {
         return descriptors_;
      }

      private:
      SctpPacket(const CommonHeader& common_header,
                  std::vector<uint8_t> data,
                  std::vector<ChunkDescriptor> descriptors)
            : common_header_(common_header),
            data_(std::move(data)),
            descriptors_(std::move(descriptors)) {}

      CommonHeader common_header_;

      // As the `descriptors_` refer to offset within data, and since SctpPacket is
      // movable, `data` needs to be pointer stable, which it is according to
      // http://www.open-std.org/JTC1/SC22/WG21/docs/lwg-active.html#2321
      std::vector<uint8_t> data_;
      // The chunks and their offsets within `data_ `.
      std::vector<ChunkDescriptor> descriptors_;
   };

snippets
-------------------------

.. code-block:: cpp

   RTCError SdpOfferAnswerHandler::PushdownMediaDescription(
      SdpType type,
      cricket::ContentSource source,
      const std::map<std::string, const cricket::ContentGroup*>&
         bundle_groups_by_mid) {


      //...

      // Need complete offer/answer with an SCTP m= section before starting SCTP,
         // according to https://tools.ietf.org/html/draft-ietf-mmusic-sctp-sdp-19
      if (pc_->sctp_mid() && local_description() && remote_description()) {
         auto local_sctp_description = cricket::GetFirstSctpDataContentDescription(
            local_description()->description());
         auto remote_sctp_description = cricket::GetFirstSctpDataContentDescription(
            remote_description()->description());
         if (local_sctp_description && remote_sctp_description) {
            int max_message_size;
            // A remote max message size of zero means "any size supported".
            // We configure the connection with our own max message size.
            if (remote_sctp_description->max_message_size() == 0) {
            max_message_size = local_sctp_description->max_message_size();
            } else {
            max_message_size =
                  std::min(local_sctp_description->max_message_size(),
                           remote_sctp_description->max_message_size());
            }
            pc_->StartSctpTransport(local_sctp_description->port(),
                                    remote_sctp_description->port(),
                                    max_message_size);
         }
      }
      //...
   }


* snippets

.. code-block::


   void SctpTransport::Start(int local_port,
                          int remote_port,
                          int max_message_size) {
      RTC_DCHECK_RUN_ON(owner_thread_);
      info_ = SctpTransportInformation(info_.state(), info_.dtls_transport(),
                                       max_message_size, info_.MaxChannels());

      if (!internal()->Start(local_port, remote_port, max_message_size)) {
         RTC_LOG(LS_ERROR) << "Failed to push down SCTP parameters, closing.";
         UpdateInformation(SctpTransportState::kClosed);
      }
   }


* snippet 3

   ./media/sctp/dcsctp_transport.h

.. code-block::

   // This is the default SCTP port to use. It is passed along the wire and the
   // connectee and connector must be using the same port. It is not related to the
   // ports at the IP level. (Corresponds to: sockaddr_conn.sconn_port in
   // usrsctp.h)
   const int kSctpDefaultPort = 5000;


   class DcSctpTransport : public cricket::SctpTransportInternal


   bool DcSctpTransport::Start(int local_sctp_port,
                            int remote_sctp_port,
                            int max_message_size) {
      RTC_DCHECK_RUN_ON(network_thread_);
      RTC_DCHECK(max_message_size > 0);

      RTC_LOG(LS_INFO) << debug_name_ << "->Start(local=" << local_sctp_port
                        << ", remote=" << remote_sctp_port
                        << ", max_message_size=" << max_message_size << ")";

      if (!socket_) {
         dcsctp::DcSctpOptions options;
         options.local_port = local_sctp_port;
         options.remote_port = remote_sctp_port;
         options.max_message_size = max_message_size;
         options.max_timer_backoff_duration = kMaxTimerBackoffDuration;
         // Don't close the connection automatically on too many retransmissions.
         options.max_retransmissions = absl::nullopt;
         options.max_init_retransmits = absl::nullopt;

         std::unique_ptr<dcsctp::PacketObserver> packet_observer;
         if (RTC_LOG_CHECK_LEVEL(LS_VERBOSE)) {
            packet_observer =
               std::make_unique<dcsctp::TextPcapPacketObserver>(debug_name_);
         }

         dcsctp::DcSctpSocketFactory factory;
         socket_ =
            factory.Create(debug_name_, *this, std::move(packet_observer), options);
      } else {
         if (local_sctp_port != socket_->options().local_port ||
            remote_sctp_port != socket_->options().remote_port) {
            RTC_LOG(LS_ERROR)
               << debug_name_ << "->Start(local=" << local_sctp_port
               << ", remote=" << remote_sctp_port
               << "): Can't change ports on already started transport.";
            return false;
         }
         socket_->SetMaxMessageSize(max_message_size);
      }

      MaybeConnectSocket();

      return true;
   }


* DcSctpSocket::Connect

.. code-block::


   void DcSctpSocket::Connect() {
      RTC_DCHECK_RUN_ON(&thread_checker_);
      CallbackDeferrer::ScopedDeferrer deferrer(callbacks_);

      if (state_ == State::kClosed) {
         MakeConnectionParameters();
         RTC_DLOG(LS_INFO)
            << log_prefix()
            << rtc::StringFormat(
                     "Connecting. my_verification_tag=%08x, my_initial_tsn=%u",
                     *connect_params_.verification_tag, *connect_params_.initial_tsn);
         SendInit();
         t1_init_->Start();
         SetState(State::kCookieWait, "Connect called");
      } else {
         RTC_DLOG(LS_WARNING) << log_prefix()
                              << "Called Connect on a socket that is not closed";
      }
      RTC_DCHECK(IsConsistent());
   }
