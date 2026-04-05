import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/ai_chat_provider.dart';
import '../../providers/chicken_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/egg_provider.dart';
import '../../services/quota_service.dart';
import 'thread_screen.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  double _usageFraction = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<AiChatProvider>().loadThreads();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final f = await QuotaService.instance.usageFraction();
    if (mounted) setState(() => _usageFraction = f);
  }

  Future<void> _newConversation() async {
    final provider = context.read<AiChatProvider>();
    final chickenProvider = context.read<ChickenProvider>();
    final journalProvider = context.read<JournalProvider>();
    final eggProvider = context.read<EggProvider>();

    final thread = await provider.createThread();

    final chickens = chickenProvider.chickens;
    final batches = journalProvider.batches;
    final eggsLast7 = eggProvider.records
        .where((r) => r.date
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    final flockContext =
        provider.buildFlockContext(chickens, batches, eggsLast7);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ThreadScreen(
            thread: thread,
            flockContext: flockContext,
          ),
        ),
      ).then((_) {
        provider.loadThreads();
        _loadQuota();
      });
    }
  }

  void _openThread(thread) {
    final provider = context.read<AiChatProvider>();
    final chickenProvider = context.read<ChickenProvider>();
    final journalProvider = context.read<JournalProvider>();
    final eggProvider = context.read<EggProvider>();

    final chickens = chickenProvider.chickens;
    final batches = journalProvider.batches;
    final eggsLast7 = eggProvider.records
        .where((r) => r.date
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;
    final flockContext =
        provider.buildFlockContext(chickens, batches, eggsLast7);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreadScreen(
          thread: thread,
          flockContext: flockContext,
        ),
      ),
    ).then((_) {
      provider.loadThreads();
      _loadQuota();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    final threads = provider.threads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask ChickDaddyAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New conversation',
            onPressed: _newConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quota warning — only shown at 70%+
          if (!kDevMode && _usageFraction >= 0.7)
            _QuotaBanner(fraction: _usageFraction),

          // Dev mode badge
          if (kDevMode)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.developer_mode,
                      size: 14, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Text(
                    'Developer mode — quota limits bypassed',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade800),
                  ),
                ],
              ),
            ),

          Expanded(
            child: threads.isEmpty
                ? _EmptyState(onNew: _newConversation)
                : ListView.separated(
                    itemCount: threads.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final t = threads[i];
                      return Dismissible(
                        key: Key(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade400,
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) =>
                            provider.deleteThread(t.id),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D8A3C)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Color(0xFF5D8A3C),
                            ),
                          ),
                          title: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _relativeTime(t.updatedAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.grey),
                          onTap: () => _openThread(t),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: threads.isNotEmpty
          ? FloatingActionButton(
              onPressed: _newConversation,
              backgroundColor: const Color(0xFF5D8A3C),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

class _QuotaBanner extends StatelessWidget {
  final double fraction;
  const _QuotaBanner({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).round();
    final isAtLimit = fraction >= 1.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isAtLimit ? Colors.red.shade50 : Colors.amber.shade50,
      child: Row(
        children: [
          Icon(
            isAtLimit ? Icons.block : Icons.info_outline,
            size: 16,
            color: isAtLimit
                ? Colors.red.shade700
                : Colors.amber.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAtLimit
                  ? 'Monthly AI message limit reached — resets next month.'
                  : "You've used $pct% of your monthly AI messages.",
              style: TextStyle(
                fontSize: 12,
                color: isAtLimit
                    ? Colors.red.shade800
                    : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Ask ChickDaddyAI',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Get expert advice on your flock — health, breeds, '
              'incubation, feed, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: const Text('Start a conversation'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5D8A3C)),
            ),
          ],
        ),
      ),
    );
  }
}
