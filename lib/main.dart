import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mcp_llm/mcp_llm.dart';
import 'gemini_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _msgs = <_Msg>[];

  final _mcpLlm = McpLlm(); // เผื่อใช้ Claude/OpenAI
  LlmClient? _llmClient;     // Claude/OpenAI ผ่าน mcp_llm
  GeminiClient? _gemini;     // Gemini (REST)
  bool _busy = false;

  /// เลือกผู้ให้บริการ: 'gemini' | 'claude' | 'openai'
  String _provider = 'gemini'; // ค่าเริ่มต้น = Gemini (มีโควต้าฟรีสำหรับทดสอบ)

  @override
  void initState() {
    super.initState();
    _registerProviders();
    _initClient();
  }

  void _registerProviders() {
    _mcpLlm
      ..registerProvider('claude', ClaudeProviderFactory())
      ..registerProvider('openai', OpenAiProviderFactory());
  }

  Future<void> _initClient() async {
    setState(() => _busy = true);
    try {
      if (_provider == 'gemini') {
        const key = String.fromEnvironment('GEMINI_API_KEY');
        if (key.isEmpty) {
          throw 'ไม่พบ GEMINI_API_KEY (ส่งด้วย --dart-define=GEMINI_API_KEY=...)';
        }
        _gemini = GeminiClient(
          apiKey: key,
          model: 'gemini-2.5-flash', // จาก ListModels ของคุณ
        );
        _llmClient = null;
        return;
      }

      // Claude/OpenAI: ใช้ผ่าน mcp_llm
      late final LlmConfiguration cfg;
      if (_provider == 'claude') {
        const key = String.fromEnvironment('CLAUDE_API_KEY');
        if (key.isEmpty) {
          throw 'ไม่พบ CLAUDE_API_KEY (--dart-define=CLAUDE_API_KEY=...)';
        }
        cfg = LlmConfiguration(
          apiKey: key,
          model: 'claude-3-haiku-20240307',
          options: {'temperature': 0.7, 'max_tokens': 1500},
        );
      } else {
        const key = String.fromEnvironment('OPENAI_API_KEY');
        if (key.isEmpty) {
          throw 'ไม่พบ OPENAI_API_KEY (--dart-define=OPENAI_API_KEY=...)';
        }
        cfg = LlmConfiguration(
          apiKey: key,
          model: 'gpt-4o-mini',
          options: {'temperature': 0.7, 'max_tokens': 1500},
        );
      }

      _llmClient = await _mcpLlm.createClient(
        providerName: _provider,
        config: cfg,
        systemPrompt:
            'You are a helpful Thai assistant for Flutter & MCP. Be concise and friendly.',
      );
      _gemini = null;
    } catch (e) {
      _snack('Init error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() => _msgs.add(_Msg('You', text)));

    // สร้างช่องตอบของ AI
    setState(() {
      _msgs.add(_Msg('AI', ''));
      _busy = true;
    });
    final idx = _msgs.length - 1;

    try {
      if (_provider == 'gemini') {
        // Gemini: non-stream (เสถียรบน Web/เดสก์ท็อป)
        final history = _msgs
            .take(_msgs.length - 1)
            .map((m) => {
                  'role': m.author == 'AI' ? 'model' : 'user',
                  'text': m.text,
                })
            .toList();
        final ans = await _gemini!.chat(text, history: history);
        setState(() => _msgs[idx] = _msgs[idx].replace(ans));
        return;
      }

      // Claude/OpenAI:
      if (kIsWeb) {
        final res = await _llmClient!.chat(text);
        setState(() => _msgs[idx] = _msgs[idx].replace(res.text));
      } else {
        // ลองสตรีมก่อน (เดสก์ท็อป)
        final stream = _llmClient!.streamChat(text);
        bool gotAny = false;
        await for (final chunk in stream) {
          final add = chunk.textChunk ?? '';
          if (add.isNotEmpty) gotAny = true;
          setState(() => _msgs[idx] = _msgs[idx].append(add));
          if (chunk.isDone) break;
        }
        if (!gotAny) {
          final res = await _llmClient!.chat(text);
          setState(() => _msgs[idx] = _msgs[idx].replace(res.text));
        }
      }
    } catch (e) {
      // แสดง error จริงเพื่อดีบักง่าย
      setState(() => _msgs[idx] = _msgs[idx].replace('AI Error: $e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    _textCtrl.dispose();
    _mcpLlm.shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat App'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _provider,
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _provider = v);
                await _initClient();
              },
              items: const [
                DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                DropdownMenuItem(value: 'claude', child: Text('Claude')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[_msgs.length - 1 - i];
                final me = m.author == 'You';
                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 720),
                    decoration: BoxDecoration(
                      color: me ? Colors.blue.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText('${m.author}: ${m.text}'),
                  ),
                );
              },
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความ…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('ส่ง'),
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

class _Msg {
  final String author;
  final String text;
  const _Msg(this.author, this.text);
  _Msg append(String chunk) => _Msg(author, '$text$chunk');
  _Msg replace(String t) => _Msg(author, t);
}
