import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wpa_app/presentation/foundation/layout/adaptive_shell.dart';
import 'package:wpa_app/presentation/foundation/layout/content_constraint.dart';
import 'package:wpa_app/presentation/foundation/layout/responsive_grid.dart';
import 'package:wpa_app/presentation/foundation/layout/window_size.dart';

Future<void> setWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('WindowSize breakpoints are 600 / 840 / 1200', () {
    expect(WindowSize.fromWidth(599.9), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(839), WindowSize.medium);
    expect(WindowSize.fromWidth(840), WindowSize.expanded);
    expect(WindowSize.fromWidth(1199), WindowSize.expanded);
    expect(WindowSize.fromWidth(1200), WindowSize.large);
  });

  group('AdaptiveShell', () {
    var selected = -1;

    Widget shell() => MaterialApp(
          home: AdaptiveShell(
            destinations: const [
              AdaptiveDestination(icon: Icons.home, label: 'HOME'),
              AdaptiveDestination(icon: Icons.person, label: 'PROFILE'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (i) => selected = i,
            body: const Text('body'),
          ),
        );

    final cases = <double, (Type, bool?)>{
      390: (NavigationBar, null),
      700: (NavigationRail, false),
      1024: (NavigationRail, true),
      1366: (NavigationRail, true),
    };

    cases.forEach((width, expected) {
      testWidgets('at ${width.toInt()} px uses ${expected.$1}', (tester) async {
        await setWidth(tester, width);
        await tester.pumpWidget(shell());
        expect(find.text('body'), findsOneWidget);
        expect(find.byType(expected.$1), findsOneWidget);
        if (expected.$1 == NavigationRail) {
          expect(find.byType(NavigationBar), findsNothing);
          final rail =
              tester.widget<NavigationRail>(find.byType(NavigationRail));
          expect(rail.extended, expected.$2);
        } else {
          expect(find.byType(NavigationRail), findsNothing);
        }
        selected = -1;
        await tester.tap(find.text('PROFILE'));
        expect(selected, 1);
      });
    });

    testWidgets('re-reads the size class when the window resizes',
        (tester) async {
      await setWidth(tester, 390);
      await tester.pumpWidget(shell());
      expect(find.byType(NavigationBar), findsOneWidget);
      tester.view.physicalSize = const Size(1024, 900);
      await tester.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  testWidgets('ContentConstraint caps width and centres', (tester) async {
    await setWidth(tester, 1366);
    const key = Key('content');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ContentConstraint(
            child: SizedBox(key: key, height: 10, width: 2000)),
      ),
    ));
    final rect = tester.getRect(find.byKey(key));
    expect(rect.width, ContentConstraint.defaultMaxWidth);
    expect(rect.center.dx, closeTo(683, 0.5));
  });

  testWidgets('ContentConstraint fills narrow screens', (tester) async {
    await setWidth(tester, 390);
    const key = Key('content');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ContentConstraint(
          child: SizedBox(key: key, height: 10, width: double.infinity),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(key)).width, 390);
  });

  for (final (width, columns) in [(390.0, 2), (1366.0, 4)]) {
    testWidgets('ResponsiveGrid shows $columns columns at ${width.toInt()} px',
        (tester) async {
      await setWidth(tester, width);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResponsiveGrid(
            maxItemExtent: 360,
            spacing: 0,
            itemCount: 8,
            itemBuilder: (_, i) => Text('item $i'),
          ),
        ),
      ));
      final y0 = tester.getTopLeft(find.text('item 0')).dy;
      final sameRow = List.generate(8, (i) => i)
          .where((i) => find.text('item $i').evaluate().isNotEmpty)
          .where((i) => tester.getTopLeft(find.text('item $i')).dy == y0)
          .length;
      expect(sameRow, columns);
    });
  }
}
