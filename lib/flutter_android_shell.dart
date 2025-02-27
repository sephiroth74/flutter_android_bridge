import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_android_bridge/exceptions.dart';
import 'package:flutter_android_bridge/flutter_android_am.dart';
import 'package:flutter_android_bridge/flutter_android_bridge.dart';
import 'package:flutter_android_bridge/flutter_android_client.dart';
import 'package:flutter_android_bridge/flutter_android_pm.dart';
import 'package:flutter_android_bridge/flutter_android_types.dart';
import 'package:properties/properties.dart';

RegExp _kGetPropRegExp = RegExp(r'^\[(.*)\]\s*:\s*\[([^\]]*)\]\s*$', multiLine: true);
RegExp _kGetProps = RegExp(r'^\[(.*)\]\s*:\s*\[([^\]]*)\]$');

class FlutterAndroidShell {
  final FlutterAndroidBridge _bridge;
  final Connection _connection;

  FlutterAndroidShell({required FlutterAndroidBridge bridge, required Connection connection})
    : _bridge = bridge,
      _connection = connection;

  Future<io.ProcessResult> cat(String path) async {
    return await _bridge.executor.execute([..._connection.arguments, 'shell', 'cat', path]);
  }

  Future<io.ProcessResult> exec(List<String> command) async {
    return await _bridge.executor.execute([..._connection.arguments, 'shell', ...command]);
  }

  Future<void> mount(String path) async {
    await _bridge.executor.execute([..._connection.arguments, 'shell', 'mount', '-o', 'rw,remount', path]);
  }

  Future<void> unmount(String path) async {
    await _bridge.executor.execute([..._connection.arguments, 'shell', 'mount', '-o', 'ro,remount', path]);
  }

  Future<String> command(String command) async {
    return _bridge.executor
        .execute([..._connection.arguments, 'shell', 'command', '-v', command])
        .then((result) {
          final string = result.stdout.toString().trim();
          if (result.exitCode != 0 || string.isEmpty) {
            throw AdbFileNotFoundExeption(command);
          } else {
            return string;
          }
        })
        .catchError((e) {
          throw AdbFileNotFoundExeption(command);
        });
  }

  Future<void> checkAvbctl() async {
    return command('avbctl').then((_) {}).catchError((e) {
      throw AdbFileNotFoundExeption('avbctl');
    });
  }

  Future<bool> hasAvbctl() async {
    return command('avbctl').then((_) => true).catchError((e) => false);
  }

  Future<String> which(String command) async {
    return _bridge.executor
        .execute([..._connection.arguments, 'shell', 'which', command])
        .then((result) {
          final string = result.stdout.toString().trim();
          if (result.exitCode != 0 || string.isEmpty) {
            throw AdbFileNotFoundExeption(command);
          } else {
            return string;
          }
        })
        .catchError((e) {
          throw AdbFileNotFoundExeption(command);
        });
  }

  Future<bool> getVerityStatus() async {
    return checkAvbctl().then((_) {
      return exec(['avbctl', 'get-verity']).then((result) {
        return result.stdout.toString().contains('enabled');
      });
    });
  }

  Future<void> disableVerity() async {
    await checkAvbctl();
    await exec(['avbctl', 'disable-verification']);
  }

  Future<void> enableVerity() async {
    await checkAvbctl();
    await exec(['avbctl', 'enable-verity']);
  }

  Future<bool> isScreenOn() async {
    final result = await exec(["dumpsys input_method | egrep 'mInteractive=(true|false)'"]);
    return result.stdout.toString().contains('mInteractive=true');
  }

  Future<io.ProcessResult> sendKeyEvent(KeyCode keyCode, {KeyEventType? type, InputSource? inputSource}) async {
    final event = _makeKeyEvent(keyCode, eventType: type, inputSource: inputSource);
    return await exec(event);
  }

  Future<io.ProcessResult> sendKeyCode(int keyCode, {KeyEventType? type, InputSource? inputSource}) async {
    final event = _makeKeyCode(keyCode, eventType: type, inputSource: inputSource);
    return await exec(event);
  }

  Future<Properties> listSettings(SettingsType type) async {
    return exec(['settings', 'list', type.name]).then((result) {
      return Properties.fromString(result.stdout.toString());
    });
  }

  Future<String> getSetting(SettingsType type, {required String key}) async {
    return exec(['settings', 'get', type.name, key]).then((result) {
      final value = result.stdout.toString().trim();
      if (value == 'null') {
        return '';
      }
      return value;
    });
  }

