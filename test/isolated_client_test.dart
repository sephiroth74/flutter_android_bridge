import 'dart:math';

import 'package:flutter_android_bridge/isolated_client.dart';
import 'package:flutter_android_bridge/library.dart';
import 'package:flutter_test/flutter_test.dart';

const _kAddress = '192.168.1.101:5555';

void main() {
  test('test connect', () async {
    final worker = await Worker.spawn(FlutterAndroidBridge().newClient(_kAddress));
    print(await worker.connect());
    worker.close();    
  });
}
