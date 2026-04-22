// ABOUTME: Integration test driver — passes through to the default integration runner.
// ABOUTME: Screenshots are captured externally via `adb exec-out screencap` from the
// ABOUTME: capture script watching the test's stdout marker lines, not via onScreenshot.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
