// ignore_for_file: constant_identifier_names

import 'package:copy_with_extension/copy_with_extension.dart';

part 'flutter_android_types.g.dart';

mixin ToArgs {
  List<String> toArgs();
}

@CopyWith()
class Package {
  final String packageName;
  final String? path;
  final int? versionCode;
  final int? uid;

  Package({required this.packageName, this.path, this.versionCode, this.uid});

  @override
  String toString() {
    return 'Package{packageName: $packageName, path: $path, versionCode: $versionCode, uid: $uid}';
  }
}

@CopyWith()
class ListPackageFilter with ToArgs {
  // -d: filter to only show disabled packages
  final bool showOnlyDisabled;
  // -e: filter to only show enabled packages
  final bool showOnlyEnabed;
  // -s: filter to only show system packages
  final bool showOnlySystem;
  // -3: filter to only show third party packages
  final bool showOnly3rdParty;
  // --apex-only: only show APEX packages
  final bool apexOnly;
  // --uid UID: filter to only show packages with the given UID
  final String? uid;
  // --user USER_ID: only list packages belonging to the given user
  final String? user;

  const ListPackageFilter({
    this.showOnlyDisabled = false,
    this.showOnlyEnabed = false,
    this.showOnlySystem = false,
    this.showOnly3rdParty = false,
    this.apexOnly = false,
    this.uid,
    this.user,
  });

  @override
  List<String> toArgs() {
    final args = <String>[];
    if (showOnlyDisabled) {
      args.add('-d');
    }

    if (showOnlyEnabed) {
      args.add('-e');
    }

    if (showOnlySystem) {
      args.add('-s');
    }

    if (showOnly3rdParty) {
      args.add('-3');
    }

    if (apexOnly) {
      args.add('--apex-only');
    }

    if (uid != null) {
      args.add('--uid');
      args.add(uid!);
    }

    if (user != null) {
      args.add('--user');
      args.add(user!);
    }

    return args;
  }
}

@CopyWith()
class FFPlayOptions with ToArgs {
  final int? framerate;
  final int? width;
  final int? height;
  final int? probesize;
  final String? logLevel;

  const FFPlayOptions({
    this.framerate = 30,
    this.width = 1440,
    this.height = 800,
    this.probesize = 300,
    this.logLevel = 'repeat+level+verbose',
  });

  @override
  List<String> toArgs() {
    final args = <String>['-an', '-autoexit', '-sync', 'video'];
    if (framerate != null) {
      args.add('-framerate');
      args.add(framerate.toString());
    }

    if (probesize != null) {
      args.add('-probesize');
      args.add(probesize.toString());
    }

    if (width != null && height != null) {
      args.add('-vf');
      args.add('scale=$width:$height');
    }

    if (logLevel != null) {
      args.add('-loglevel');
      args.add(logLevel!);
    }

    args.add('-');

    return args;
  }
}

@CopyWith()
class ListPackageDisplayOptions with ToArgs {
  // -U: also show the package UID
  final bool showUid;
  // --show-versioncode: also show the version code
  final bool showVersionCode;
  // -u: also include uninstalled packages
  final bool includeUninstalled;
  // -f: see their associated file
  final bool showApkFile;

  const ListPackageDisplayOptions({
    this.showUid = false,
    this.showVersionCode = false,
    this.includeUninstalled = false,
    this.showApkFile = false,
  });

  @override
  List<String> toArgs() {
    final args = <String>[];
    if (showUid) {
      args.add('-U');
    }

    if (showVersionCode) {
      args.add('--show-versioncode');
    }

    if (includeUninstalled) {
      args.add('-u');
    }

    if (showApkFile) {
      args.add('-f');
    }

    return args;
  }
}

@CopyWith()
class Size {
  final int width;
  final int height;

  Size(this.width, this.height);

  @override
  String toString() {
    return '$width:$height';
  }
}

@CopyWith()
class ScreenRecordOptions with ToArgs {
  /// --bit-rate 4000000
  /// Set the video bit rate, in bits per second. Value may be specified as bits or megabits, e.g. '4000000' is equivalent to '4M'.
  /// Default 20Mbps.
  final int? bitrate;

  /// --time-limit=120 (in seconds)
  /// Set the maximum recording time, in seconds. Default / maximum is 180
  final Duration? timelimit;

  /// --rotate
  /// Rotates the output 90 degrees. This feature is experimental.
  final bool? rotate;

  /// --bugreport
  /// Add additional information, such as a timestamp overlay, that is helpful in videos captured to illustrate bugs.
  final bool? bugReport;