  Future<void> putSetting(SettingsType type, {required String key, required String value}) async {
    await exec(['settings', 'put', type.name, key, value]);
  }

  Future<void> deleteSetting(SettingsType type, {required String key}) async {
    await exec(['settings', 'delete', type.name, key]);
  }

  Future<bool> testFile(String path, String mode) async {
    return exec(['test -$mode $path && echo 1 || echo 0']).then((result) {
      return result.stdout.toString().trim() == '1';
    });
  }

  Future<bool> exists(String path) async {
    return testFile(path, 'e');
  }

  Future<bool> isFile(String path) async {
    return testFile(path, 'f');
  }

  Future<bool> isDirectory(String path) async {
    return testFile(path, 'd');
  }

  Future<bool> isSymLink(String path) async {
    return testFile(path, 'h');
  }

  Future<io.ProcessResult> screencap(String path) async {
    return await exec(['screencap', '-p', path]);
  }

  Future<void> rm(String path, {List<String> args = const []}) async {
    await exec(['rm', ...args, path]);
  }

  Future<String> getProp(String key) async {
    return exec(['getprop', key]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  Future<PropType> getPropType(String key) async {
    final result = await exec(['getprop', '-T', key]);
    final value = result.stdout.toString().trim();
    return PropType.fromString(value);
  }

  Future<Map<String, PropType>> getPropTypes() async {
    final result = await exec(['getprop', '-T']);
    final lines = result.stdout.toString().split('\n');
    final props = <String, PropType>{};
    for (final line in lines) {
      _kGetProps.allMatches(line).forEach((match) {
        props[match.group(1)!] = PropType.fromString(match.group(2)!);
      });
    }
    return props;
  }

  Future<Map<String, String>> getProps() async {
    return exec(['getprop']).then((result) {
      final lines = result.stdout.toString().split('\n');
      final props = <String, String>{};
      for (final line in lines) {
        final match = _kGetPropRegExp.firstMatch(line.trim());
        if (match != null) {
          props[match.group(1)!] = match.group(2)!;
        }
      }
      return props;
    });
  }

  Future<void> setProp(String key, String value) async {
    final newValue = value == "" ? '""' : value;
    await exec(['setprop', key, newValue]);
  }

  Future<void> clearProp(String key) async {
    await setProp(key, '');
  }

  FlutterAndroidActivityManager am() {
    return FlutterAndroidActivityManager(shell: this);
  }

  FlutterAndroidPackageManager pm() {
    return FlutterAndroidPackageManager(shell: this);
  }

  ///
  /// Start screen recording
  /// [answer] - ReceivePort to listen for the response
  /// [recordingOptions] - ScreenRecordOptions
  /// [playOptions] - FFPlayOptions
  /// Returns SendPort to control the screen recording
  ///
  /// Example:
  /// ```dart
  /// final answer = ReceivePort();
  /// final sendPort = await client.shell().screenMirror(answer: answer);
  /// sendPort.send('start');
  ///
  /// Future.delayed(Duration(seconds: 10), () {
  ///  sendPort.send('stop');
  /// });
  ///
  /// await for (final message in answer) {
  ///  print(message);
  /// }
  ///
  /// ```
  ///
  Future<SendPort> screenMirror({
    required ReceivePort answer,
    ScreenRecordOptions recordingOptions = const ScreenRecordOptions(),
    FFPlayOptions playOptions = const FFPlayOptions(),
  }) async {
    final response = ReceivePort();
    final screenArgs = [..._connection.arguments, 'shell', 'screenrecord', ...recordingOptions.toArgs(), '-'];
    final ffplayArgs = [...playOptions.toArgs()];

    await Isolate.spawn(_screenMirrorTask, response.sendPort);
    final sendPort = await response.first;
    sendPort.send(['setup', answer.sendPort, screenArgs, ffplayArgs]);
    return sendPort;
  }

  Future<SELinuxType> getEnforce() async {
    return exec(['getenforce']).then((result) {
      final value = result.stdout.toString().trim();
      return SELinuxType.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
    });
  }

  Future<void> setEnforce(SELinuxType type) async {
    await exec(['setenforce', ...type.toArgs()]);
  }

  Future<void> sendTap(Point<int> pos, {InputSource? inputSource}) async {
    await exec(_makeTap(pos, inputSource: inputSource));
  }

  Future<void> sendEvent({required String event, required int codeType, required int code, required int value}) async {
    await exec(_makeEvent(event, codeType, code, value));
  }

  Future<void> sendText(String text, {InputSource? inputSource}) async {
    await exec(_makeText(text, inputSource: inputSource));
  }

  Future<void> sendMotion(MotionEvent motion, {required Point<int> pos, InputSource? inputSource}) async {
    await exec(_makeMotion(motion, pos: pos, inputSource: inputSource));
  }

  Future<void> sendDragAndDrop({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
  }) async {
    await exec(_makeDragAndDrop(inputSource: inputSource, duration: duration, start: start, end: end));
  }

  Future<void> sendPress({InputSource? inputSource}) async {
    await exec(_makePress(inputSource));
  }

  Future<void> sendKeyEvents(List<KeyCode> events, {InputSource? inputSource}) async {
    await exec(_makeKeyEvents(events, inputSource: inputSource));
  }

  Future<void> sendKeyCodes(List<int> keycodes, {InputSource? inputSource}) async {
    await exec(_makeKeyCodes(keycodes, inputSource: inputSource));
  }

  Future<void> sendSwipe({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
  }) async {
    await exec(_makeSwipe(inputSource: inputSource, duration: duration, start: start, end: end));
  }

  Future<void> _screenMirrorTask(SendPort mainIsolateSendPort) async {
    final port = ReceivePort();
    mainIsolateSendPort.send(port.sendPort);

    io.Process? s1;
    io.Process? s2;
    List<String>? screenArgs;
    List<String>? ffplayArgs;
    SendPort? replyTo;

    port.listen((message) async {
      final String action = message is String ? message : (message as List<dynamic>)[0];

      if (action == 'setup') {
        final List<dynamic> msg = message;
        replyTo = msg[1];
        screenArgs = msg[2];
        ffplayArgs = msg[3];

        replyTo?.send('setup');
      } else if (action == 'start') {
        s1 = await io.Process.start('adb', screenArgs!, runInShell: true);
        s2 = await io.Process.start('ffplay', ffplayArgs!, runInShell: true);

        replyTo?.send('started');

        s1!.stdout.pipe(s2!.stdin);
        await io.stdout.addStream(s2!.stdout);

        replyTo?.send('done');
      } else {
        s1?.kill();
        s2?.kill();

        replyTo?.send('stopped');
        port.close();
      }
    });
  }

  List<String> _makeSwipe({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
  }) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }
    args.add('swipe');
    args.add(start.x.toString());
    args.add(start.y.toString());
    args.add(end.x.toString());
    args.add(end.y.toString());

    if (duration != null) {
      args.add(duration.inMilliseconds.toString());
    }

    return args;
  }

