import 'dart:io';

import 'package:flutter_android_bridge/flutter_android_bridge.dart';
import 'package:flutter_android_bridge/flutter_android_shell.dart';
import 'package:meta/meta.dart';

class FlutterAndroidClient {
  final Connection _connection;
  final FlutterAndroidBridge _bridge;

  @internal
  FlutterAndroidClient(String address, {required FlutterAndroidBridge bridge})
    : _connection = Connection(address),
      _bridge = bridge;

  Future<bool> connect() async {
    await _bridge.executor.execute(['connect', _connection.address]);
    return isConnected();
  }

  Future<bool> isConnected() async {
    final result = await _bridge.executor.execute([..._connection.arguments, 'get-state']);
    return result.stdout.toString().contains('device');
  }

  FlutterAndroidShell shell() {
    return FlutterAndroidShell(bridge: _bridge, connection: _connection);
  }

  Future<void> root() async {
    if (await isRooted()) {
      return;
    }
    return await _bridge.executor.root(_connection.arguments);
  }

  Future<void> unroot() async {
    if (!await isRooted()) {
      return;
    }
    return await _bridge.executor.unroot(_connection.arguments);
  }

  Future<bool> isRooted() async {
    return await _bridge.executor.isRooted(_connection.arguments);
  }

  Future<ProcessResult> disconnect() async {
    return await _bridge.executor.execute(['disconnect', _connection.address]);
  }
}

class Connection {
  final String address;
  const Connection(this.address);

  List<String> get arguments => ['-s', address];
}