  /// --size 1280x720
  /// Set the video size, e.g. "1280x720". Default is the device's main display resolution (if supported), 1280x720 if not.
  /// For best results, use a size supported by the AVC encoder.
  final Size? size;

  /// --verbose
  /// Display interesting information on stdout
  final bool? verbose;

  const ScreenRecordOptions({
    this.bitrate = 4_000_000,
    this.timelimit,
    this.rotate,
    this.bugReport,
    this.size,
    this.verbose,
  });

  @override
  List<String> toArgs() {
    final args = <String>[];
    if (bitrate != null) {
      args.add('--bit-rate');
      args.add(bitrate.toString());
    }

    if (timelimit != null) {
      args.add('--time-limit');
      args.add(timelimit!.inSeconds.toString());
    }

    if (rotate == true) {
      args.add('--rotate');
    }

    if (bugReport == true) {
      args.add('--bugreport');
    }

    if (size != null) {
      args.add('--size');
      args.add('${size!.width}x${size!.height}');
    }

    if (verbose == true) {
      args.add('--verbose');
    }

    args.add('--output-format=h264');

    return args;
  }
}

enum KeyEventType with ToArgs {
  longPress,
  doubleTap;

  @override
  List<String> toArgs() {
    switch (this) {
      case KeyEventType.longPress:
        return ['--longpress'];
      case KeyEventType.doubleTap:
        return ['--doubletap'];
    }
  }
}

