import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/ai_thread.dart';
import '../models/ai_message.dart';
import '../models/chicken.dart';
import '../models/chick_batch.dart';
import '../services/claude_service.dart';
import '../services/quota_service.dart';
import '../screens/settings/settings_screen.dart';

class AiChatProvider extends ChangeNotifier {
  List<AiThread> _threads = [];
  final Map<String, List<AiMessage>> _messages = {};
  bool _sending = false;
  String? _error;
  bool _errorIsAuth = false;

  List<AiThread> get threads => _threads;
  bool get sending => _sending;
  String? get error => _error;
  bool get errorIsAuth => _errorIsAuth;

  List<AiMessage> messagesFor(String threadId) =>
      _messages[threadId] ?? [];

  Future<void> loadThreads() async {
    _threads = await DatabaseHelper.instance.getAllAiThreads();
    notifyListeners();
  }

  Future<void> loadMessages(String threadId) async {
    _messages[threadId] =
        await DatabaseHelper.instance.getMessagesForThread(threadId);
    notifyListeners();
  }

  Future<AiThread> createThread() async {
    final now = DateTime.now();
    final thread = AiThread(
      id: const Uuid().v4(),
      title: 'New conversation',
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseHelper.instance.insertAiThread(thread);
    _threads.insert(0, thread);
    _messages[thread.id] = [];
    notifyListeners();
    return thread;
  }

  Future<void> deleteThread(String threadId) async {
    await DatabaseHelper.instance.deleteAiThread(threadId);
    _threads.removeWhere((t) => t.id == threadId);
    _messages.remove(threadId);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorIsAuth = false;
    notifyListeners();
  }

  /// Builds a flock context string from live data to inject into the system prompt.
  String buildFlockContext(
      List<Chicken> chickens, List<ChickBatch> batches, int eggsLast7Days) {
    final active = chickens.where((c) => c.status == 'active').toList();
    if (active.isEmpty && batches.isEmpty && eggsLast7Days == 0) return '';

    final buf = StringBuffer('[FLOCK DATA]\n');

    if (active.isNotEmpty) {
      buf.writeln('Active birds (${active.length}):');
      for (final c in active) {
        final age = c.currentAgeInDays != null
            ? '${(c.currentAgeInDays! ~/ 7)} weeks'
            : 'age unknown';
        final breed = c.breed?.isNotEmpty == true ? c.breed! : 'breed unknown';
        buf.writeln('- ${c.name}, $breed, $age, ${c.gender}');
      }
    }

    final activeBatches =
        batches.where((b) => b.status == 'incubating').toList();
    if (activeBatches.isNotEmpty) {
      buf.writeln('\nActive hatch batches:');
      for (final b in activeBatches) {
        final day = DateTime.now().difference(b.startDate).inDays + 1;
        final hatchDate = b.startDate
            .add(Duration(days: b.incubationDays))
            .toLocal();
        final hatchStr =
            '${hatchDate.day}/${hatchDate.month}/${hatchDate.year}';
        final breed =
            b.breed?.isNotEmpty == true ? b.breed! : 'breed unknown';
        buf.writeln(
            '- "${b.name}" ($breed) — day $day of ${b.incubationDays}, '
            'expected hatch around $hatchStr');
      }
    }

    if (eggsLast7Days > 0) {
      buf.writeln('\nEggs collected last 7 days: $eggsLast7Days');
    }

    buf.write('[/FLOCK DATA]');
    return buf.toString();
  }

  Future<void> sendMessage(
    String threadId,
    String userText, {
    required String flockContext,
  }) async {
    if (userText.trim().isEmpty) return;

    // Quota check
    if (await QuotaService.instance.isAtLimit()) {
      _error = 'You\'ve reached your monthly AI message limit. '
          'It resets at the start of next month.';
      _errorIsAuth = false;
      notifyListeners();
      return;
    }

    final apiKey = await SettingsScreen.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _error = 'No API key found — add one in Settings first.';
      _errorIsAuth = false;
      notifyListeners();
      return;
    }

    // Add user message
    final userMsg = AiMessage(
      id: const Uuid().v4(),
      threadId: threadId,
      role: 'user',
      content: userText.trim(),
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertAiMessage(userMsg);
    _messages.putIfAbsent(threadId, () => []).add(userMsg);

    // Update thread title from first user message
    final threadIndex = _threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1 &&
        _threads[threadIndex].title == 'New conversation') {
      final title = userText.trim().length > 50
          ? '${userText.trim().substring(0, 50)}…'
          : userText.trim();
      final updated = _threads[threadIndex].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.updateAiThread(updated);
      _threads[threadIndex] = updated;
    }

    _sending = true;
    _error = null;
    _errorIsAuth = false;
    notifyListeners();

    try {
      // Build message history for API
      final history = (_messages[threadId] ?? [])
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final service = ClaudeService(apiKey);
      final reply = await service.askChickDaddyAI(
        history,
        flockContext: flockContext,
      );

      final assistantMsg = AiMessage(
        id: const Uuid().v4(),
        threadId: threadId,
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertAiMessage(assistantMsg);
      _messages[threadId]!.add(assistantMsg);

      // Update thread timestamp
      if (threadIndex != -1) {
        final updated =
            _threads[threadIndex].copyWith(updatedAt: DateTime.now());
        await DatabaseHelper.instance.updateAiThread(updated);
        _threads[threadIndex] = updated;
        // Re-sort threads by updated_at
        _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      await QuotaService.instance.increment();
    } on TimeoutException {
      _error = 'Request timed out — check your connection and try again.';
    } on SocketException {
      _error = 'No internet connection. Please check your network.';
    } catch (e) {
      final isAuth = e is ClaudeServiceException && e.isAuthError;
      _error = e is ClaudeServiceException
          ? e.message
          : 'Something went wrong. Please try again.';
      _errorIsAuth = isAuth;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
