import 'package:campusmate/main.dart' as campusmate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('CAMPUSMATE_TEST_EMAIL');
  const password = String.fromEnvironment('CAMPUSMATE_TEST_PASSWORD');

  testWidgets('sign in, switch Dashboard and Chats, calculate tuition', (
    tester,
  ) async {
    expect(
      email,
      isNotEmpty,
      reason: 'Set CAMPUSMATE_TEST_EMAIL in the local test credentials file.',
    );
    expect(
      password,
      isNotEmpty,
      reason:
          'Set CAMPUSMATE_TEST_PASSWORD in the local test credentials file.',
    );

    await campusmate.main();
    await tester.pump();

    // Start from sign-in even if this device already has an active session.
    if (Supabase.instance.client.auth.currentSession != null) {
      await Supabase.instance.client.auth.signOut();
      await _pauseAfterAction(tester);
    }

    final signInTitle = find.text('Welcome back');
    final welcomeLink = find.text('I already have an account');
    await _pumpUntilAny(tester, [signInTitle, welcomeLink]);
    if (welcomeLink.evaluate().isNotEmpty) {
      await _tapWhenReady(tester, welcomeLink);
    }
    await _pumpUntil(tester, signInTitle);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await _enterTextAndPause(tester, fields.at(0), email);
    await _enterTextAndPause(tester, fields.at(1), password);
    await _tapWhenReady(tester, find.text('Sign in'));

    final greeting = find.textContaining('Hello,');
    await _pumpUntil(tester, greeting, timeout: const Duration(seconds: 60));

    await _tapWhenReady(tester, find.text('Chats').last);
    await _pumpUntil(
      tester,
      find.text('Your study help conversations will appear here.'),
    );

    await _tapWhenReady(tester, find.text('Home').last);
    await _pumpUntil(tester, greeting);

    await _tapWhenReady(tester, find.text('Calculate tuition'));
    await _pumpUntil(tester, find.text('Tuition Fee Calculator'));

    final creditsField = find.byType(TextFormField);
    expect(creditsField, findsOneWidget);
    await _enterTextAndPause(tester, creditsField, '12');

    await _tapWhenReady(tester, find.text('No waiver'));
    await _tapWhenReady(tester, find.text('50%').last);

    await _tapWhenReady(tester, find.text('Calculate'));
    await _pumpUntil(
      tester,
      find.text('Calculated Installments'),
      timeout: const Duration(seconds: 60),
    );
    expect(find.text('1st installment'), findsOneWidget);
    expect(find.text('2nd installment'), findsOneWidget);
    expect(find.text('3rd installment'), findsOneWidget);

    await _tapWhenReady(tester, find.text('Close'));
    await _tapWhenReady(tester, find.byTooltip('Back'));
    await _pumpUntil(tester, greeting);

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    await _testMarketplace(tester, suffix);
    await _testLostAndFound(tester, suffix);
    await _testStudyHelp(tester, suffix);
    await _testThemeToggle(tester);

    // The flutter drive --keep-app-running option leaves the profile screen open.
  });
}

Future<void> _testMarketplace(WidgetTester tester, String suffix) async {
  final title = 'CampusMate test item $suffix';
  await _openDashboardFeature(tester, 'Marketplace');
  await _tapWhenReady(tester, find.text('Sell an item'));

  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(3));
  await _enterTextAndPause(tester, fields.at(0), title);
  await _enterTextAndPause(
    tester,
    fields.at(1),
    'Automated test listing for marketplace UI checks.',
  );
  await _enterTextAndPause(tester, fields.at(2), '1');
  await _tapWhenReady(tester, find.text('Post'));

  await _pumpUntil(tester, find.text(title), timeout: const Duration(seconds: 60));
  await _tapWhenReady(tester, find.text(title));
  await _pumpUntil(tester, find.text('Post details'));
  await _tapWhenReady(tester, find.text('Mark as sold out'));
  await _pumpUntil(tester, find.text('Mark item as sold out?'));
  await _tapWhenReady(tester, find.text('Mark sold out'));
  await _pumpUntil(tester, find.text('Mark as available'),
      timeout: const Duration(seconds: 60));
  expect(find.text('Sold out'), findsOneWidget);

  await _backToDashboard(tester);
}