enum KeyCode {
  KEYCODE_0,
  KEYCODE_11,
  KEYCODE_12,
  KEYCODE_1,
  KEYCODE_2,
  KEYCODE_3,
  KEYCODE_3D_MODE,
  KEYCODE_4,
  KEYCODE_5,
  KEYCODE_6,
  KEYCODE_7,
  KEYCODE_8,
  KEYCODE_9,
  KEYCODE_A,
  KEYCODE_ALL_APPS,
  KEYCODE_ALT_LEFT,
  KEYCODE_ALT_RIGHT,
  KEYCODE_APOSTROPHE,
  KEYCODE_APP_SWITCH,
  KEYCODE_ASSIST,
  KEYCODE_AT,
  KEYCODE_AVR_INPUT,
  KEYCODE_AVR_POWER,
  KEYCODE_B,
  KEYCODE_BACK,
  KEYCODE_BACKSLASH,
  KEYCODE_BOOKMARK,
  KEYCODE_BREAK,
  KEYCODE_BRIGHTNESS_DOWN,
  KEYCODE_BRIGHTNESS_UP,
  KEYCODE_BUTTON_10,
  KEYCODE_BUTTON_11,
  KEYCODE_BUTTON_12,
  KEYCODE_BUTTON_13,
  KEYCODE_BUTTON_14,
  KEYCODE_BUTTON_15,
  KEYCODE_BUTTON_16,
  KEYCODE_BUTTON_1,
  KEYCODE_BUTTON_2,
  KEYCODE_BUTTON_3,
  KEYCODE_BUTTON_4,
  KEYCODE_BUTTON_5,
  KEYCODE_BUTTON_6,
  KEYCODE_BUTTON_7,
  KEYCODE_BUTTON_8,
  KEYCODE_BUTTON_9,
  KEYCODE_BUTTON_A,
  KEYCODE_BUTTON_B,
  KEYCODE_BUTTON_C,
  KEYCODE_BUTTON_L1,
  KEYCODE_BUTTON_L2,
  KEYCODE_BUTTON_MODE,
  KEYCODE_BUTTON_R1,
  KEYCODE_BUTTON_R2,
  KEYCODE_BUTTON_SELECT,
  KEYCODE_BUTTON_START,
  KEYCODE_BUTTON_THUMBL,
  KEYCODE_BUTTON_THUMBR,
  KEYCODE_BUTTON_X,
  KEYCODE_BUTTON_Y,
  KEYCODE_BUTTON_Z,
  KEYCODE_C,
  KEYCODE_CALCULATOR,
  KEYCODE_CALENDAR,
  KEYCODE_CALL,
  KEYCODE_CAMERA,
  KEYCODE_CAPS_LOCK,
  KEYCODE_CAPTIONS,
  KEYCODE_CHANNEL_DOWN,
  KEYCODE_CHANNEL_UP,
  KEYCODE_CLEAR,
  KEYCODE_COMMA,
  KEYCODE_CONTACTS,
  KEYCODE_COPY,
  KEYCODE_CTRL_LEFT,
  KEYCODE_CTRL_RIGHT,
  KEYCODE_CUT,
  KEYCODE_D,
  KEYCODE_DEL,
  KEYCODE_DPAD_CENTER,
  KEYCODE_DPAD_DOWN,
  KEYCODE_DPAD_DOWN_LEFT,
  KEYCODE_DPAD_DOWN_RIGHT,
  KEYCODE_DPAD_LEFT,
  KEYCODE_DPAD_RIGHT,
  KEYCODE_DPAD_UP,
  KEYCODE_DPAD_UP_LEFT,
  KEYCODE_DPAD_UP_RIGHT,
  KEYCODE_DVR,
  KEYCODE_E,
  KEYCODE_EISU,
  KEYCODE_ENDCALL,
  KEYCODE_ENTER,
  KEYCODE_ENVELOPE,
  KEYCODE_EQUALS,
  KEYCODE_ESCAPE,
  KEYCODE_EXPLORER,
  KEYCODE_F10,
  KEYCODE_F11,
  KEYCODE_F12,
  KEYCODE_F1,
  KEYCODE_F2,
  KEYCODE_F3,
  KEYCODE_F4,
  KEYCODE_F5,
  KEYCODE_F6,
  KEYCODE_F7,
  KEYCODE_F8,
  KEYCODE_F9,
  KEYCODE_F,
  KEYCODE_FOCUS,
  KEYCODE_FORWARD,
  KEYCODE_FORWARD_DEL,
  KEYCODE_FUNCTION,
  KEYCODE_G,
  KEYCODE_GRAVE,
  KEYCODE_GUIDE,
  KEYCODE_H,
  KEYCODE_HEADSETHOOK,
  KEYCODE_HELP,
  KEYCODE_HENKAN,
  KEYCODE_HOME,
  KEYCODE_I,
  KEYCODE_INFO,
  KEYCODE_INSERT,
  KEYCODE_J,
  KEYCODE_K,
  KEYCODE_KANA,
  KEYCODE_KATAKANA_HIRAGANA,
  KEYCODE_L,
  KEYCODE_LANGUAGE_SWITCH,
  KEYCODE_LAST_CHANNEL,
  KEYCODE_LEFT_BRACKET,
  KEYCODE_M,
  KEYCODE_MANNER_MODE,
  KEYCODE_MEDIA_AUDIO_TRACK,
  KEYCODE_MEDIA_CLOSE,
  KEYCODE_MEDIA_EJECT,
  KEYCODE_MEDIA_FAST_FORWARD,
  KEYCODE_MEDIA_NEXT,
  KEYCODE_MEDIA_PAUSE,
  KEYCODE_MEDIA_PLAY,
  KEYCODE_MEDIA_PLAY_PAUSE,
  KEYCODE_MEDIA_PREVIOUS,
  KEYCODE_MEDIA_RECORD,
  KEYCODE_MEDIA_REWIND,
  KEYCODE_FAST_FORWARD,
  KEYCODE_MEDIA_SKIP_BACKWARD,
  KEYCODE_MEDIA_SKIP_FORWARD,
  KEYCODE_MEDIA_STEP_BACKWARD,
  KEYCODE_MEDIA_STEP_FORWARD,
  KEYCODE_MEDIA_STOP,
  KEYCODE_MEDIA_TOP_MENU,
  KEYCODE_MENU,
  KEYCODE_META_LEFT,
  KEYCODE_META_RIGHT,
  KEYCODE_MINUS,
  KEYCODE_MOVE_END,
  KEYCODE_MOVE_HOME,
  KEYCODE_MUHENKAN,
  KEYCODE_MUSIC,
  KEYCODE_MUTE,
  KEYCODE_N,
  KEYCODE_NAVIGATE_IN,
  KEYCODE_NAVIGATE_NEXT,
  KEYCODE_NAVIGATE_OUT,
  KEYCODE_NAVIGATE_PREVIOUS,
  KEYCODE_NOTIFICATION,
  KEYCODE_NUM,
  KEYCODE_NUM_LOCK,
  KEYCODE_NUMPAD_0,
  KEYCODE_NUMPAD_1,
  KEYCODE_NUMPAD_2,
  KEYCODE_NUMPAD_3,
  KEYCODE_NUMPAD_4,
  KEYCODE_NUMPAD_5,
  KEYCODE_NUMPAD_6,
  KEYCODE_NUMPAD_7,
  KEYCODE_NUMPAD_8,
  KEYCODE_NUMPAD_9,
  KEYCODE_NUMPAD_ADD,
  KEYCODE_NUMPAD_COMMA,
  KEYCODE_NUMPAD_DIVIDE,
  KEYCODE_NUMPAD_DOT,
  KEYCODE_NUMPAD_ENTER,
  KEYCODE_NUMPAD_EQUALS,
  KEYCODE_NUMPAD_LEFT_PAREN,
  KEYCODE_NUMPAD_MULTIPLY,
  KEYCODE_NUMPAD_RIGHT_PAREN,
  KEYCODE_NUMPAD_SUBTRACT,
  KEYCODE_O,
  KEYCODE_P,
  KEYCODE_PAGE_DOWN,
  KEYCODE_PAGE_UP,
  KEYCODE_PAIRING,
  KEYCODE_PASTE,
  KEYCODE_PERIOD,
  KEYCODE_PICTSYMBOLS,
  KEYCODE_PLUS,
  KEYCODE_POUND,
  KEYCODE_POWER,
  KEYCODE_PROFILE_SWITCH,
  KEYCODE_PROG_BLUE,
  KEYCODE_PROG_GREEN,
  KEYCODE_PROG_RED,
  KEYCODE_PROG_YELLOW,
  KEYCODE_Q,
  KEYCODE_R,
  KEYCODE_REFRESH,
  KEYCODE_RIGHT_BRACKET,
  KEYCODE_RO,
  KEYCODE_S,
  KEYCODE_SCROLL_LOCK,
  KEYCODE_SEARCH,
  KEYCODE_SEMICOLON,
  KEYCODE_SETTINGS,
  KEYCODE_SHIFT_LEFT,
  KEYCODE_SHIFT_RIGHT,
  KEYCODE_SLASH,
  KEYCODE_SLEEP,
  KEYCODE_SOFT_LEFT,
  KEYCODE_SOFT_RIGHT,
  KEYCODE_SOFT_SLEEP,
  KEYCODE_SPACE,
  KEYCODE_STAR,
  KEYCODE_STB_INPUT,
  KEYCODE_STB_POWER,
  KEYCODE_STEM_1,
  KEYCODE_STEM_2,
  KEYCODE_STEM_3,
  KEYCODE_STEM_PRIMARY,
  KEYCODE_SWITCH_CHARSET,
  KEYCODE_SYM,
  KEYCODE_SYSRQ,
  KEYCODE_SYSTEM_NAVIGATION_DOWN,
  KEYCODE_SYSTEM_NAVIGATION_LEFT,
  KEYCODE_SYSTEM_NAVIGATION_RIGHT,
  KEYCODE_SYSTEM_NAVIGATION_UP,
  KEYCODE_T,
  KEYCODE_TAB,
  KEYCODE_THUMBS_DOWN,
  KEYCODE_THUMBS_UP,
  KEYCODE_TV,
  KEYCODE_TV_ANTENNA_CABLE,
  KEYCODE_TV_AUDIO_DESCRIPTION,
  KEYCODE_TV_AUDIO_DESCRIPTION_MIX_DOWN,
  KEYCODE_TV_AUDIO_DESCRIPTION_MIX_UP,
  KEYCODE_TV_CONTENTS_MENU,
  KEYCODE_TV_DATA_SERVICE,
  KEYCODE_TV_INPUT,
  KEYCODE_TV_INPUT_COMPONENT_1,
  KEYCODE_TV_INPUT_COMPONENT_2,
  KEYCODE_TV_INPUT_COMPOSITE_1,
  KEYCODE_TV_INPUT_COMPOSITE_2,
  KEYCODE_TV_INPUT_HDMI_1,
  KEYCODE_TV_INPUT_HDMI_2,
  KEYCODE_TV_INPUT_HDMI_3,
  KEYCODE_TV_INPUT_HDMI_4,
  KEYCODE_TV_INPUT_VGA_1,
  KEYCODE_TV_MEDIA_CONTEXT_MENU,
  KEYCODE_TV_NETWORK,
  KEYCODE_TV_NUMBER_ENTRY,
  KEYCODE_TV_POWER,
  KEYCODE_TV_RADIO_SERVICE,
  KEYCODE_TV_SATELLITE,
  KEYCODE_TV_SATELLITE_BS,
  KEYCODE_TV_SATELLITE_CS,
  KEYCODE_TV_SATELLITE_SERVICE,
  KEYCODE_TV_TELETEXT,
  KEYCODE_TV_TERRESTRIAL_ANALOG,
  KEYCODE_TV_TERRESTRIAL_DIGITAL,
  KEYCODE_TV_TIMER_PROGRAMMING,
  KEYCODE_TV_ZOOM_MODE,
  KEYCODE_U,
  KEYCODE_UNKNOWN,
  KEYCODE_V,
  KEYCODE_VOICE_ASSIST,
  KEYCODE_VOLUME_DOWN,
  KEYCODE_VOLUME_MUTE,
  KEYCODE_VOLUME_UP,
  KEYCODE_W,
  KEYCODE_WAKEUP,
  KEYCODE_WINDOW,
  KEYCODE_X,
  KEYCODE_Y,
  KEYCODE_YEN,
  KEYCODE_Z,
  KEYCODE_ZENKAKU_HANKAKU,
  KEYCODE_ZOOM_IN,
  KEYCODE_ZOOM_OUT,
}

