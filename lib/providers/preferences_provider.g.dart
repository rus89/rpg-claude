// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preferences)
final preferencesProvider = PreferencesProvider._();

final class PreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Preferences>,
          Preferences,
          FutureOr<Preferences>
        >
    with $FutureModifier<Preferences>, $FutureProvider<Preferences> {
  PreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesHash();

  @$internal
  @override
  $FutureProviderElement<Preferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Preferences> create(Ref ref) {
    return preferences(ref);
  }
}

String _$preferencesHash() => r'342d790bf7fe5450b9dffca72f845e3c3a9747a5';
