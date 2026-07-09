import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/services/inventory_ffi_service.dart';
import 'package:inventory_app/services/native_contract.dart';

void main() {
  group('Native FFI contract', () {
    test('CItem size matches the packed C++ struct contract', () {
      expect(sizeOf<CItem>(), equals(kNativeCItemSize));
    });

    test('CRule size matches the packed C++ struct contract', () {
      expect(sizeOf<CRule>(), equals(kNativeCRuleSize));
    });

    test('FFI field lengths remain aligned with the Dart-side contract', () {
      expect(kNativeItemIdLen, equals(64));
      expect(kNativeBarcodeLen, equals(64));
      expect(kNativeNameLen, equals(256));
      expect(kNativeCategoryLen, equals(128));
      expect(kNativeDescriptionLen, equals(512));
    });

    test('Rule enum ordering stays stable for native matching', () {
      expect(MatchType.values.map((type) => type.index).toList(), [0, 1, 2, 3]);
    });
  });
}