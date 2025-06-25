// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video360viewer/main.dart';

void main() {
  testWidgets('360 Video Viewer app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Video360ViewerApp());

    // Verify that the app title appears.
    expect(find.text('360° Video Viewer'), findsOneWidget);
    
    // Verify that the floating action button is present.
    expect(find.text('اختر فيديو 360°'), findsOneWidget);
    
    // Verify that the button icon is present.
    expect(find.byIcon(Icons.video_library), findsOneWidget);
  });
}