Future<void> _testLostAndFound(WidgetTester tester, String suffix) async {
  final title = 'CampusMate lost item test $suffix';
  await _openDashboardFeature(tester, 'Lost & found');
  await _tapWhenReady(tester, find.text('Create post'));

  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(3));
  await _enterTextAndPause(tester, fields.at(0), title);
  await _enterTextAndPause(
    tester,
    fields.at(1),
    'Automated test post for lost and found UI checks.',
  );
  await _enterTextAndPause(tester, fields.at(2), 'Test location');
  await _tapWhenReady(tester, find.text('Submit post'));

  await _pumpUntil(tester, find.text(title), timeout: const Duration(seconds: 60));
  await _tapWhenReady(tester, find.text(title));
  await _pumpUntil(tester, find.text('Post details'));
  await _tapWhenReady(tester, find.text('Mark resolved'));
  await _pumpUntil(tester, find.text('Mark post as resolved?'));
  await _tapWhenReady(tester, find.text('Mark resolved').last);
  await _pumpUntil(tester, find.text('Lost (Resolved)'),
      timeout: const Duration(seconds: 60));

  await _backToDashboard(tester);
}

Future<void> _testStudyHelp(WidgetTester tester, String suffix) async {
  final topic = 'CampusMate study test $suffix';
  await _openDashboardFeature(tester, 'Study help');
  await _tapWhenReady(tester, find.text('Ask for help'));

  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(3));
  await _enterTextAndPause(tester, fields.at(0), 'UI Test Course');
  await _enterTextAndPause(tester, fields.at(1), topic);
  await _enterTextAndPause(
    tester,
    fields.at(2),
    'Automated test request for study help UI checks.',
  );
  await _tapWhenReady(tester, find.text('Post'));

  await _pumpUntil(tester, find.text(topic), timeout: const Duration(seconds: 60));
  await _tapWhenReady(tester, find.text('View details'));
  await _pumpUntil(tester, find.text('Study help details'));
  await _tapWhenReady(tester, find.text('Mark as solved'));
  await _pumpUntil(tester, find.text('Mark request as solved?'));
  await _tapWhenReady(tester, find.text('Mark solved'));
  await _pumpUntil(tester, find.text('Solved'),
      timeout: const Duration(seconds: 60));

  await _backToDashboard(tester);
}

Future<void> _testThemeToggle(WidgetTester tester) async {
  final profileAvatar = find.ancestor(
    of: find.byWidgetPredicate(
      (widget) => widget is CircleAvatar && widget.radius == 21,
      description: 'dashboard profile avatar',
    ),
    matching: find.byType(InkWell),
  );
  // Scroll the Dashboard back to its header before resolving the lazy avatar.
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
  await _pauseAfterAction(tester);
  await _pumpUntil(tester, profileAvatar.hitTestable());
  await _tapWhenReady(tester, profileAvatar.first);
  await _pumpUntil(tester, find.text('Your profile'));
  final darkModeSwitch = find.byType(SwitchListTile);
  await _pumpUntil(tester, darkModeSwitch);
  final initialValue = tester.widget<SwitchListTile>(darkModeSwitch).value;

  await _tapWhenReady(tester, find.text('Dark mode'));
  expect(tester.widget<SwitchListTile>(darkModeSwitch).value, !initialValue);
  await _tapWhenReady(tester, find.text('Dark mode'));
  expect(tester.widget<SwitchListTile>(darkModeSwitch).value, initialValue);
}

Future<void> _openDashboardFeature(
  WidgetTester tester,
  String label,
) async {
  final feature = find.text(label);
  await tester.scrollUntilVisible(
    feature,
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await _pauseAfterAction(tester);
  await _tapWhenReady(tester, feature);
}

Future<void> _backToDashboard(WidgetTester tester) async {
  await _tapWhenReady(tester, find.byTooltip('Back'));
  await _tapWhenReady(tester, find.byTooltip('Back'));
  await _pumpUntil(tester, find.byType(NavigationBar));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().length != 1 && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilAny(WidgetTester tester, List<Finder> finders) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  bool found() => finders.any((finder) => finder.evaluate().isNotEmpty);

  while (!found() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(found(), isTrue, reason: 'Expected the welcome or sign-in page.');
}

Future<void> _tapWhenReady(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 60));
  final scrollables = find.byType(Scrollable);
  while (finder.hitTestable().evaluate().length != 1 &&
      DateTime.now().isBefore(end)) {
    final matches = finder.evaluate();
    if (matches.isNotEmpty) {
      final target = finder.first;
      final rect = tester.getRect(target);
      final view = tester.view;
      final center = rect.center;
      final outsideView = center.dx < 0 ||
          center.dx > view.physicalSize.width / view.devicePixelRatio ||
          center.dy < 0 ||
          center.dy > view.physicalSize.height / view.devicePixelRatio;
      if (outsideView) {
        await tester.ensureVisible(target);
        await _pauseAfterAction(tester);
      } else {
        await tester.pump(const Duration(milliseconds: 250));
      }
    } else if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -280));
      await _pauseAfterAction(tester);
    } else {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _pauseAfterAction(tester);
}

Future<void> _enterTextAndPause(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await _pauseAfterAction(tester);
}

Future<void> _pauseAfterAction(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(seconds: 1)),
  );
  await tester.pump();
}
