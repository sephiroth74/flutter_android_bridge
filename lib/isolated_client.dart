import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_android_bridge/library.dart';

class Worker {
  final SendPort _commands;
  final ReceivePort _responses;
  final FlutterAndroidClient _client;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Future<Object?> connect() async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, 'connect', _client));
    return await completer.future;
  }

  static Future<Worker> spawn(FlutterAndroidClient client) async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return Worker._(client, receivePort, sendPort);
  }

  Worker._(this._client, this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    print('--- response from isolate ---');
    print('message: $message');

    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(ReceivePort receivePort, SendPort sendPort) {
    receivePort.listen((message) {
      print('--- command to isolate ---');
      print('message: $message');

      if (message == 'shutdown') {
        receivePort.close();
        return;
      }

      final (int id, String command, dynamic arguments) = message as (int, String, dynamic);
      print('command: $command');

      if (command == 'connect') {
        final FlutterAndroidClient client = arguments as FlutterAndroidClient;
        client
            .connect()
            .then((value) {
              sendPort.send((id, value));
            })
            .catchError((e) {
              sendPort.send((id, RemoteError(e.toString(), '')));
            });
      } else {
        sendPort.send((id, RemoteError('Unknown command', command)));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      print('--- port closed --- ');
    }
  }
}

class IsolatedClient {
  final FlutterAndroidClient _client;
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Future<bool> connect() async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<bool>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, 'connect', _client));
    return await completer.future;
  }

  static Future<IsolatedClient> spawn(FlutterAndroidClient client) async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      debugPrint('--- initial message ---');
      debugPrint(initialMessage.toString());

      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      debugPrint('--- error spawning isolate ---');

      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return IsolatedClient._(client, receivePort, sendPort);
  }

  IsolatedClient._(this._client, this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    debugPrint('--- response from isolate ---');
    debugPrint(message.toString());

    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(ReceivePort receivePort, SendPort sendPort) {
    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }

      final args = message as List<dynamic>;
      final int id = args[0] as int;
      final String command = args[1] as String;
      final FlutterAndroidClient client = args[2] as FlutterAndroidClient;

      if (command == 'connect') {
        client
            .connect()
            .then((value) {
              sendPort.send((id, value));
            })
            .catchError((e) {
              sendPort.send((id, RemoteError(e.toString(), '')));
            });
        return;
      } else {
        sendPort.send((id, RemoteError('Unknown command', command)));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      print('--- port closed --- ');
    }
  }
}
