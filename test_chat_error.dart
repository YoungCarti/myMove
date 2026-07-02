import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sort check', () {
    List<String> ids = ['Z', 'A'];
    ids.sort();
    print(ids.join('_'));
  });
}
