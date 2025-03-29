import 'package:copy_with_extension/copy_with_extension.dart';

part 'flutter_android_intent.g.dart';

@CopyWith()
class FlutterAndroidIntent {
  final String? action;
  final String? data;
  final String? mimeType;
  final String? category;
  final String? component;
  final String? package;
  final String? userId;
  final int? flags;
  final bool? receiverForeground;
  final bool? wait;
  final FlutterAndroidExtra extra;

  FlutterAndroidIntent({
    this.action,
    this.data,
    this.mimeType,
    this.category,
    this.component,
    this.package,
    this.userId,
    this.flags,
    this.receiverForeground,
    this.wait,
    this.extra = const FlutterAndroidExtra(),
  });

  factory FlutterAndroidIntent.action(String action) {
    return FlutterAndroidIntent(action: action);
  }

  List<String> asArguments() {
    final List<String> args = [];
    if (action != null) {
      args.add('-a');
      args.add(action!);
    }
    if (data != null) {
      args.add('-d');
      args.add(data!);
    }
    if (mimeType != null) {
      args.add('-t');
      args.add(mimeType!);
    }
    if (category != null) {
      args.add('-c');
      args.add(category!);
    }
    if (component != null) {
      args.add('-n');
      args.add(component!);
    }
    if (package != null) {
      args.add('-p');
      args.add(package!);
    }
    if (userId != null) {
      args.add('--user');
      args.add(userId!);
    }
    if (flags != null) {
      args.add('--flags');
      args.add(flags.toString());
    }
    if (receiverForeground != null) {
      args.add('--receiver-foreground');
    }
    if (wait != null) {
      args.add('-W');
    }
    args.addAll(extra.asArguments());
    return args;
  }
}

@CopyWith()
class FlutterAndroidExtra {
  final Map<String, String> es;
  final Map<String, bool> ez;
  final Map<String, int> ei;
  final Map<String, int> el;
  final Map<String, double> ef;
  final Map<String, String> eu;
  final Map<String, String> ecn;
  final Map<String, List<int>> eia;
  final Map<String, List<int>> ela;
  final Map<String, List<double>> efa;
  final Map<String, List<String>> esa;
  final bool grantReadUriPermission;
  final bool grantWriteUriPermission;
  final bool excludeStoppedPackages;
  final bool includeStoppedPackages;

  const FlutterAndroidExtra({
    this.es = const <String, String>{},
    this.ez = const <String, bool>{},
    this.ei = const <String, int>{},
    this.el = const <String, int>{},
    this.ef = const <String, double>{},
    this.eu = const <String, String>{},
    this.ecn = const <String, String>{},
    this.eia = const <String, List<int>>{},
    this.ela = const <String, List<int>>{},
    this.efa = const <String, List<double>>{},
    this.esa = const <String, List<String>>{},
    this.grantReadUriPermission = false,
    this.grantWriteUriPermission = false,
    this.excludeStoppedPackages = false,
    this.includeStoppedPackages = false,
  });

  putString(String key, String value) {
    es[key] = value;
  }

  pubBool(String key, bool value) {
    ez[key] = value;
  }

  putInt(String key, int value) {
    ei[key] = value;
  }

  putLong(String key, int value) {
    el[key] = value;
  }

  putFloat(String key, double value) {
    ef[key] = value;
  }

  putStringArray(String key, List<String> value) {
    esa[key] = value;
  }

  putIntArray(String key, List<int> value) {
    eia[key] = value;
  }

  putLongArray(String key, List<int> value) {
    ela[key] = value;
  }

  putFloatArray(String key, List<double> value) {
    efa[key] = value;
  }

  List<String> asArguments() {
    final List<String> args = [];
    es.forEach((key, value) {
      args.add('--es');
      args.add(key);
      args.add(value);
    });
    ez.forEach((key, value) {
      args.add('--ez');
      args.add(key);
      args.add(value.toString());
    });
    ei.forEach((key, value) {
      args.add('--ei');
      args.add(key);
      args.add(value.toString());
    });
    el.forEach((key, value) {
      args.add('--el');
      args.add(key);
      args.add(value.toString());
    });
    ef.forEach((key, value) {
      args.add('--ef');
      args.add(key);
      args.add(value.toString());
    });
    eu.forEach((key, value) {
      args.add('--eu');
      args.add(key);
      args.add(value);
    });
    ecn.forEach((key, value) {
      args.add('--ecn');
      args.add(key);
      args.add(value);
    });
    esa.forEach((key, value) {
      args.add('--esa');
      args.add(key);
      args.add(value.join(','));
    });
    eia.forEach((key, value) {
      args.add('--eia');
      args.add(key);
      args.add(value.join(','));
    });
    ela.forEach((key, value) {
      args.add('--ela');
      args.add(key);
      args.add(value.join(','));
    });
    efa.forEach((key, value) {
      args.add('--efa');
      args.add(key);
      args.add(value.join(','));
    });
    if (grantReadUriPermission) {
      args.add('--grant-read-uri-permission');
    }
    if (grantWriteUriPermission) {
      args.add('--grant-write-uri-permission');
    }
    if (excludeStoppedPackages) {
      args.add('--exclude-stopped-packages');
    }
    if (includeStoppedPackages) {
      args.add('--include-stopped-packages');
    }
    return args;
  }

  @override
  String toString() {
    return 'FlutterAndroidExtra{es: $es, ez: $ez, ei: $ei, el: $el, ef: $ef, eu: $eu, ecn: $ecn, eia: $eia, ela: $ela, efa: $efa, esa: $esa}';
  }
}
