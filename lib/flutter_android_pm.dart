///
/// Flutter Android Package Manager.
///
/// This file defines the `FlutterAndroidPackageManager` class, which provides various methods to interact with the Android package manager (`pm`) through a shell interface.
/// library: flutter_android_bridge
///
library;

import 'package:flutter_android_bridge/flutter_android_shell.dart';
import 'package:flutter_android_bridge/flutter_android_types.dart';
import 'package:meta/meta.dart';

RegExp _kListPackagesRegExp = RegExp(
  r'package:((?<file>.*\.apk)=)?(?<name>\S+)(\s(versionCode|uid):(\d+))?(\s(versionCode|uid):(\d+))?',
);

class FlutterAndroidPackageManager {
  final FlutterAndroidShell _shell;

  FlutterAndroidPackageManager._({required FlutterAndroidShell shell}) : _shell = shell;

  @internal
  factory FlutterAndroidPackageManager({required FlutterAndroidShell shell}) {
    return FlutterAndroidPackageManager._(shell: shell);
  }

  /// Get the path of the package with the given [packageName].
  ///
  /// If the package is not installed, an empty list is returned.
  ///
  /// If [user] is provided, the package path is retrieved for the specified user.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// final path = await pm.path('com.example.app');
  /// ```
  ///
  Future<List<String>> path(String packageName, {String? user}) async {
    final args = ['pm', 'path'];

    if (user != null) {
      args.addAll(['--user', user]);
    }

    args.add(packageName);

    final lines = await _shell.exec(args);
    final result = <String>[];

    lines.stdout.toString().split('\n').forEach((line) {
      if (line.startsWith('package:')) {
        result.add(line.substring(8).trim());
      }
    });

    return result;
  }

  /// grant the specified [permission] to the package with the given [packageName].
  ///
  /// If [user] is provided, the permission is granted to the specified user.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// await pm.grant('com.example.app', 'android.permission.CAMERA');
  /// ```
  ///
  Future<void> grant(String packageName, String permission, {String? user}) async {
    final args = ['pm', 'grant'];

    if (user != null) {
      args.addAll(['--user', user]);
    }

    args.addAll([packageName, permission]);
    await _shell.exec(args);
  }

  /// revoke the specified [permission] from the package with the given [packageName].
  ///
  /// If [user] is provided, the permission is revoked from the specified user.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// await pm.revoke('com.example.app', 'android.permission.CAMERA');
  /// ```
  ///
  Future<void> revoke(String packageName, String permission, {String? user}) async {
    final args = ['pm', 'revoke'];

    if (user != null) {
      args.addAll(['--user', user]);
    }

    args.addAll([packageName, permission]);
    await _shell.exec(args);
  }

  /// reset all permissions for the package with the given [packageName].
  ///
  /// If [user] is provided, the permissions are reset for the specified user.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// await pm.resetPermissions('com.example.app');
  /// ```
  ///
  Future<void> resetPermissions(String packageName, {String? user}) async {
    final args = ['pm', 'reset-permissions'];

    if (user != null) {
      args.addAll(['--user', user]);
    }

    args.add(packageName);
    await _shell.exec(args);
  }

  /// Get the list of packages installed on the device.
  ///
  /// The [filter] parameter can be used to filter the list of packages.
  ///
  /// The [displayOptions] parameter can be used to specify the display options for the list of packages.
  ///
  /// The [nameFilter] parameter can be used to filter the list of packages by name.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// final packages = await pm.listPackages();
  /// ```
  ///
  Future<List<Package>> listPackages({
    ListPackageFilter filter = const ListPackageFilter(),
    ListPackageDisplayOptions displayOptions = const ListPackageDisplayOptions(),
    String? nameFilter,
  }) async {
    final args = ['pm', 'list', 'packages'];
    args.addAll(filter.toArgs());
    args.addAll(displayOptions.toArgs());

    if (nameFilter != null) {
      args.add(nameFilter);
    }

    final lines = await _shell.exec(args);
    final result = <Package>[];

    lines.stdout.toString().split('\n').forEach((line) {
      final match = _kListPackagesRegExp.firstMatch(line);
      if (match != null && match.groupCount == 9) {
        final file = match.namedGroup('file');
        final name = match.namedGroup('name');
        int? versionCode;
        int? uid;

        if (match.group(5) == 'versionCode') {
          versionCode = int.parse(match.group(6)!);
          uid = int.parse(match.group(9)!);
        } else if (match.group(5) == 'uid') {
          uid = int.parse(match.group(6)!);
        }

        result.add(Package(packageName: name!, path: file, versionCode: versionCode, uid: uid));
      }
    });

    return result;
  }

  /// Check if the package with the given [packageName] is installed.
  Future<bool> isInstalled(String packageName) async {
    return path(packageName).then((value) => value.isNotEmpty).catchError((_) => false);
  }

  /// Clear the data of the package with the given [packageName].
  ///
  /// If [user] is provided, the data is cleared for the specified user.
  ///
  /// Throws an exception if the package manager command fails.
  ///
  /// Example:
  /// ```dart
  /// await pm.clear('com.example.app');
  /// ```
  Future<void> clear(String packageName, {String? user}) async {
    return _operation('clear', packageName: packageName, user: user);
  }

  Future<void> enable(String packageName, {String? user}) async {
    return _operation('enable', packageName: packageName, user: user);
  }

  Future<void> disable(String packageName, {String? user}) async {
    return _operation('disable', packageName: packageName, user: user);
  }

  Future<void> disableUser(String packageName, {String? user}) async {
    return _operation('disable-user', packageName: packageName, user: user);
  }

  Future<void> disableUntilUsed(String packageName, {String? user}) async {
    return _operation('disable-until-used', packageName: packageName, user: user);
  }

  Future<void> defaultState(String packageName, {String? user}) async {
    return _operation('default-state', packageName: packageName, user: user);
  }

  Future<void> unhide(String packageName, {String? user}) async {
    return _operation('unhide', packageName: packageName, user: user);
  }

  Future<void> hide(String packageName, {String? user}) async {
    return _operation('hide', packageName: packageName, user: user);
  }

  Future<void> suspend(String packageName, {String? user}) async {
    return _operation('suspend', packageName: packageName, user: user);
  }

  Future<void> unsuspend(String packageName, {String? user}) async {
    return _operation('unsuspend', packageName: packageName, user: user);
  }

  Future<void> _operation(String operation, {required String packageName, String? user}) async {
    final args = ['pm', operation];

    if (user != null) {
      args.addAll(['--user', user]);
    }

    args.add(packageName);
    await _shell.exec(args);
  }
}
