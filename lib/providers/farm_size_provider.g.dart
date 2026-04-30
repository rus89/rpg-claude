// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm_size_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FarmSizeRepository)
final farmSizeRepositoryProvider = FarmSizeRepositoryProvider._();

final class FarmSizeRepositoryProvider
    extends $AsyncNotifierProvider<FarmSizeRepository, List<FarmSizeSnapshot>> {
  FarmSizeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'farmSizeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$farmSizeRepositoryHash();

  @$internal
  @override
  FarmSizeRepository create() => FarmSizeRepository();
}

String _$farmSizeRepositoryHash() =>
    r'09bd0daf5a77d81fdd801a7b52880fea647f90e5';

abstract class _$FarmSizeRepository
    extends $AsyncNotifier<List<FarmSizeSnapshot>> {
  FutureOr<List<FarmSizeSnapshot>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FarmSizeSnapshot>>, List<FarmSizeSnapshot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FarmSizeSnapshot>>,
                List<FarmSizeSnapshot>
              >,
              AsyncValue<List<FarmSizeSnapshot>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
