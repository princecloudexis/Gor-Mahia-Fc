import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../repositories/match_repository.dart';
import '../models/match_models.dart';

final echoServiceProvider = Provider<EchoService>((ref) {
  final repo = ref.watch(matchRepositoryProvider);
  return EchoService(repo);
});

/// Implements the Pusher protocol over raw WebSockets, compatible with Laravel Reverb.
class EchoService {
  final MatchRepository _repository;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Map<String, List<Function(MatchChatMessage)>> _listeners = {};

  bool _isConnected = false;

  EchoService(this._repository);

  Future<void> _ensureConnected() async {
    if (_isConnected) return;

    try {
      final config = await _repository.getBroadcastingConfig();
      final appKey = config['app_key'];
      var host = config['host'];
      var port = config['port'];
      var useTls = config['use_tls'] ?? false;

      // Workaround for dev environment config returned by backend
      if (host == '127.0.0.1' || host == 'localhost') {
        host = 'footballclub.staging-workhub.com';
        // The staging server uses WSS (HTTPS), so we need to use port 443:
        port = '443';
        useTls = true;
      }

      final scheme = useTls ? 'wss' : 'ws';
      final uri = Uri.parse('$scheme://$host:$port/app/$appKey?protocol=7&client=flutter&version=1.0&flash=false');

      _channel = WebSocketChannel.connect(uri);
      
      // Wait for the connection to be established to catch any SocketException
      // and prevent the app from crashing due to unhandled exceptions.
      await _channel!.ready;

      _isConnected = true;
      print('[EchoService] Connected to WebSocket: $uri');

      _subscription = _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          print('[EchoService] WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('[EchoService] WebSocket connection closed.');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('[EchoService] Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw.toString());
      final event = msg['event'] ?? '';
      final channel = msg['channel'] ?? '';

      // Ignore system events
      if (event == 'pusher:connection_established' || event == 'pusher_internal:subscription_succeeded') {
        print('[EchoService] [$channel] System event: $event');
        return;
      }

      // Dispatch to listeners registered for this channel
      if (_listeners.containsKey(channel)) {
        final dataRaw = msg['data'];
        final Map<String, dynamic> data = dataRaw is String ? jsonDecode(dataRaw) : (dataRaw ?? {});

        // The payload is the message object directly
        final payload = data['message'] ?? data;

        try {
          final chatMessage = MatchChatMessage.fromJson(payload);
          for (final listener in _listeners[channel] ?? []) {
            listener(chatMessage);
          }
        } catch (e) {
          print('[EchoService] Error parsing chat message: $e');
        }
      }
    } catch (e) {
      print('[EchoService] Error handling message: $e');
    }
  }

  Future<void> subscribeToMatchChat(int matchId, Function(MatchChatMessage) onMessageReceived) async {
    try {
      await _ensureConnected();

      final channelName = 'match-chat.$matchId';
      _listeners[channelName] = [onMessageReceived];

      // Send Pusher subscribe command
      final subscribePayload = jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName}
      });
      _channel!.sink.add(subscribePayload);
      print('[EchoService] Subscribed to channel: $channelName');
    } catch (e) {
      print('[EchoService] Error subscribing to match chat: $e');
    }
  }

  void unsubscribeFromMatchChat(int matchId) {
    final channelName = 'match-chat.$matchId';
    _listeners.remove(channelName);

    if (_channel != null) {
      final unsubscribePayload = jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName}
      });
      _channel!.sink.add(unsubscribePayload);
      print('[EchoService] Unsubscribed from channel: $channelName');
    }

    // If no more listeners, disconnect
    if (_listeners.isEmpty) {
      _subscription?.cancel();
      _channel?.sink.close();
      _isConnected = false;
    }
  }
}
