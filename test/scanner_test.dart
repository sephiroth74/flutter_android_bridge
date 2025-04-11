import 'package:flutter_android_bridge/scanner/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tcpScanner test', () async {
    final stopWatch = Stopwatch();
    final tcpScanner = TcpScanner(
      hostRange: IpAddressRange('192.168.1.0/24'),
      ports: {5555},
      timeout: Duration(milliseconds: 500),
      debug: true,
    );

    stopWatch.start();
    final results = await tcpScanner.scan();
    stopWatch.stop();

    print('Elapsed time: ${stopWatch.elapsedMilliseconds} ms');
    print('----------------------------------------');
    for (final result in results.where((result) => result.isOpen)) {
      print('Host: ${result.host}, Port: ${result.port}, Open: ${result.isOpen}');
    }
  });
}
