// ABOUTME: Riverpod provider for PackageInfo, fetched once per app process.
// ABOUTME: Consumed by reviewPrompterProvider and the O aplikaciji screen.

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'package_info_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
