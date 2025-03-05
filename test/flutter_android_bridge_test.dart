import 'dart:isolate';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:flutter_android_bridge/library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:properties/properties.dart';

const _kAddress = '192.168.1.101:5555';

String get _kAdbPath {
  final userHome = Platform.environment['HOME'];
  return '$userHome/Library/Android/sdk/platform-tools/adb';
}

void main() {
  test('is connected', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient('192.168.1.112:5555');
    await expectLater(client.isConnected(), completion(false));
  });

  test('test read model', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient('192.168.1.101:5555');
    await expectLater(client.connect(), completion(true));
    final product = await client.shell().getProp('ro.build.product');
    final apiLevel = await client.shell().getProp('ro.build.version.sdk');
    print('product: $product');
    print('api level: $apiLevel');
    expect(product, isA<String>());
    expect(apiLevel, isA<String>());
  });

  test('test reboot', () async {
    final adb = FlutterAndroidBridge(_kAdbPath, debug: true);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.reboot(), completes);
  });

  test('test get wakefulness', () async {
    final adb = FlutterAndroidBridge(_kAdbPath, debug: true);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    final wakefulness = await client.getWakefulness();
    expect(wakefulness, isA<Wakefulness>());

    final isAwake = await client.isAwake();
    expect(isAwake, isA<bool>());
  });

  test('root and unroot', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);

    await expectLater(client.isConnected(), completes);

    await expectLater(client.connect(timeout: Duration(milliseconds: 500)), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.unroot(), completes);
    await expectLater(client.isRooted(), completion(false));
  });

  test('wait for device', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.waitForDevice(timeout: Duration(seconds: 1)), completes);
  });

  test('test shell cat', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));

    final result = await client.shell().cat('/sys/class/net/eth0/address');
    expect(result.exitCode, 0);

    final value = result.stdout.toString().trim();
    expect(value, isA<String>());

    print('mac address: $value');
    expect(value, isA<String>());
  });

  test('test shell exec', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));

    final result = await client.shell().exec(['scmuuid_test']);
    expect(result.exitCode, 0);

    final value = result.stdout.toString().trim();
    expect(value, isA<String>());

    print('device uuid: $value');
    expect(value, isA<String>());
  });

  test('list devices', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    await expectLater(adb.listDevices(), completion(isA<List<String>>()));
  });

  test('is connected', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final devices = await adb.listDevices();
    expect(devices, isA<List<String>>().having((l) => l.isNotEmpty, 'is not empty', true));

    final device = devices.first;

    final client = adb.newClient(device);

    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
  });

  test('start adb server', () {
    Executor executor = Executor(adbPath: _kAdbPath);
    expect(executor.startServer(), completes);
  });

  test(
    'kill adb server',
    () {
      Executor executor = Executor(adbPath: _kAdbPath);
      expect(executor.killServer(), completes);
    },
    onPlatform: {
      'android': Skip('This test is not supported on Android'),
      'ios': Skip('This test is not supported on iOS'),
    },
  );

  test('mount', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.shell().mount('/system'), completes);
    await expectLater(client.shell().unmount('/system'), completes);
  });

  test('get command', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.shell().command('ls'), completion(isA<String>()));
    await expectLater(client.shell().command('nonexistent'), throwsA(isA<AdbFileNotFoundExeption>()));
  });

  test('has avbctl', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().hasAvbctl(), completion(isA<bool>()));
  });

  test('which', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().which('ls'), completion(isA<String>()));
    await expectLater(client.shell().which('ls'), completion('/system/bin/ls'));
    await expectLater(client.shell().which('nonexistent'), throwsA(isA<AdbFileNotFoundExeption>()));
  });

  test('get verity', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().getVerityStatus(), completion(isA<bool>()));
  });

  test('is screen on', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().isScreenOn(), completion(isA<bool>()));
  });

  test('send key event', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.shell().sendKeyEvent(KeyCode.KEYCODE_HOME), completes);
  });

  test('send key code', () async {
    final char = 'a';
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.shell().sendKeyCode(char.codeUnits[0]), completes);
  });

  test('list settings', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    final globalProperties = client.shell().listSettings(SettingsType.global);
    await expectLater(globalProperties, completion(isA<Properties>()));
    expect(await globalProperties, isNotEmpty);
  });

  test('get setting key', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().getSetting(SettingsType.global, key: 'device_name'), completion(isA<String>()));
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'device_name'), completion(isNotEmpty));
  });

  test('put settings', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().putSetting(SettingsType.global, key: 'test', value: 'something'), completes);
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'test'), completion('something'));
  });

  test('delete setting', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().putSetting(SettingsType.global, key: 'test', value: 'something'), completes);
    await expectLater(client.shell().deleteSetting(SettingsType.global, key: 'test'), completes);
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'test'), completion(isEmpty));
  });

  test('file exists', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().exists('/system/bin/ls'), completion(true));
    await expectLater(client.shell().exists('/system/bin/nonexistent'), completion(false));
  });

  test('save screencap', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    final path = '/sdcard/Download/screencap.png';

    final result = await client.shell().screencap(path);
    expect(result.exitCode, 0);

    await expectLater(client.shell().exists(path), completion(true));
    await expectLater(client.shell().isFile(path), completion(true));
    await expectLater(client.shell().isDirectory(path), completion(false));
    await expectLater(client.shell().isSymLink(path), completion(false));
  });

  test('rm file', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);

    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    final path = '/sdcard/Download/screencap.png';

    final exists = await client.shell().isFile(path);
    if (exists) {
      await expectLater(client.shell().rm(path), completes);
    }
    await expectLater(client.shell().exists(path), completion(false));
  });

  test('get prop', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    await expectLater(client.shell().getProp('ro.product.model'), completion(isA<String>()));
    await expectLater(client.shell().getProp('ro.product.model'), completion(isNotEmpty));
  });

  test('get props', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final future = client.shell().getProps();
    await expectLater(future, completion(isA<Map<String, String>>()));
    await expectLater(future, completion(isNotEmpty));
  });

  test('set prop', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final key = 'test';
    final value = Random().nextInt(100).toString();

    await expectLater(client.shell().setProp(key, value), completes);
    await expectLater(client.shell().getProp(key), completion(value));

    await expectLater(client.shell().clearProp(key), completes);
    await expectLater(client.shell().getProp(key), completion(isEmpty));
  });

  test('am force stop', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.settings';
    await expectLater(client.shell().am().forceStop(packageName), completes);
  });

  test('am start', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final intent = FlutterAndroidIntent(
      action: 'com.example.action.EXAMPLE_ACTION',
      data: 'content://android.media.tv/content',
      package: 'com.example.app',
      extra: FlutterAndroidExtra(es: {'media': '/liveTv'}),
    );
    await expectLater(client.shell().am().start(intent), completes);
  });

  test('screen mirror', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final answer = ReceivePort();
    final sendPort = await client.shell().screenMirror(answer: answer);

    sendPort.send('start');

    Future.delayed(Duration(seconds: 10), () {
      sendPort.send('stop');
    });

    await answer.forEach((message) {
      print('message: $message');
      if (message == 'stopped') {
        answer.close();
      }
    });
  });

  test('pm path', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    final path = client.shell().pm().path(packageName);
    await expectLater(path, completion(isA<List<String>>()));
  });

  test('pm grant permission', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.camera';
    final permission = 'android.permission.ACCESS_FINE_LOCATION';
    await expectLater(client.shell().pm().grant(packageName, permission), completes);
  });

  test('pm revoke permission', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.camera';
    final permission = 'android.permission.ACCESS_FINE_LOCATION';
    await expectLater(client.shell().pm().revoke(packageName, permission), completes);
  });

  test('pm reset permissions', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    await expectLater(client.shell().pm().resetPermissions(packageName, user: '0'), completes);
  });

  test('pm list packages', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packages = await client.shell().pm().listPackages(
      displayOptions: ListPackageDisplayOptions(showUid: true, showVersionCode: true, showApkFile: false),
    );

    expect(packages, isA<List<dynamic>>());

    for (final package in packages) {
      expect(package, isA<Package>());
      print(package);
    }
  });

  test('pm is installed', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    final future = client.shell().pm().isInstalled(packageName);
    await expectLater(future, completion(isA<bool>()));
    await expectLater(future, completion(true));
  });

  test('pm clear', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    await expectLater(client.shell().pm().clear(packageName), completes);
  });

  test('get enforce', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    final enforce = client.shell().getEnforce();
    expect(enforce, completion(isA<SELinuxType>()));
  });

  test('set enforce', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.shell().setEnforce(SELinuxType.permissive), completes);
  });

  test('send tap', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.shell().sendTap(Point(50, 50)), completes);
  });

  test('sendEvent', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    final event = "/dev/input/event0";

    await expectLater(
      client.shell().sendEvent(event: event, codeType: 0x0001, code: 0x006a, value: 0x00000001),
      completes,
    );
  });

  test('send text', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    final char = 'a';
    await expectLater(client.shell().sendText(char), completes);
  });

  test('send motion event', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    await expectLater(client.shell().sendMotion(MotionEvent.DOWN, pos: Point(300, 50)), completes);
    await expectLater(client.shell().sendMotion(MotionEvent.UP, pos: Point(300, 50)), completes);
  });

  test('send drag and drop', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    await expectLater(
      client.shell().sendDragAndDrop(duration: Duration(seconds: 1), start: Point(0, 0), end: Point(1000, 1000)),
      completes,
    );
  });

  test('send press', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    await expectLater(client.shell().sendPress(inputSource: InputSource.keyboard), completes);
  });

  test('send key events', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));

    await expectLater(
      client.shell().sendKeyEvents([KeyCode.KEYCODE_DPAD_RIGHT, KeyCode.KEYCODE_DPAD_RIGHT]),
      completes,
    );
  });

  test('send key codes', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.shell().sendKeyCodes([1, 2, 3]), completes);
  });

  test('send swipe', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(
      client.shell().sendSwipe(duration: Duration(seconds: 1), start: Point(0, 500), end: Point(0, 0)),
      completes,
    );
  });

  test('get prop type', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);

    await expectLater(client.shell().getPropType('aaudio.mmap_policy'), completion(PropType.Int));
    await expectLater(client.shell().getPropType('apexd.status'), completion(PropType.Enum));
  });

  test('get prop types', () async {
    final adb = FlutterAndroidBridge(_kAdbPath);
    final client = adb.newClient(_kAddress);

    final types = client.shell().getPropTypes();
    await expectLater(types, completion(isA<Map<String, PropType>>()));
    await expectLater(types, completion(isNotEmpty));
  });
}
