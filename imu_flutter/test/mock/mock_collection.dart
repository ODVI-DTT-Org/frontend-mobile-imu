import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock implementation of ResultList from PocketBase
class MockResultList<T> extends Mock implements ResultList<T> {
  @override
  // ignore: We only need the for testing
  final List<T> items = [];

  @override
  List<T>? get resultList => null;
}
