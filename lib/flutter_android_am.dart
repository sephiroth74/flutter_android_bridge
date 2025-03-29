import 'package:flutter_android_bridge/flutter_android_intent.dart';
import 'package:flutter_android_bridge/flutter_android_shell.dart';

class FlutterAndroidActivityManager {
  final FlutterAndroidShell _shell;

  FlutterAndroidActivityManager({required FlutterAndroidShell shell}) : _shell = shell;

  Future<void> forceStop(String packageName, {bool debug = false}) async {
    await _shell.exec(['am', 'force-stop', packageName], debug: debug);
  }

  Future<void> start(FlutterAndroidIntent intent, {bool debug = false}) async {
    await _shell.exec(['am', 'start', ...intent.asArguments()], debug: debug);
  }

  Future<void> broadcast(FlutterAndroidIntent intent, {bool debug = false}) async {
    await _shell.exec(['am', 'broadcast', ...intent.asArguments()], debug: debug);
  }

  Future<void> instrument(FlutterAndroidIntent intent, {bool debug = false}) async {
    await _shell.exec(['am', 'instrument', ...intent.asArguments()], debug: debug);
  }

  Future<void> startService(FlutterAndroidIntent intent, {bool debug = false}) async {
    await _shell.exec(['am', 'startservice', ...intent.asArguments()], debug: debug);
  }

  Future<void> startForegroundService(FlutterAndroidIntent intent, {bool debug = false}) async {
    await _shell.exec(['am', 'start-foreground-service', ...intent.asArguments()], debug: debug);
  }
}
