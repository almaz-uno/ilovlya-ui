import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/app.dart';

void main() {
  Future<ScrollController> pumpList(WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: appScrollBehavior,
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (context, index) => SizedBox(height: 50, child: Text('item $index')),
          ),
        ),
      ),
    );
    return controller;
  }

  // A trackpad's two-finger scroll, and a Magic Mouse's one-finger scroll on
  // macOS, reach the framework as pan-zoom events of a trackpad.
  testWidgets('a trackpad pan-zoom gesture scrolls a list', (tester) async {
    final controller = await pumpList(tester);
    final center = tester.getCenter(find.byType(ListView));
    final pointer = TestPointer(1, PointerDeviceKind.trackpad);

    await tester.sendEventToBinding(pointer.panZoomStart(center));
    for (var i = 1; i <= 10; i++) {
      await tester.sendEventToBinding(pointer.panZoomUpdate(center, pan: Offset(0, -30.0 * i)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.sendEventToBinding(pointer.panZoomEnd());
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThanOrEqualTo(300));
  });

  testWidgets('a mouse drag still scrolls a list', (tester) async {
    final controller = await pumpList(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -300), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
  });
}
