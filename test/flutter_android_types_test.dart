import 'package:flutter_android_bridge/library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LogcatOptions.toArgs returns empty args with defaults', () {
    final options = LogcatOptions();

    expect(options.toArgs(), isEmpty);
  });

  test('LogcatOptions.toArgs builds expected adb logcat arguments', () {
    final since = DateTime(2026, 6, 24, 10, 14, 0, 116);
    final options = LogcatOptions(
      expr: 'ActivityManager',
      dump: true,
      filename: '/tmp/logcat.txt',
      tags: [LogcatTag.info('System.out'), LogcatTag.error('AndroidRuntime')],
      format: 'threadtime',
      since: since,
      pid: 1234,
    );

    expect(options.toArgs(), [
      '-e',
      'ActivityManager',
      '-d',
      '-f',
      '/tmp/logcat.txt',
      'System.out:I',
      'AndroidRuntime:E',
      '-s',
      '-v',
      'threadtime',
      '-T',
      '06-24 10:14:00.116',
      '--pid',
      '1234',
    ]);
  });
}
