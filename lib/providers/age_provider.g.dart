// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgeRepository)
final ageRepositoryProvider = AgeRepositoryProvider._();

final class AgeRepositoryProvider
    extends $AsyncNotifierProvider<AgeRepository, List<AgeSnapshot>> {
  AgeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ageRepositoryHash();

  @$internal
  @override
  AgeRepository create() => AgeRepository();
}

String _$ageRepositoryHash() => r'a6d7325f5194e26adb3ed356244722528aca57c5';

abstract class _$AgeRepository extends $AsyncNotifier<List<AgeSnapshot>> {
  FutureOr<List<AgeSnapshot>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AgeSnapshot>>, List<AgeSnapshot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AgeSnapshot>>, List<AgeSnapshot>>,
              AsyncValue<List<AgeSnapshot>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
