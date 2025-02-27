import 'package:flutter_android_bridge/flutter_android_intent.dart';
import 'package:flutter_android_bridge/flutter_android_shell.dart';

class FlutterAndroidActivityManager {
  final FlutterAndroidShell _shell;

  FlutterAndroidActivityManager({required FlutterAndroidShell shell}) : _shell = shell;

  Future<void> forceStop(String packageName) async {
    await _shell.exec(['am', 'force-stop', packageName]);
  }

  Future<void> start(FlutterAndroidIntent intent) async {
    await _shell.exec(['am', 'start', ...intent.asArguments()]);
  }

  Future<void> broadcast(FlutterAndroidIntent intent) async {
    await _shell.exec(['am', 'broadcast', ...intent.asArguments()]);
  }

  Future<void> instrument(FlutterAndroidIntent intent) async {
    await _shell.exec(['am', 'instrument', ...intent.asArguments()]);
  }

  Future<void> startService(FlutterAndroidIntent intent) async {
    await _shell.exec(['am', 'startservice', ...intent.asArguments()]);
  }

  Future<void> startForegroundService(FlutterAndroidIntent intent) async {
    await _shell.exec(['am', 'start-foreground-service', ...intent.asArguments()]);
  }
}
