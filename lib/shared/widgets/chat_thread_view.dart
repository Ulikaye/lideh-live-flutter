import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';

/// Shared rendering for both sides of a conversation — the
/// musician/organizer's own thread screen, and the admin's view of
/// any thread. Keeping this in one widget means bubble styling and
/// send behavior can't drift between the two screens over time.
class ChatThreadView extends StatefulWidget {
  final List<ChatMessage> messages;
  final String myRole; // 'admin' or 'user'
  final Future<void> Function(String text) onSend;
  final void Function(ChatMessage message)? onToggleLike; // admin-only, null hides the affordance entirely

  const ChatThreadView({
    super.key,
    required this.messages,
    required this.myRole,
    required this.onSend,
    this.onToggleLike,
  });

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
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
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await widget.onSend(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No messages yet — say hello!', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: widget.messages[i],
                    isMine: widget.messages[i].senderRole == widget.myRole,
                    onToggleLike: widget.onToggleLike,
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final void Function(ChatMessage message)? onToggleLike;

  const _Bubble({required this.message, required this.isMine, this.onToggleLike});

  @override
  Widget build(BuildContext context) {
    // The like affordance only ever makes sense on the *other*
    // person's message from the viewer's perspective — an admin can
    // like a user's message, never their own reply.
    final showLike = onToggleLike != null && !isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine ? null : Border.all(color: AppColors.border),
            ),
            child: Text(message.text, style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.createdAt != null)
                Text(DateFormat('MMM d, h:mm a').format(message.createdAt!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              if (message.liked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.favorite_rounded, size: 12, color: AppColors.danger),
              ],
              if (showLike)
                InkWell(
                  onTap: () => onToggleLike!(message),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      message.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: message.liked ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
