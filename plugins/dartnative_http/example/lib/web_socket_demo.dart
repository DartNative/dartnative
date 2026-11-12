// A WebSocket screen for this example, which upstream's example does not
// have: it connects to a public echo server, which sends back every message
// it receives. Everything comes from the one import of dartnative_http.

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_http/http.dart';

/// Postman's public echo server: every text message sent to it comes back.
/// It ends the connection when it receives a binary message, so this screen
/// sends text only.
final _echoServer = Uri.parse('wss://ws.postman-echo.com/raw');

/// Opens a WebSocket to an echo server: type a message, send it, and see it
/// come back.
class WebSocketDemoPage extends StatefulWidget {
  const WebSocketDemoPage({super.key});

  @override
  State<WebSocketDemoPage> createState() => _WebSocketDemoPageState();
}

class _WebSocketDemoPageState extends State<WebSocketDemoPage> {
  final _message = TextEditingController();
  // What was sent and received, newest first.
  final _lines = <String>[];
  NativeWebSocket? _socket;
  bool _connecting = false;
  bool _open = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    // Leaving the screen ends the connection.
    final socket = _socket;
    if (socket != null && _open) unawaited(_closeQuietly(socket));
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _status = 'Connecting to ${_echoServer.host}…';
    });
    final NativeWebSocket socket;
    try {
      socket = await NativeWebSocket.connect(_echoServer);
    } on WebSocketException catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = 'Could not connect: ${e.message}';
      });
      return;
    }
    if (!mounted) {
      // The screen closed while the connection was opening.
      unawaited(_closeQuietly(socket));
      return;
    }
    _socket = socket;
    setState(() {
      _connecting = false;
      _open = true;
      _status = 'Connected to ${_echoServer.host}';
    });
    socket.events.listen((event) {
      if (!mounted) return;
      setState(() {
        switch (event) {
          case TextDataReceived(:final text):
            _lines.insert(0, 'Server: $text');
          case BinaryDataReceived(:final data):
            _lines.insert(0, 'Server: ${data.length} bytes');
          case CloseReceived(:final code, :final reason):
            // The server closed the connection, or it was lost.
            _open = false;
            _status = 'Closed: $code $reason';
        }
      });
    });
  }

  void _send() {
    final text = _message.text;
    final socket = _socket;
    if (text.isEmpty || socket == null || !_open) return;
    try {
      socket.sendText(text);
    } on WebSocketConnectionClosed {
      // The server closed the connection a moment ago; its CloseReceived
      // event is on its way.
      return;
    }
    _message.clear();
    setState(() => _lines.insert(0, 'You: $text'));
  }

  Future<void> _disconnect() async {
    final socket = _socket;
    if (socket == null || !_open) return;
    setState(() {
      _open = false;
      _status = 'Closed by you';
    });
    await _closeQuietly(socket);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('WebSocket Echo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_status),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: _open,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Button(title: 'Send', onPressed: _open ? _send : null),
                ],
              ),
              const SizedBox(height: 12),
              Button(
                title: _open ? 'Close' : 'Connect',
                onPressed: _connecting ? null : (_open ? _disconnect : _connect),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (final line in _lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(line),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Closes [socket]. `close` throws a [WebSocketConnectionClosed] when the
/// connection is already closed, for example by the server a moment ago;
/// there is nothing left to do then.
Future<void> _closeQuietly(NativeWebSocket socket) async {
  try {
    await socket.close();
  } on WebSocketConnectionClosed {
    // Already closed.
  }
}
