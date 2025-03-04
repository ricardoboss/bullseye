import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  test('HTTP request', () async {
    final client = MockClient();

    when(client.get(any)).thenAnswer((_) async => http.Response('', 200));

    expect(await client.get(Uri.parse('https://example.com')), isNotNull);
  });
}