enum InputSource { dpad, keyboard, mouse, touchpad, gamepad, touchnavigation, joystick, touchscreen, stylus, trackball }

enum SettingsType { global, system, secure }

enum SELinuxType with ToArgs {
  enforcing,
  permissive;

  @override
  List<String> toArgs() {
    switch (this) {
      case SELinuxType.enforcing:
        return ['1'];
      case SELinuxType.permissive:
        return ['0'];
    }
  }
}

enum MotionEvent { DOWN, UP, MOVE, CANCEL }

RegExp _kPropType = RegExp(r"^enum\s((?:[\w_]+\s?)+)$");

enum PropType {
  String,
  Bool,
  Int,
  Enum,
  Unknown;

  static PropType fromString(dynamic value) {
    switch (value) {
      case 'string':
        return PropType.String;
      case 'bool':
        return PropType.Bool;
      case 'int':
        return PropType.Int;
      default:
        final match = _kPropType.firstMatch(value);
        if (match != null) {
          // final strings = match.group(1)!;
          // final s = strings.split(' ');
          return PropType.Enum;
        }
        return PropType.Unknown;
    }
  }
}

enum RebootType {
  Bootloader('bootloader'),
  Recovery('recovery'),
  Sideload('sideload'),
  SideloadAutoReboot('sideload-auto-reboot'),
  Dra('dra');

