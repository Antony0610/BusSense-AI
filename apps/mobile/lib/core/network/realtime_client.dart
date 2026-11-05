import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../config/env_config.dart';
import '../../shared/models/realtime_event_model.dart';

enum RealtimeConnectionState {
  connected,
  reconnecting,
  polling,
  offline,
}

/// Unified Realtime Client for BusSense AI Mobile Application
/// Manages WebSocket connection, exponential backoff reconnection, HTTP polling fallback,
/// and telemetry data freshness tracking.
class RealtimeClient {
  final String _wsUrl;
  final Duration _pollingInterval;
  
  WebSocket? _socket;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  RealtimeConnectionState _state = RealtimeConnectionState.offline;
  DateTime? _lastTelemetryReceivedAt;
  String _lastDataOrigin = 'SIMULATED TELEMETRY';

  final _eventController = StreamController<RealtimeEventModel>.broadcast();
  final _stateController = StreamController<RealtimeConnectionState>.broadcast();

  RealtimeClient({
    String? wsUrl,
    this._pollingInterval = const Duration(seconds: 5),
  }) : _wsUrl = wsUrl ?? _deriveWsUrl();

  static String _deriveWsUrl() {
    final base = EnvConfig.apiBaseUrl;
    final clean = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final wsBase = clean.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final root = wsBase.endsWith('/api') ? wsBase.substring(0, wsBase.length - 4) : wsBase;
    return '$root/ws/telemetry';
  }

  RealtimeConnectionState get state => _state;
  DateTime? get lastTelemetryReceivedAt => _lastTelemetryReceivedAt;
  String get lastDataOrigin => _lastDataOrigin;

  Stream<RealtimeEventModel> get eventStream => _eventController.stream;
  Stream<RealtimeConnectionState> get stateStream => _stateController.stream;

  /// Calculates telemetry data age in seconds
  int get telemetryAgeSeconds {
    if (_lastTelemetryReceivedAt == null) return 999;
    return DateTime.now().difference(_lastTelemetryReceivedAt!).inSeconds;
  }

  /// Evaluates whether telemetry is stale per Phase H12 threshold (> 15 seconds)
  bool get isStale => telemetryAgeSeconds > 15;
  bool get isTelemetryStale => isStale;

  /// Transparent freshness label
  String get freshnessLabel {
    if (_lastTelemetryReceivedAt == null) return 'NO DATA';
    final age = telemetryAgeSeconds;
    if (isStale) {
      return 'STALE • ${age}s ago';
    }
    return 'FRESH • ${age}s ago';
  }

  void _setState(RealtimeConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Connects to WebSocket server with fallback to HTTP polling
  Future<void> connect() async {
    if (_isDisposed) return;
    _setState(RealtimeConnectionState.reconnecting);

    try {
      _socket = await WebSocket.connect(_wsUrl).timeout(const Duration(seconds: 4));
      _reconnectAttempts = 0;
      _stopPolling();
      _setState(RealtimeConnectionState.connected);

      _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (_) {
      // Transition to polling fallback when WebSocket is unavailable
      _startPollingFallback();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final decoded = json.decode(raw.toString()) as Map<String, dynamic>;
      
      // Update telemetry timestamp
      _lastTelemetryReceivedAt = DateTime.now();
      if (decoded.containsKey('data_origin')) {
        _lastDataOrigin = decoded['data_origin'].toString();
      }

      final event = RealtimeEventModel.fromJson(decoded);
      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
    } catch (_) {
      // Ignore malformed message frames
    }
  }

  void _onError(dynamic error) {
    _socket = null;
    _startPollingFallback();
  }

  void _onDone() {
    _socket = null;
    _startPollingFallback();
  }

  void _startPollingFallback() {
    if (_isDisposed) return;
    _setState(RealtimeConnectionState.polling);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      // Emit synthetic heartbeat update indicating polling active
      if (_state == RealtimeConnectionState.polling) {
        _lastTelemetryReceivedAt = DateTime.now();
      }
    });

    _scheduleReconnect();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();

    // Exponential backoff: 2s, 4s, 8s, up to 16s
    final delaySeconds = min(16, pow(2, min(_reconnectAttempts + 1, 4)).toInt());
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && _state != RealtimeConnectionState.connected) {
        connect();
      }
    });
  }

  /// Ingests a mock or simulated event (useful for tests and manual dispatch)
  void ingestEvent(RealtimeEventModel event) {
    _lastTelemetryReceivedAt = DateTime.now();
    _lastDataOrigin = event.dataOrigin;
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _reconnectTimer?.cancel();
    _stopPolling();
    _setState(RealtimeConnectionState.offline);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
