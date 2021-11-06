import 'dart:io';
import 'package:brethap/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:brethap/constants.dart';
import 'package:brethap/preferences_widget.dart';
import 'package:brethap/hive_storage.dart';

Future<void> main() async {
  late Box preferences;
  setUpAll((() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter(Directory.systemTemp.createTempSync().path);
    Hive.registerAdapter(PreferenceAdapter());
    preferences = await Hive.openBox('preferences');
  }));

  tearDownAll((() async {}));

  group('Preferences', () {
    setUp(() async {});

    tearDown((() async {}));

    // ignore: unused_element
    void verifyDefault(Preference preference) {
      Preference p = getDefaultPref();
      expect(preference.duration, p.duration);
      expect(
          find.textContaining(
              "${getDurationString(Duration(seconds: p.duration))}",
              skipOffstage: false),
          findsOneWidget);
      expect(preference.vibrateDuration, p.vibrateDuration);
      expect(
          find.textContaining("${p.vibrateDuration} ms", skipOffstage: false),
          findsOneWidget);
      expect(preference.durationTts, p.durationTts);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Switch &&
              widget.key == Key(DURATION_TTS_TEXT) &&
              widget.value == DURATION_TTS),
          findsOneWidget);
      expect(preference.inhale, p.inhale);
      expect(preference.exhale, p.exhale);
      expect(
          find.textContaining("${(INHALE / Duration.millisecondsPerSecond)} s"),
          findsWidgets);
      expect(preference.vibrateBreath, p.vibrateBreath);
      expect(find.textContaining("${p.vibrateBreath} ms"), findsOneWidget);
      expect(preference.breathTts, p.breathTts);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Switch &&
              widget.key == Key(BREATH_TTS_TEXT) &&
              widget.value == BREATH_TTS),
          findsOneWidget);
    }

    testWidgets('PreferencesWidget', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: PreferencesWidget(
        preferences: preferences,
        callback: () {
          debugPrint("callback executed");
        },
      )));

      await tester.pumpAndSettle();

      Preference preference = preferences.get(0);

      // Drag duration slider
      expect(
          find.textContaining(
              "${getDurationString(Duration(seconds: DURATION))}"),
          findsOneWidget);
      await tester.drag(find.byKey(Key(DURATION_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.duration, 3660);
      expect(find.bySemanticsLabel(RegExp("1:01:00")), findsOneWidget);

      // Drag vibrate duration slider
      expect(find.textContaining("$VIBRATE_DURATION ms"), findsOneWidget);
      await tester.drag(
          find.byKey(Key(DURATION_VIBRATE_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.vibrateDuration, 500);
      expect(find.textContaining("500 ms"), findsOneWidget);

      // Drag duration tts switch
      expect(preference.durationTts, DURATION_TTS);
      await tester.drag(
          find.byKey(Key(DURATION_TTS_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.durationTts, !DURATION_TTS);

      // Drag inhale slider
      expect(
          find.textContaining("${(INHALE / Duration.millisecondsPerSecond)} s"),
          findsWidgets);
      await tester.drag(find.byKey(Key(INHALE_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.inhale, [5300, INHALE_HOLD]);
      expect(find.textContaining("5.3 s"), findsWidgets);

      // Drag inhale hold slider
      expect(
          find.textContaining(
              "${(INHALE_HOLD / Duration.millisecondsPerSecond)} s"),
          findsWidgets);
      await tester.drag(
          find.byKey(Key(INHALE_HOLD_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.inhale, [5300, 5000]);
      expect(find.textContaining("5.0 s"), findsWidgets);

      // Drag exhale slider
      expect(
          find.textContaining("${(INHALE / Duration.millisecondsPerSecond)} s"),
          findsWidgets);
      await tester.drag(find.byKey(Key(EXHALE_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.exhale, [5300, EXHALE_HOLD]);
      expect(find.textContaining("5.3 s"), findsWidgets);

      // Drag exhale hold slider
      await tester.ensureVisible(find.byKey(Key(EXHALE_HOLD_TEXT)));
      expect(
          find.textContaining(
              "${(EXHALE_HOLD / Duration.millisecondsPerSecond)} s"),
          findsWidgets);
      await tester.drag(
          find.byKey(Key(EXHALE_HOLD_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.exhale, [5300, 5000]);
      expect(find.textContaining("5.0 s"), findsWidgets);

      // Drag vibrate breath slider
      expect(find.textContaining("$VIBRATE_BREATH ms"), findsOneWidget);
      await tester.drag(
        find.byKey(Key(BREATH_VIBRATE_TEXT)),
        const Offset(0.0, 0.0),
      );
      await tester.pumpAndSettle();
      expect(preference.vibrateBreath, 500);
      expect(find.textContaining("500 ms"), findsOneWidget);

      // Drag breath tts switch
      expect(preference.breathTts, BREATH_TTS);
      await tester
          .ensureVisible(find.byKey(Key(BREATH_TTS_TEXT), skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.drag(
          find.byKey(Key(BREATH_TTS_TEXT)), const Offset(0.0, 0.0));
      await tester.pumpAndSettle();
      expect(preference.breathTts, !BREATH_TTS);

      // Verify saved preferences
      for (int i = 1; i <= SAVED_PREFERENCES; i++) {
        // Long press preference button
        await tester.longPress(find.byKey(Key("Preference $i")));
        await tester.pumpAndSettle();

        // Verify preference
        preference = preferences.get(i);
        expect(preference.duration, 3660);
        expect(preference.vibrateDuration, 500);
        expect(preference.durationTts, !DURATION_TTS);
        expect(preference.inhale, [5300, 5000]);
        expect(preference.exhale, [5300, 5000]);
        expect(preference.vibrateBreath, 500);
        expect(preference.breathTts, !BREATH_TTS);
      }

      // Verify menu items
      Finder menu = find.byKey(Key("menu"));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Verify menu items
      Finder resetAll = find.byKey(Key(RESET_ALL_TEXT));
      expect(resetAll, findsOneWidget);
      Finder backup = find.byKey(Key(BACKUP_TEXT));
      expect(backup, findsOneWidget);
      Finder restore = find.byKey(Key(RESTORE_TEXT));
      expect(restore, findsOneWidget);
      Finder presets = find.byKey(Key(PRESETS_TEXT));
      expect(presets, findsOneWidget);

      // Verify backup
      await tester.tap(backup);
      await tester.pumpAndSettle();

      menu = find.byKey(Key("menu"));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Verify restore
      await tester.tap(restore);
      await tester.pumpAndSettle();

      menu = find.byKey(Key("menu"));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Verify reset all
      await tester.tap(resetAll);
      await tester.pumpAndSettle();
      Finder cont = find.byKey(Key(CONTINUE_TEXT));
      expect(cont, findsOneWidget);
      await tester.tap(cont);
      await tester.pumpAndSettle();

      //TODO: Verify preferences reset
      //expect(preferences.length, 1);

      menu = find.byKey(Key("menu"));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Verify presets
      await tester.tap(presets);
      await tester.pumpAndSettle();
      Finder def = find.textContaining(DEFAULT_TEXT);
      expect(def, findsOneWidget);
      await tester.tap(def);
      await tester.pumpAndSettle();

      verifyDefault(preferences.get(0));

      // debugDumpApp();
    });
  });
}
