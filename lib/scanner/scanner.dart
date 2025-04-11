import 'dart:async';
import 'dart:io';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';

part 'scanner.g.dart';

@CopyWith()
class IpAddressRange {
  final String cidr; // 192.168.1.100/31

  IpAddressRange(this.cidr) {
    final parts = cidr.split('/');
    if (parts.length != 2) {
      throw ArgumentError('Invalid CIDR format');
    }

    final ip = parts[0];
    final ipParts = ip.split('.');
    if (ipParts.length != 4) {
      throw ArgumentError('Invalid IP format');
    }

    for (final part in ipParts) {
      final int partInt = int.parse(part);
      if (partInt < 0 || partInt > 255) {
        throw ArgumentError('Invalid IP format');
      }
    }
  }

  List<String> getHosts() {
    final hosts = <String>[];
    final parts = cidr.split('/');
    final ip = parts[0];
    final mask = int.parse(parts[1]);
    final ipParts = ip.split('.');
    final total = 1 << (32 - mask);

    List<int> ipPartsInt = ipParts.map((e) => int.parse(e)).toList();

    int i = 0;
    while (true) {
      final String ip = '${ipPartsInt[0]}.${ipPartsInt[1]}.${ipPartsInt[2]}.${ipPartsInt[3]}';

      hosts.add(ip);
      i++;
      if (i == total) {
        break;
      }

      ipPartsInt[3]++;
      if (ipPartsInt[3] > 255) {
        ipPartsInt[3] = 0;

        for (int j = 2; j >= 0; j--) {
          ipPartsInt[j]++;
          if (ipPartsInt[j] <= 255) {
            break;
          }

          ipPartsInt[j] = 0;
        }
      }
    }

    return hosts;
  }
}

@CopyWith()
class ScanResult {
  final String host;
  final int port;
  final bool isOpen;

  ScanResult(this.host, this.port, this.isOpen);

  @override
  String toString() => 'Host: $host, Port: $port, Open: $isOpen';
}

class TcpScanner {
  final IpAddressRange hostRange;
  final Set<int> ports;
  final Duration timeout;
  final bool debug;
  final int? maxJobs;

  TcpScanner({
    required this.hostRange,
    required this.ports,
    this.timeout = const Duration(seconds: 1),
    this.debug = false,
    this.maxJobs,
  }) {
    if (ports.isEmpty) {
      throw ArgumentError('Ports list cannot be empty');
    }
  }

  Future<List<ScanResult>> scan() async {
    final results = <ScanResult>[];
    final hosts = hostRange.getHosts();

    if (debug) {
      debugPrint('Scanning ${hosts.length} hosts with ${ports.length} ports each');
      debugPrint('First ip: ${hosts.first}, Last ip: ${hosts.last}');
      debugPrint('----------------------------------------');
    }

    final cpus = maxJobs ?? (Platform.numberOfProcessors * 2);
    final pool = IsolatePool(cpus);
    await pool.start();

    final futures = <Future<ScanResult>>[];

    for (final host in hosts) {
      for (final port in ports) {
        futures.add(pool.scheduleJob<ScanResult>(ScanJob(host, port, timeout)));
      }
    }

    // Wait for all futures to complete and collect results
    for (final future in futures) {
      final result = await future;
      results.add(result);
      if (debug) {
        debugPrint('[${DateTime.now()}] scan result: ${result.toString()}');
      }
    }

    pool.stop();

    return results;
  }
}

class ScanJob extends PooledJob<ScanResult> {
  final String host;
  final int port;
  final Duration timeout;

  ScanJob(this.host, this.port, this.timeout);

  @override
  Future<ScanResult> job() async {
    return Socket.connect(host, port, timeout: timeout)
        .then((socket) {
          socket.destroy();
          return ScanResult(host, port, true);
        })
        .catchError((_) {
          return ScanResult(host, port, false);
        });
  }
}