  List<String> _makePress(InputSource? inputSource) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }
    args.add('press');
    return args;
  }

  List<String> _makeDragAndDrop({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
  }) {
    List<String> args = ['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }
    args.add('draganddrop');
    args.add(start.x.toString());
    args.add(start.y.toString());
    args.add(end.x.toString());
    args.add(end.y.toString());

    if (duration != null) {
      args.add(duration.inMilliseconds.toString());
    }

    return args;
  }

  List<String> _makeMotion(MotionEvent motion, {required Point<int> pos, InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('motionevent');
    args.add(motion.name);
    args.add(pos.x.toString());
    args.add(pos.y.toString());
    return args;
  }

  List<String> _makeText(String char, {InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }
    args.add('text');
    args.add(char);
    return args;
  }

  List<String> _makeEvent(String event, int codeType, int code, int value) {
    return ['sendevent', event, codeType.toString(), code.toString(), value.toString()];
  }

  List<String> _makeTap(Point<int> pos, {InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('tap');
    args.add(pos.x.toString());
    args.add(pos.y.toString());
    return args;
  }

  List<String> _makeKeyEvents(List<KeyCode> events, {InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('keyevent');
    args.addAll(events.map((e) => e.name));
    return args;
  }

  List<String> _makeKeyEvent(KeyCode keycode, {KeyEventType? eventType, InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('keyevent');

    if (eventType != null) {
      args.addAll(eventType.toArgs());
    }

    args.add(keycode.name);
    return args;
  }

  List<String> _makeKeyCodes(List<int> keycodes, {InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('keyevent');
    args.addAll(keycodes.map((e) => e.toString()));
    return args;
  }

  List<String> _makeKeyCode(int keycode, {KeyEventType? eventType, InputSource? inputSource}) {
    final args = <String>['input'];
    if (inputSource != null) {
      args.add(inputSource.name);
    }

    args.add('keyevent');

    if (eventType != null) {
      args.addAll(eventType.toArgs());
    }

    args.add(keycode.toString());
    return args;
  }
}
