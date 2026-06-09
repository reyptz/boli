import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boli/core/widgets/offline_banner.dart';

void main() {
  testWidgets('OfflineBannerWrapper renders child widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflineBannerWrapper(
            child: Text('Boli Content'),
          ),
        ),
      ),
    );

    expect(find.text('Boli Content'), findsOneWidget);
  });
}
