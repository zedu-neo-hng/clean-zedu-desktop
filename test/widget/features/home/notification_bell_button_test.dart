import 'dart:ui' as ui;
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../helpers/helpers.dart';

void main() {
  Widget buildSubject({
    Duration debounceDuration = const Duration(milliseconds: 180),
    bool autofocus = false,
  }) {
    return ProviderScope(
      child: buildTestMaterialApp(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 120),
              child: NotificationBellButton(
                debounceDuration: debounceDuration,
                autofocus: autofocus,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders notification bell icon with unread badge', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Bell icon is rendered
    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);

    // Initial state has 2 unread notifications, so red badge container should exist
    final badgeContainers = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color ==
              AppPalette.light.error &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    );
    expect(badgeContainers, findsOneWidget);
  });

  testWidgets('tapping bell toggles the popover', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Popover is closed initially
    expect(find.text('Notifications'), findsNothing);

    // Tap bell icon to open
    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();

    // Popover is open
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('View all notifications'), findsOneWidget);

    // Tap bell again to close
    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();

    // Popover is closed
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('hover debouncing delays opening popover', (tester) async {
    await tester.pumpWidget(
      buildSubject(debounceDuration: const Duration(milliseconds: 180)),
    );
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Hover over the bell button
    await gesture.moveTo(tester.getCenter(find.byType(NotificationBellButton)));
    await tester.pump();

    // At 100ms (less than 180ms), popover should not be visible yet
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Notifications'), findsNothing);

    // At 100ms more (200ms total >= 180ms), popover opens
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('fast mouse swipe cancels show timer (anti-flicker)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(debounceDuration: const Duration(milliseconds: 180)),
    );
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Hover in briefly
    await gesture.moveTo(tester.getCenter(find.byType(NotificationBellButton)));
    await tester.pump(const Duration(milliseconds: 50));

    // Move away before debounce expires
    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();

    // Advance time past debounce duration
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Popover was never opened
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('popover displays 3 most recent notifications with metadata', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Tap to open popover
    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();

    expect(find.text('Sarah Connor'), findsOneWidget);
    expect(
      find.text('Shared a file in #announcements: Q3 Roadmap.pdf'),
      findsOneWidget,
    );

    expect(find.text('Alex Mercer'), findsOneWidget);
    expect(
      find.text('Hey, do you have a few minutes to review the new design?'),
      findsOneWidget,
    );

    expect(find.text('Workspace Admin'), findsOneWidget);
    expect(
      find.text('Your credits were renewed for this billing cycle.'),
      findsOneWidget,
    );

    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('clicking Mark all read marks all notifications as read', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // Open popover
    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();

    // Click 'Mark all read'
    expect(find.text('Mark all read'), findsOneWidget);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    // Header action 'Mark all read' is gone and items are read
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets(
    'keyboard accessibility supports Enter to toggle and Escape to dismiss',
    (tester) async {
      await tester.pumpWidget(buildSubject(autofocus: true));
      await tester.pumpAndSettle();

      // Send Enter key to toggle open
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);

      // Send Escape key to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsNothing);
    },
  );

  testWidgets('semantics has button role and expanded state', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final semanticsClosed = tester.getSemantics(
      find.byType(NotificationBellButton),
    );
    expect(semanticsClosed.label, 'Notifications');
    expect(semanticsClosed.flagsCollection.isButton, isTrue);
    expect(semanticsClosed.flagsCollection.isExpanded, ui.Tristate.isFalse);

    // Open popover
    await tester.tap(find.byType(NotificationBellButton));
    await tester.pumpAndSettle();

    final semanticsOpen = tester.getSemantics(
      find.byType(NotificationBellButton),
    );
    expect(semanticsOpen.flagsCollection.isExpanded, ui.Tristate.isTrue);

    semanticsHandle.dispose();
  });
}
