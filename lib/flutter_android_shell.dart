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

  Future<io.ProcessResult> cat(String path, {bool debug = false}) async {
    return await _bridge.executor.execute([..._connection.arguments, 'shell', 'cat', path], debug: debug);
  }

  Future<io.ProcessResult> exec(List<String> command, {bool debug = false}) async {
    return await _bridge.executor.execute([..._connection.arguments, 'shell', ...command], debug: debug);
  }

  Future<void> mount(String path, {bool debug = false}) async {
    await _bridge.executor.execute([
      ..._connection.arguments,
      'shell',
      'mount',
      '-o',
      'rw,remount',
      path,
    ], debug: debug);
  }

  Future<void> unmount(String path, {bool debug = false}) async {
    await _bridge.executor.execute([
      ..._connection.arguments,
      'shell',
      'mount',
      '-o',
      'ro,remount',
      path,
    ], debug: debug);
  }

  Future<String> command(String command, {bool debug = false}) async {
    return _bridge.executor
        .execute([..._connection.arguments, 'shell', 'command', '-v', command], debug: debug)
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

  Future<void> checkAvbctl({bool debug = false}) async {
    return command('avbctl', debug: debug).then((_) {}).catchError((e) {
      throw AdbFileNotFoundExeption('avbctl');
    });
  }

  Future<bool> hasAvbctl({bool debug = false}) async {
    return command('avbctl', debug: debug).then((_) => true).catchError((e) => false);
  }

  Future<String> which(String command, {bool debug = false}) async {
    return _bridge.executor
        .execute([..._connection.arguments, 'shell', 'which', command], debug: debug)
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

  Future<bool> getVerityStatus({bool debug = false}) async {
    return checkAvbctl(debug: debug).then((_) {
      return exec(['avbctl', 'get-verity']).then((result) {
        return result.stdout.toString().contains('enabled');
      });
    });
  }

  Future<void> disableVerity({bool debug = false}) async {
    await checkAvbctl(debug: debug);
    await exec(['avbctl', 'disable-verification'], debug: debug);
  }

  Future<void> enableVerity({bool debug = false}) async {
    await checkAvbctl(debug: debug);
    await exec(['avbctl', 'enable-verity'], debug: debug);
  }

  Future<bool> isScreenOn({bool debug = false}) async {
    final result = await exec(["dumpsys input_method | egrep 'mInteractive=(true|false)'"], debug: debug);
    return result.stdout.toString().contains('mInteractive=true');
  }

  Future<io.ProcessResult> sendKeyEvent(
    KeyCode keyCode, {
    KeyEventType? type,
    InputSource? inputSource,
    bool debug = false,
  }) async {
    final event = _makeKeyEvent(keyCode, eventType: type, inputSource: inputSource);
    return await exec(event, debug: debug);
  }

  Future<io.ProcessResult> sendKeyCode(
    int keyCode, {
    KeyEventType? type,
    InputSource? inputSource,
    bool debug = false,
  }) async {
    final event = _makeKeyCode(keyCode, eventType: type, inputSource: inputSource);
    return await exec(event, debug: debug);
  }

  Future<Properties> listSettings(SettingsType type, {bool debug = false}) async {
    return exec(['settings', 'list', type.name], debug: debug).then((result) {
      return Properties.fromString(result.stdout.toString());
    });
  }

  Future<String> getSetting(SettingsType type, {required String key, bool debug = false}) async {
    return exec(['settings', 'get', type.name, key], debug: debug).then((result) {
      final value = result.stdout.toString().trim();
      if (value == 'null') {
        return '';
      }
      return value;
    });
  }

  Future<void> putSetting(SettingsType type, {required String key, required String value, bool debug = false}) async {
    await exec(['settings', 'put', type.name, key, value], debug: debug);
  }

  Future<void> deleteSetting(SettingsType type, {required String key, bool debug = false}) async {
    await exec(['settings', 'delete', type.name, key], debug: debug);
  }

  Future<bool> testFile(String path, String mode, {bool debug = false}) async {
    return exec(['test -$mode $path && echo 1 || echo 0'], debug: debug).then((result) {
      return result.stdout.toString().trim() == '1';
    });
  }

  Future<bool> exists(String path, {bool debug = false}) async {
    return testFile(path, 'e', debug: debug);
  }

  Future<bool> isFile(String path, {bool debug = false}) async {
    return testFile(path, 'f', debug: debug);
  }

  Future<bool> isDirectory(String path, {bool debug = false}) async {
    return testFile(path, 'd', debug: debug);
  }

  Future<bool> isSymLink(String path, {bool debug = false}) async {
    return testFile(path, 'h', debug: debug);
  }

  Future<io.ProcessResult> screencap(String path, {bool debug = false}) async {
    return await exec(['screencap', '-p', path], debug: debug);
  }

  Future<void> rm(String path, {List<String> args = const [], bool debug = false}) async {
    await exec(['rm', ...args, path], debug: debug);
  }

  Future<String> getProp(String key, {bool debug = false}) async {
    return exec(['getprop', key], debug: debug).then((result) {
      return result.stdout.toString().trim();
    });
  }

  Future<PropType> getPropType(String key, {bool debug = false}) async {
    final result = await exec(['getprop', '-T', key], debug: debug);
    final value = result.stdout.toString().trim();
    return PropType.fromString(value);
  }

  Future<Map<String, PropType>> getPropTypes({bool debug = false}) async {
    final result = await exec(['getprop', '-T'], debug: debug);
    final lines = result.stdout.toString().split('\n');
    final props = <String, PropType>{};
    for (final line in lines) {
      _kGetProps.allMatches(line).forEach((match) {
        props[match.group(1)!] = PropType.fromString(match.group(2)!);
      });
    }
    return props;
  }

  Future<Map<String, String>> getProps({bool debug = false}) async {
    return exec(['getprop'], debug: debug).then((result) {
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

  Future<void> setProp(String key, String value, {bool debug = false}) async {
    final newValue = value == "" ? '""' : value;
    await exec(['setprop', key, newValue], debug: debug);
  }

  Future<void> clearProp(String key, {bool debug = false}) async {
    await setProp(key, '', debug: debug);
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

  Future<SELinuxType> getEnforce({bool debug = false}) async {
    return exec(['getenforce'], debug: debug).then((result) {
      final value = result.stdout.toString().trim();
      return SELinuxType.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
    });
  }

  Future<void> setEnforce(SELinuxType type, {bool debug = false}) async {
    await exec(['setenforce', ...type.toArgs()], debug: debug);
  }

  Future<void> sendTap(Point<int> pos, {InputSource? inputSource, bool debug = false}) async {
    await exec(_makeTap(pos, inputSource: inputSource), debug: debug);
  }

  Future<void> sendEvent({
    required String event,
    required int codeType,
    required int code,
    required int value,
    bool debug = false,
  }) async {
    await exec(_makeEvent(event, codeType, code, value), debug: debug);
  }

  Future<void> sendText(String text, {InputSource? inputSource, bool debug = false}) async {
    await exec(_makeText(text, inputSource: inputSource), debug: debug);
  }

  Future<void> sendMotion(
    MotionEvent motion, {
    required Point<int> pos,
    InputSource? inputSource,
    bool debug = false,
  }) async {
    await exec(_makeMotion(motion, pos: pos, inputSource: inputSource), debug: debug);
  }

  Future<void> sendDragAndDrop({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
    bool debug = false,
  }) async {
    await exec(_makeDragAndDrop(inputSource: inputSource, duration: duration, start: start, end: end), debug: debug);
  }

  Future<void> sendPress({InputSource? inputSource, bool debug = false}) async {
    await exec(_makePress(inputSource), debug: debug);
  }

  Future<void> sendKeyEvents(List<KeyCode> events, {InputSource? inputSource, bool debug = false}) async {
    await exec(_makeKeyEvents(events, inputSource: inputSource), debug: debug);
  }

  Future<void> sendKeyCodes(List<int> keycodes, {InputSource? inputSource, bool debug = false}) async {
    await exec(_makeKeyCodes(keycodes, inputSource: inputSource), debug: debug);
  }

  Future<void> sendSwipe({
    InputSource? inputSource,
    Duration? duration,
    required Point<int> start,
    required Point<int> end,
    bool debug = false,
  }) async {
    await exec(_makeSwipe(inputSource: inputSource, duration: duration, start: start, end: end), debug: debug);
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
