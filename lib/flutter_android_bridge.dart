import 'package:flutter_android_bridge/executor.dart';
import 'package:flutter_android_bridge/flutter_android_client.dart';
import 'package:meta/meta.dart';

class FlutterAndroidBridge {
  @internal
  late final Executor executor;

  FlutterAndroidBridge(String adbPath, {bool debug = false}) {
    executor = Executor(adbPath: adbPath, debug: debug);
  }

  FlutterAndroidClient newClient(String address) {
    return FlutterAndroidClient(address, bridge: this);
  }

  Future<List<String>> listDevices() async {
    await executor.startServer();

    final result = await executor.execute(['devices'], runInShell: true);

    final lines =
        result.stdout.toString().split('\n')
          ..removeAt(0)
          ..removeWhere((element) => element.isEmpty);

    final devices = <String>[];
    for (final line in lines) {
      final parts = line.trim().split('\t');
      if (parts.isEmpty) {
        continue;
      }
      devices.add(parts[0]);
    }
    return devices;
  }
}
