import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_android_bridge/library.dart';

const _kRootInterval = Duration(milliseconds: 100);
const _kRootTimeout = Duration(seconds: 5);
const _kInterval = Duration(milliseconds: 100);

class Executor {
  final String? _adbPath;
  final bool debug;
  bool _initialized = false;

  Executor({required String? adbPath, this.debug = false}) : _adbPath = adbPath {
    debugPrint('Executor: adbPath: $adbPath');
    if (adbPath == null || adbPath.isEmpty) {
      throw AdbNotFoundException(message: 'adbPath is null');
    }
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      await io.Process.run(_adbPath!, ['--version'], runInShell: true);
      _initialized = true;
    } on io.ProcessException catch (e) {
      throw AdbNotFoundException(message: e);
    }
  }

  Future<io.Process> start(List<String> arguments, {bool runInShell = true}) async {
    await init();
    return await io.Process.start(_adbPath!, arguments, runInShell: runInShell);
  }

  Future<io.ProcessResult> execute(
    List<String> arguments, {
    bool runInShell = true,
    bool checkIfRunning = true,
    Duration? timeout,
  }) async {
    final time = DateTime.now();

    if (debug) {
      final timeString = '${time.hour}:${time.minute}:${time.second}.${time.millisecond}';
      debugPrint('[$timeString] Executing $_adbPath ${arguments.join(' ')}');
    }

    await init();
    final process = io.Process.run(_adbPath!, arguments, runInShell: runInShell);
    final result;

    if (timeout != null) {
      result = await process.timeout(timeout);
    } else {
      result = await process;
    }

    if (debug) {
      final t2 = DateTime.now();
      final elapsed = t2.difference(time).inMilliseconds;
      final timeString = '${t2.hour}:${t2.minute}:${t2.second}.${t2.millisecond}';
      debugPrint('[$timeString] exitCode: ${result.exitCode}, elapsed: $elapsed ms');
    }

    if (checkIfRunning && result.exitCode != 0) {
      if (result.stderr.toString().contains(AdbDaemonNotRunningException.trigger)) {
        throw AdbDaemonNotRunningException(message: result.stderr.toString());
      }

      throw Exception(result.stderr);
    }
    return result;
  }

  Future<void> startServer() async {
    await init();

    while (true) {
      final io.ProcessResult result = await execute(['start-server']);

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

  Future<void> root(List<String> arguments) async {
    await init();
    await execute([...arguments, 'root']);

    final now = DateTime.now();

    while (DateTime.now().difference(now) < _kRootTimeout) {
      await Future.delayed(_kRootInterval);
      if (await isRooted(arguments)) {
        return;
      }
    }

    throw Exception('Failed to start adb as root');
  }

  Future<void> unroot(List<String> arguments) async {
    await init();
    await execute([...arguments, 'unroot']);
    final now = DateTime.now();

    while (DateTime.now().difference(now) < _kRootTimeout) {
      await Future.delayed(_kRootInterval);
      if (!await isRooted(arguments)) {
        return;
      }
    }

    throw Exception('Failed to stop adb as root');
  }

  Future<bool> isRooted(List<String> arguments) async {
    await init();
    final result = await execute([...arguments, 'shell', 'whoami']);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    return result.stdout.toString().contains('root');
  }
}
