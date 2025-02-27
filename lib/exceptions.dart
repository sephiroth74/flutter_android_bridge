abstract class AdbException implements Exception {
  final dynamic message;

  const AdbException({required this.message});

  @override
  String toString() => '$runtimeType: $message';
}

class AdbNotFoundException extends AdbException {
  const AdbNotFoundException({required super.message});
}

class AdbDaemonNotRunningException extends AdbException {
  const AdbDaemonNotRunningException({required super.message});

  static const trigger = 'daemon not running; starting now at';
}

class AdbFileNotFoundExeption extends AdbException {
  const AdbFileNotFoundExeption(String command) : super(message: 'Command not found: $command');
}

class AvbctlNotInstalledException extends AdbException {
  const AvbctlNotInstalledException() : super(message: 'avbctl not found');
}