  final String value;

  const RebootType(this.value);
}

@CopyWith()
class AdbInstallOptions with ToArgs {
  // -d: allow version code downgrade
  final bool allowVersionDowngrade;
  // -t: allow test packages
  final bool allowTestPackage;
  // -r: replace existing application
  final bool replace;
  // -l: forward lock the app
  final bool forwardLock;
  // -s: Install on SD card instead of internal storage
  final bool installOnSDCard;
  // -g: grant all runtime permissions
  final bool grantPermissions;
  // --instant: Cause the app to be installed as an ephemeral install app
  final bool instant;

  const AdbInstallOptions({
    this.allowVersionDowngrade = false,
    this.allowTestPackage = false,
    this.replace = false,
    this.forwardLock = false,
    this.installOnSDCard = false,
    this.grantPermissions = false,
    this.instant = false,
  });

  @override
  List<String> toArgs() {
    final args = <String>[];
    if (allowVersionDowngrade) {
      args.add('-d');
    }

    if (allowTestPackage) {
      args.add('-t');
    }

    if (replace) {
      args.add('-r');
    }

    if (forwardLock) {
      args.add('-l');
    }

    if (installOnSDCard) {
      args.add('-s');
    }

    if (grantPermissions) {
      args.add('-g');
    }

    if (instant) {
      args.add('--instant');
    }

    return args;
  }
}

@CopyWith()
class AdbUninstallOptions with ToArgs {
  // -k
  final bool keepData;
  // --user
  final String? user;
  // --versionCode
  final int? versionCode;

  AdbUninstallOptions({required this.keepData, required this.user, required this.versionCode});

  @override
  List<String> toArgs() {
    final args = <String>[];
    if (keepData) {
      args.add('-k');
    }

    if (user != null) {
      args.add('--user');
      args.add(user!);
    }

    if (versionCode != null) {
      args.add('--versionCode');
      args.add(versionCode.toString());
    }

    return args;
  }
}

enum Wakefulness {
  Awake,
  Asleep,
  Dreaming;

  static Wakefulness? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'awake':
        return Wakefulness.Awake;
      case 'asleep':
        return Wakefulness.Asleep;
      case 'dreaming':
        return Wakefulness.Dreaming;
      default:
        return null;
    }
  }
}
