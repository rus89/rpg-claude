// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$municipalityNamesHash() => r'2c4b1b37e864b7bd410ad4f71fdbdc9fb23b6d59';

/// See also [municipalityNames].
@ProviderFor(municipalityNames)
final municipalityNamesProvider = AutoDisposeProvider<List<String>>.internal(
  municipalityNames,
  name: r'municipalityNamesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$municipalityNamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MunicipalityNamesRef = AutoDisposeProviderRef<List<String>>;
String _$dataRepositoryHash() => r'83244f759f3a6bd38e4cdb9dde61c1ae3718dcbe';

/// See also [DataRepository].
@ProviderFor(DataRepository)
final dataRepositoryProvider =
    AutoDisposeAsyncNotifierProvider<DataRepository, List<Snapshot>>.internal(
      DataRepository.new,
      name: r'dataRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DataRepository = AutoDisposeAsyncNotifier<List<Snapshot>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
