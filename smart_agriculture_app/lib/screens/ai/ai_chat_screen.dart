import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _Bubble {
  const _Bubble({required this.isUser, required this.text, required this.time});

  final bool isUser;
  final String text;
  final String time;
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final List<_Bubble> _bubbles = [];
  bool _loadingHistory = true;
  bool _busy = false;
  bool _listening = false;
  int _speakingIndex = -1;

  static const List<String> _suggestions = [
    'Why are my leaves yellow?',
    'How should I water my crops?',
    'How can I control pests?',
    'Which fertilizer should I use?',
    'Why is my crop wilting?',
    'What should I do during heavy rain?',
  ];

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadHistory();
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _send(widget.initialQuestion!),
      );
    }
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speakingIndex = -1);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speakingIndex = -1);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = SessionService.instance.userId;
    List<ChatMessage> history = [];
    if (userId != null) {
      history = await DatabaseHelper.instance.getChatHistory(userId);
    }
    if (!mounted) return;
    if (history.isEmpty) {
      _bubbles.add(
        _Bubble(
          isUser: false,
          text: AIService.instance.getReply('hello'),
          time: _nowTime(),
        ),
      );
    } else {
      for (final message in history) {
        _bubbles.add(
          _Bubble(
            isUser: true,
            text: message.question,
            time: _formatTime(message.createdAt),
          ),
        );
        _bubbles.add(
          _Bubble(
            isUser: false,
            text: message.answer,
            time: _formatTime(message.createdAt),
          ),
        );
      }
    }
    setState(() => _loadingHistory = false);
    _scrollToBottom();
  }

  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return _nowTimeOf(dt);
    } catch (_) {
      return _nowTime();
    }
  }

  String _nowTimeOf(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _scrollToBottom() {
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

  Future<void> _send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _busy) return;
    _textController.clear();
    setState(() {
      _bubbles.add(_Bubble(isUser: true, text: text, time: _nowTime()));
      _busy = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));
    final answer = AIService.instance.getReply(text);
    if (!mounted) return;
    setState(() {
      _bubbles.add(_Bubble(isUser: false, text: answer, time: _nowTime()));
      _busy = false;
    });
    _scrollToBottom();

    final userId = SessionService.instance.userId;
    if (userId != null) {
      await DatabaseHelper.instance.addChatMessage(
        ChatMessage(
          userId: userId,
          question: text,
          answer: answer,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  Future<void> _speak(int index, String text) async {
    if (_speakingIndex == index) {
      await _tts.stop();
      setState(() => _speakingIndex = -1);
      return;
    }
    try {
      setState(() => _speakingIndex = index);
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      setState(() => _speakingIndex = -1);
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice input is not available on this device.'),
            ),
          );
        }
        return;
      }
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) return;
          setState(() => _textController.text = result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          partialResults: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start voice input.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.sunset,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Agriculture Assistant')),
        body: Column(
          children: [
            Expanded(
              child: _loadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _bubbles.length + (_busy ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _bubbles.length) {
                          return _typingRow();
                        }
                        return _bubbleRow(index, _bubbles[index]);
                      },
                    ),
            ),
            _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubbleRow(int index, _Bubble bubble) {
    if (bubble.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.green],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bubble.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                bubble.time,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.lightGreen],
              ),
            ),
            child: const Icon(Icons.eco, size: 19, color: AppColors.white),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 40),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFFDCEBDD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bubble.text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        bubble.time,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _speak(index, bubble.text),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _speakingIndex == index
                                ? AppColors.paleGreen
                                : AppColors.paleGreen.withValues(alpha: 0.5),
                          ),
                          child: Icon(
                            _speakingIndex == index
                                ? Icons.volume_up
                                : Icons.volume_up_outlined,
                            size: 17,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.lightGreen],
              ),
            ),
            child: const Icon(Icons.eco, size: 19, color: AppColors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            onPressed: () => _send(suggestion),
            backgroundColor: AppColors.paleGreen,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD4E7D5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleMic,
            tooltip: _listening ? 'Stop listening' : 'Speak your question',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening ? AppColors.danger : AppColors.paleGreen,
              ),
              child: Icon(
                _listening ? Icons.mic : Icons.mic_none,
                size: 20,
                color: _listening ? AppColors.white : AppColors.green,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 3,
              onSubmitted: _send,
              decoration: const InputDecoration(
                hintText: 'Ask about crops, pests, water…',
                border: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _send(_textController.text),
            tooltip: 'Send',
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.green],
                ),
              ),
              child: const Icon(Icons.send, size: 19, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
