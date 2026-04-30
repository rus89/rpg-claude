// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DataRepository)
final dataRepositoryProvider = DataRepositoryProvider._();

final class DataRepositoryProvider
    extends $AsyncNotifierProvider<DataRepository, List<Snapshot>> {
  DataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataRepositoryHash();

  @$internal
  @override
  DataRepository create() => DataRepository();
}

String _$dataRepositoryHash() => r'329f7879037f8ed7f20c18e4dbe7033012053896';

abstract class _$DataRepository extends $AsyncNotifier<List<Snapshot>> {
  FutureOr<List<Snapshot>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Snapshot>>, List<Snapshot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Snapshot>>, List<Snapshot>>,
              AsyncValue<List<Snapshot>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nameResolver)
final nameResolverProvider = NameResolverProvider._();

final class NameResolverProvider
    extends
        $FunctionalProvider<
          AsyncValue<NameResolver>,
          NameResolver,
          FutureOr<NameResolver>
        >
    with $FutureModifier<NameResolver>, $FutureProvider<NameResolver> {
  NameResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nameResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nameResolverHash();

  @$internal
  @override
  $FutureProviderElement<NameResolver> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NameResolver> create(Ref ref) {
    return nameResolver(ref);
  }
}

String _$nameResolverHash() => r'6d4af064b931037eb6fd963d061c12efaa18df7a';

@ProviderFor(municipalityNames)
final municipalityNamesProvider = MunicipalityNamesProvider._();

final class MunicipalityNamesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  MunicipalityNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'municipalityNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$municipalityNamesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return municipalityNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$municipalityNamesHash() => r'2c4b1b37e864b7bd410ad4f71fdbdc9fb23b6d59';
