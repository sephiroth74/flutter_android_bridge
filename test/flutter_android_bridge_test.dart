import 'dart:isolate';
import 'dart:math';

import 'package:flutter_android_bridge/exceptions.dart';
import 'package:flutter_android_bridge/executor.dart';
import 'package:flutter_android_bridge/flutter_android_bridge.dart';
import 'package:flutter_android_bridge/flutter_android_intent.dart';
import 'package:flutter_android_bridge/flutter_android_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:properties/properties.dart';

const _kAddress = '192.168.1.101:5555';

void main() {
  test('init', () {
    FlutterAndroidBridge flutterAndroidBridge = FlutterAndroidBridge();
    // flutterAndroidBridge.init should not throw an exception
    expect(flutterAndroidBridge.init(), completes);
  });

  test('root and unroot', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);

    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.unroot(), completes);
    await expectLater(client.isRooted(), completion(false));
  });

  test('test shell cat', () async {
    final adb = FlutterAndroidBridge();
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

    final result2 = await client.shell().cat('/timeshift/conf/tvlib-aot-client.properties');
    expect(result2.exitCode, 0);

    final value2 = result2.stdout.toString().trim();
    print('tvlib-aot-client.properties: $value2');
  });

  test('test shell exec', () async {
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
    await expectLater(adb.listDevices(), completion(isA<List<String>>()));
  });

  test('is connected', () async {
    final adb = FlutterAndroidBridge();
    final devices = await adb.listDevices();
    expect(devices, isA<List<String>>().having((l) => l.isNotEmpty, 'is not empty', true));

    final device = devices.first;

    final client = adb.newClient(device);

    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
  });

  test('check adb', () {
    Executor executor = Executor();
    expect(executor.init(), completes);
  });

  test('start adb server', () {
    Executor executor = Executor();
    expect(executor.startServer(), completes);
  });

  test(
    'kill adb server',
    () {
      Executor executor = Executor();
      expect(executor.killServer(), completes);
    },
    onPlatform: {
      'android': Skip('This test is not supported on Android'),
      'ios': Skip('This test is not supported on iOS'),
    },
  );

  test('mount', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.shell().mount('/system'), completes);
    await expectLater(client.shell().unmount('/system'), completes);
  });

  test('get command', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.isRooted(), completion(true));
    await expectLater(client.shell().command('ls'), completion(isA<String>()));
    await expectLater(client.shell().command('nonexistent'), throwsA(isA<AdbFileNotFoundExeption>()));
  });

  test('has avbctl', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().hasAvbctl(), completion(isA<bool>()));
  });

  test('which', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().which('ls'), completion(isA<String>()));
    await expectLater(client.shell().which('ls'), completion('/system/bin/ls'));
    await expectLater(client.shell().which('nonexistent'), throwsA(isA<AdbFileNotFoundExeption>()));
  });

  test('get verity', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().getVerityStatus(), completion(isA<bool>()));
  });

  test('is screen on', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);
    await expectLater(client.shell().isScreenOn(), completion(isA<bool>()));
  });

  test('send key event', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.shell().sendKeyEvent(KeyCode.KEYCODE_HOME), completes);
  });

  test('send key code', () async {
    final char = 'a';
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.shell().sendKeyCode(char.codeUnits[0]), completes);
  });

  test('list settings', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    final globalProperties = client.shell().listSettings(SettingsType.global);
    await expectLater(globalProperties, completion(isA<Properties>()));
    expect(await globalProperties, isNotEmpty);
  });

  test('get setting key', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().getSetting(SettingsType.global, key: 'device_name'), completion(isA<String>()));
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'device_name'), completion(isNotEmpty));
  });

  test('put settings', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().putSetting(SettingsType.global, key: 'test', value: 'something'), completes);
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'test'), completion('something'));
  });

  test('delete setting', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().putSetting(SettingsType.global, key: 'test', value: 'something'), completes);
    await expectLater(client.shell().deleteSetting(SettingsType.global, key: 'test'), completes);
    await expectLater(client.shell().getSetting(SettingsType.global, key: 'test'), completion(isEmpty));
  });

  test('file exists', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));
    await expectLater(client.root(), completes);

    await expectLater(client.shell().exists('/system/bin/ls'), completion(true));
    await expectLater(client.shell().exists('/system/bin/nonexistent'), completion(false));
  });

  test('save screencap', () async {
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    await expectLater(client.shell().getProp('ro.product.model'), completion(isA<String>()));
    await expectLater(client.shell().getProp('ro.product.model'), completion(isNotEmpty));
  });

  test('get props', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final future = client.shell().getProps();
    await expectLater(future, completion(isA<Map<String, String>>()));
    await expectLater(future, completion(isNotEmpty));
  });

  test('set prop', () async {
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.settings';
    await expectLater(client.shell().am().forceStop(packageName), completes);
  });

  test('am start', () async {
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    final path = client.shell().pm().path(packageName);
    await expectLater(path, completion(isA<List<String>>()));
  });

  test('pm grant permission', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.camera';
    final permission = 'android.permission.ACCESS_FINE_LOCATION';
    await expectLater(client.shell().pm().grant(packageName, permission), completes);
  });

  test('pm revoke permission', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.camera';
    final permission = 'android.permission.ACCESS_FINE_LOCATION';
    await expectLater(client.shell().pm().revoke(packageName, permission), completes);
  });

  test('pm reset permissions', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    await expectLater(client.shell().pm().resetPermissions(packageName, user: '0'), completes);
  });

  test('pm list packages', () async {
    final adb = FlutterAndroidBridge();
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
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    final future = client.shell().pm().isInstalled(packageName);
    await expectLater(future, completion(isA<bool>()));
    await expectLater(future, completion(true));
  });

  test('pm clear', () async {
    final adb = FlutterAndroidBridge();
    final client = adb.newClient(_kAddress);
    await expectLater(client.connect(), completion(true));
    await expectLater(client.isConnected(), completion(true));

    final packageName = 'com.android.wifi';
    await expectLater(client.shell().pm().clear(packageName), completes);
  });
}
