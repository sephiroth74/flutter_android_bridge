import 'dart:convert';
import 'dart:io';

import 'package:flutter_android_bridge/flutter_android_bridge.dart';
import 'package:flutter_android_bridge/flutter_android_shell.dart';
import 'package:flutter_android_bridge/library.dart';
import 'package:meta/meta.dart';

class FlutterAndroidClient {
  final Connection _connection;
  final FlutterAndroidBridge _bridge;

  @internal
  FlutterAndroidClient(String address, {required FlutterAndroidBridge bridge})
    : _connection = Connection(address),
      _bridge = bridge;

  /// Connects to the device.
  ///
  /// [timeout] is optional and can be used to specify the maximum time to wait.
  ///
  /// Returns true if the device is connected, false otherwise.
  Future<bool> connect({Duration? timeout}) async {
    await _bridge.executor.execute(['connect', _connection.address], timeout: timeout);
    return isConnected();
  }

  /// Waits for the device to be connected.
  ///
  /// [timeout] is optional and can be used to specify the maximum time to wait.
  ///
  Future<void> waitForDevice({Duration? timeout}) async {
    await _bridge.executor.execute([..._connection.arguments, 'wait-for-device'], timeout: timeout);
  }

  /// Checks if the device is connected.
  ///
  /// Returns true if the device is connected, false otherwise.
  Future<bool> isConnected() async {
    final result = await _bridge.executor.execute([..._connection.arguments, 'get-state'], checkIfRunning: false);
    if (result.exitCode != 0) {
      return false;
    }
    return result.stdout.toString().contains('device');
  }

  FlutterAndroidShell shell() {
    return FlutterAndroidShell(bridge: _bridge, connection: _connection);
  }

  /// Roots the connection with the device.
  ///
  Future<void> root() async {
    if (await isRooted()) {
      return;
    }
    return await _bridge.executor.root(_connection.arguments);
  }

  /// Unroots the connection with the device.
  ///
  Future<void> unroot() async {
    if (!await isRooted()) {
      return;
    }
    return await _bridge.executor.unroot(_connection.arguments);
  }

  /// Checks if the connection with the device is rooted.
  ///
  Future<bool> isRooted() async {
    return await _bridge.executor.isRooted(_connection.arguments);
  }

  /// Disconnects the device.
  ///
  Future<ProcessResult> disconnect() async {
    return await _bridge.executor.execute(['disconnect', _connection.address]);
  }

  /// Pushes a file from the host to the device.
  ///
  /// [src] is the path to the file on the device.
  /// [dst] is the path to the file on the host.
  ///
  Future<void> push({required String src, required String dst}) {
    return _bridge.executor.execute([..._connection.arguments, 'push', src, dst]);
  }

  /// Pulls a file from the device to the host.
  ///
  /// [src] is the path to the file on the device.
  /// [dst] is the path to the file on the host.
  ///
  Future<void> pull({required String src, required String dst}) {
    return _bridge.executor.execute([..._connection.arguments, 'pull', src, dst]);
  }

  /// Reboots the device.
  ///
  /// [rebootType] is optional and can be used to specify the type of reboot.
  ///
  Future<void> reboot({RebootType? rebootType}) async {
    final args = ['reboot'];
    if (rebootType != null) {
      args.add(rebootType.value);
    }
    await _bridge.executor.execute([..._connection.arguments, ...args]);
  }

  /// Installs an APK on the device.
  ///
  /// [apkPath] is the path to the APK file.
  /// [installOptions] is optional and can be used to specify additional options.
  ///
  /// Returns the result of the installation.
  Future<void> install({required String apkPath, AdbInstallOptions? installOptions}) async {
    final args = ['install'];
    if (installOptions != null) {
      args.addAll(installOptions.toArgs());
    }
    await _bridge.executor.execute([..._connection.arguments, ...args, apkPath]);
  }

  /// Uninstalls an APK from the device.
  ///
  /// [packageName] is the name of the package to uninstall.
  /// [options] is optional and can be used to specify additional options.
  ///
  /// Returns the result of the uninstallation.
  Future<void> uninstall({required String packageName, AdbUninstallOptions? options}) async {
    final args = ['uninstall'];
    if (options != null) {
      args.addAll(options.toArgs());
    }
    await _bridge.executor.execute([..._connection.arguments, ...args, packageName]);
  }

  Future<bool> isAwake() async {
    final wakefulness = await getWakefulness();
    return wakefulness != Wakefulness.Asleep;
  }

  Future<Wakefulness?> getWakefulness() async {
    final s1 = await _bridge.executor.execute([..._connection.arguments, 'shell', 'dumpsys', 'power']);

    final exitCode = await s1.exitCode;
    if (exitCode != 0) {
      return null;
    }

    final string = await s1.stdout.toString();
    final RegExp regex = RegExp(r'^\s*mWakefulness=([^\n]*)\s*$', multiLine: true);
    final match = regex.firstMatch(string);

    if (match == null) {
      return null;
    }

    final wakefulness = match.group(1);
    return wakefulness != null ? Wakefulness.fromString(wakefulness) : null;
  }
}

class Connection {
  final String address;
  const Connection(this.address);

  List<String> get arguments => ['-s', address];
}
