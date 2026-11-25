import 'package:flutter/material.dart';

import 'package:watchiot/core/app_theme.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Xin chào! Mình có thể giúp bạn tìm hiểu cách sử dụng ứng dụng và đọc trạng thái đồng hồ.',
      fromUser: false,
    ),
  ];

  static const _suggestions = [
    'Vì sao chưa có chỉ số?',
    'Xử lý cảnh báo té ngã',
    'SpO₂ có ý nghĩa gì?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? suggestion]) {
    final question = (suggestion ?? _controller.text).trim();
    if (question.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: question, fromUser: true));
      _messages.add(_ChatMessage(text: _answer(question), fromUser: false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _answer(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('chỉ số') || normalized.contains('dữ liệu')) {
      return 'Đặt ngón tay lên cảm biến MAX30102 để đo. Nếu vẫn chưa thấy số liệu, kiểm tra đồng hồ đang gửi dữ liệu và tài khoản có quyền đọc RTDB.';
    }
    if (normalized.contains('té ngã') || normalized.contains('cảnh báo')) {
      return 'Khi có cảnh báo, kiểm tra người đeo ngay. Nếu là cảnh báo nhầm, dùng nút xác nhận an toàn; nếu có dấu hiệu nguy hiểm, gọi người thân hoặc cấp cứu.';
    }
    if (normalized.contains('spo') || normalized.contains('oxy')) {
      return 'SpO₂ là tỷ lệ oxy trong máu do cảm biến gửi lên. Ứng dụng chỉ hiển thị số đo tham khảo, không dùng để tự chẩn đoán.';
    }
    return 'Trợ lý hiện cung cấp hướng dẫn nhanh trong ứng dụng và chưa kết nối mô hình AI. Bạn có thể chọn một gợi ý bên dưới để xem hướng dẫn.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChatHeader(onClose: widget.onClose),
            const SizedBox(height: 14),
            Expanded(
              child: _messages.length == 1
                  ? ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        _MessageBubble(message: _messages.first),
                        const SizedBox(height: 10),
                        const Text(
                          'Câu hỏi gợi ý',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final suggestion in _suggestions)
                          _SuggestedQuestion(
                            text: suggestion,
                            onTap: () => _send(suggestion),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trợ lý hiện trả lời câu hỏi thường gặp trong app; chưa kết nối dịch vụ AI.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: _messages[index]),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(13, 5, 6, 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        filled: false,
                        hintText: 'Nhập câu hỏi...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _send,
                    tooltip: 'Gửi',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentSoft,
                      foregroundColor: AppColors.warning,
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            const Center(
              child: Text(
                'Hướng dẫn tham khảo · Chưa kết nối dịch vụ AI',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: AppColors.warning,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trợ lý sức khỏe',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 3),
              const Text(
                'Hướng dẫn nhanh trong ứng dụng',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'HỖ TRỢ',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 6),
          IconButton(
            onPressed: onClose,
            tooltip: 'Đóng Chatbot',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.outline),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}

class _SuggestedQuestion extends StatelessWidget {
  const _SuggestedQuestion({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.warning,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.accent.withValues(alpha: 0.25)
                : AppColors.outline,
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}
