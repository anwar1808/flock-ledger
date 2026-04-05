import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../models/ai_thread.dart';
import '../../models/ai_message.dart';
import '../../providers/ai_chat_provider.dart';
import '../../services/quota_service.dart';
import '../settings/settings_screen.dart';

class ThreadScreen extends StatefulWidget {
  final AiThread thread;
  final String flockContext;

  const ThreadScreen({
    super.key,
    required this.thread,
    required this.flockContext,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _atLimit = false;

  @override
  void initState() {
    super.initState();
    context.read<AiChatProvider>().loadMessages(widget.thread.id);
    _checkQuota();
  }

  Future<void> _checkQuota() async {
    final at = await QuotaService.instance.isAtLimit();
    if (mounted) setState(() => _atLimit = at);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await context.read<AiChatProvider>().sendMessage(
          widget.thread.id,
          text,
          flockContext: widget.flockContext,
        );
    await _checkQuota();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    final messages = provider.messagesFor(widget.thread.id);

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AiChatProvider>(
          builder: (_, p, __) {
            final thread =
                p.threads.firstWhere((t) => t.id == widget.thread.id,
                    orElse: () => widget.thread);
            return Text(
              thread.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Error banner
          if (provider.error != null)
            _ErrorBanner(
              message: provider.error!,
              isAuth: provider.errorIsAuth,
              onDismiss: () => provider.clearError(),
              onSettings: provider.errorIsAuth
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      )
                  : null,
            ),

          // Messages
          Expanded(
            child: messages.isEmpty && !provider.sending
                ? _WelcomeHint()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount:
                        messages.length + (provider.sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length && provider.sending) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: messages[i]);
                    },
                  ),
          ),

          // Input row
          _InputBar(
            controller: _inputController,
            sending: provider.sending,
            disabled: _atLimit && !kDevMode,
            onSend: _send,
            onDevReset: kDevMode
                ? () async {
                    await QuotaService.instance.devReset();
                    await _checkQuota();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Quota reset (dev mode)')),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF5D8A3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 14, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF5D8A3C)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        em: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        listBullet: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade400,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: const BoxDecoration(
              color: Color(0xFF5D8A3C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                size: 14, color: Colors.white),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = (i / 3);
                    final val = ((_controller.value + offset) % 1.0);
                    final opacity = val < 0.5
                        ? val * 2
                        : (1.0 - val) * 2;
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade500
                            .withValues(alpha: 0.3 + opacity * 0.7),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool disabled;
  final VoidCallback onSend;
  final VoidCallback? onDevReset;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.disabled,
    required this.onSend,
    this.onDevReset,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (disabled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.block,
                      size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monthly limit reached — resets next month.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800),
                    ),
                  ),
                  if (onDevReset != null)
                    TextButton(
                      onPressed: onDevReset,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Dev reset',
                          style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !disabled && !sending,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: disabled
                          ? 'Monthly limit reached'
                          : 'Ask about your flock…',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFF5D8A3C)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      if (!disabled && !sending) onSend();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: sending
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5D8A3C),
                            ),
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('send'),
                          onPressed:
                              disabled ? null : onSend,
                          icon: const Icon(Icons.send_rounded),
                          color: const Color(0xFF5D8A3C),
                          disabledColor: Colors.grey.shade300,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome hint ─────────────────────────────────────────────────────────────

class _WelcomeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Ask me anything about your flock',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _SuggestionChip('Why is my hen not laying?'),
                _SuggestionChip('Signs of coccidiosis'),
                _SuggestionChip('Best feed for meat birds'),
                _SuggestionChip('When to candle eggs?'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Find the input controller via the parent state — simpler to just
        // copy text to clipboard; tapping a chip fills the input field.
        // We do this by finding the nearest ThreadScreen state.
        final state = context
            .findAncestorStateOfType<_ThreadScreenState>();
        state?._inputController.text = text;
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF5D8A3C).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF5D8A3C).withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF5D8A3C)),
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isAuth;
  final VoidCallback onDismiss;
  final VoidCallback? onSettings;

  const _ErrorBanner({
    required this.message,
    required this.isAuth,
    required this.onDismiss,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer)),
                if (isAuth && onSettings != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onSettings,
                    child: Text(
                      'Go to Settings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color:
                Theme.of(context).colorScheme.onErrorContainer,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
