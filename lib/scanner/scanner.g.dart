// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IpAddressRangeCWProxy {
  IpAddressRange cidr(String cidr);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IpAddressRange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IpAddressRange(...).copyWith(id: 12, name: "My name")
  /// ````
  IpAddressRange call({String cidr});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIpAddressRange.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIpAddressRange.copyWith.fieldName(...)`
class _$IpAddressRangeCWProxyImpl implements _$IpAddressRangeCWProxy {
  const _$IpAddressRangeCWProxyImpl(this._value);

  final IpAddressRange _value;

  @override
  IpAddressRange cidr(String cidr) => this(cidr: cidr);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IpAddressRange(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IpAddressRange(...).copyWith(id: 12, name: "My name")
  /// ````
  IpAddressRange call({Object? cidr = const $CopyWithPlaceholder()}) {
    return IpAddressRange(
      cidr == const $CopyWithPlaceholder()
          ? _value.cidr
          // ignore: cast_nullable_to_non_nullable
          : cidr as String,
    );
  }
}

extension $IpAddressRangeCopyWith on IpAddressRange {
  /// Returns a callable class that can be used as follows: `instanceOfIpAddressRange.copyWith(...)` or like so:`instanceOfIpAddressRange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IpAddressRangeCWProxy get copyWith => _$IpAddressRangeCWProxyImpl(this);
}
