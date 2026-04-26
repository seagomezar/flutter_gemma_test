import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma 4 Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  int _progress = 0;
  String _status = "Checking model...";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      setState(() {
        _status = "Downloading Gemma 4 model (this might take a while)...";
        _isReady = false;
        _progress = 0;
      });
      await FlutterGemma.installModel(
        modelType: ModelType.deepSeek, // Using deepSeek for SmolLM
      ).fromNetwork(
        'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/model.task',
        foreground: false,
      ).withProgress((progress) {
        setState(() {
          _progress = progress;
          _status = "Downloading: $_progress%";
        });
      }).install();

      setState(() => _status = "Model ready!");
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      }
    } catch (e) {
      setState(() => _status = "Error loading model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smart_toy, size: 80, color: Colors.teal),
              const SizedBox(height: 32),
              Text(_status, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (!_isReady && _status.contains("Downloading"))
                Column(
                  children: [
                    Text(
                      '$_progress%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 250,
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress / 100 : null,
                        backgroundColor: Colors.grey[800],
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              if (!_isReady && _status.contains("Error"))
                ElevatedButton.icon(
                  onPressed: _initializeModel,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isThinking;

  ChatMessage({required this.text, required this.isUser, this.isThinking = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  InferenceModel? _model;
  dynamic _chat;
  String _thinkingText = "";

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    _chat = await _model!.createChat(isThinking: false, modelType: ModelType.deepSeek);
    setState(() {
      _messages.add(ChatMessage(text: "Hello! I am SmolLM. How can I help you today?", isUser: false));
    });
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

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isGenerating || _chat == null) return;

    final userText = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _isGenerating = true;
      _thinkingText = "";
      _messages.add(ChatMessage(text: "", isUser: false)); // Placeholder for response
    });
    _scrollToBottom();

    try {
      await _chat!.addQueryChunk(Message.text(text: userText, isUser: true));

      _chat!.generateChatResponseAsync().listen(
        (response) {
          setState(() {
            if (response is ThinkingResponse) {
              _thinkingText += response.content;
              _messages[_messages.length - 1] = ChatMessage(
                text: _messages.last.text, 
                isUser: false,
                isThinking: true,
              );
            } else if (response is TextResponse) {
              final currentText = _messages.last.text;
              _messages[_messages.length - 1] = ChatMessage(
                text: currentText + response.token,
                isUser: false,
              );
            }
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() => _isGenerating = false);
        },
        onError: (e) {
          setState(() {
            _messages[_messages.length - 1] = ChatMessage(
              text: "Error generating response: $e",
              isUser: false,
            );
            _isGenerating = false;
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma 4 Chat'),
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.teal[800] : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: message.isUser ? const Radius.circular(0) : null,
                        bottomLeft: !message.isUser ? const Radius.circular(0) : null,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isThinking && _thinkingText.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.psychology, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Thinking:\n$_thinkingText", 
                                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Message Gemma...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isGenerating,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _isGenerating ? Colors.grey[700] : Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isGenerating ? null : _sendMessage,
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
