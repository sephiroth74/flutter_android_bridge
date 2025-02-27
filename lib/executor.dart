import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_android_bridge/exceptions.dart';

const _kRootInterval = Duration(milliseconds: 100);
const _kRootTimeout = Duration(seconds: 5);
const _kInterval = Duration(milliseconds: 100);
const _kDebug = true;

class Executor {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      await io.Process.run('adb', []);
    } on io.ProcessException catch (e) {
      throw AdbNotFoundException(message: e);
    }

    _initialized = true;
  }

  Future<io.Process> start(List<String> arguments, {bool runInShell = false}) async {
    await init();
    return await io.Process.start('adb', arguments, runInShell: runInShell);
  }

  Future<io.ProcessResult> execute(
    List<String> arguments, {
    bool runInShell = false,
    bool checkIfRunning = true,
  }) async {
    if (_kDebug) {
      final time = DateTime.now();
      final timeString = '${time.hour}:${time.minute}:${time.second}.${time.millisecond}';
      debugPrint('[$timeString] Executing [shell: $runInShell]: adb ${arguments.join(' ')}');
    }

    await init();

    final result = await io.Process.run('adb', arguments, runInShell: runInShell);

    if (_kDebug) {
      // print('[${result.exitCode}] Result: ${result.stdout}');
    }

    if (checkIfRunning && result.exitCode != 0) {
      if (result.stderr.toString().contains(AdbDaemonNotRunningException.trigger)) {
        throw AdbDaemonNotRunningException(message: result.stderr.toString());
      }

      // print('[${result.exitCode}] Error: ${result.stderr.toString()}');
      throw Exception(result.stderr);
    }
    return result;
  }

  Future<void> startServer() async {
    await init();

    while (true) {
      final io.ProcessResult result = await execute(['start-server'], runInShell: true, checkIfRunning: false);

      if (result.exitCode != 0) {
        if (result.stderr.toString().contains(AdbDaemonNotRunningException.trigger)) {
          await Future.delayed(_kInterval);
        }
        throw Exception(result.stderr);
      } else {
        return;
      }
    }
  }

  Future<void> killServer() async {
    await init();

    final io.ProcessResult result = await execute(['kill-server']);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
  }

  Future<void> root() async {
    await init();
    await execute(['root']);

    final now = DateTime.now();

    while (DateTime.now().difference(now) < _kRootTimeout) {
      await Future.delayed(_kRootInterval);
      if (await isRooted()) {
        return;
      }
    }

    throw Exception('Failed to start adb as root');
  }

  Future<void> unroot() async {
    await init();
    await execute(['unroot']);
    final now = DateTime.now();

    while (DateTime.now().difference(now) < _kRootTimeout) {
      await Future.delayed(_kRootInterval);
      if (!await isRooted()) {
        return;
      }
    }

    throw Exception('Failed to stop adb as root');
  }

  Future<bool> isRooted() async {
    await init();
    final result = await execute(['shell', 'whoami']);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    return result.stdout.toString().contains('root');
  }
}
