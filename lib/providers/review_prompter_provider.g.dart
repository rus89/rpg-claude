// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_prompter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewPrompter)
final reviewPrompterProvider = ReviewPrompterProvider._();

final class ReviewPrompterProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReviewPrompter>,
          ReviewPrompter,
          FutureOr<ReviewPrompter>
        >
    with $FutureModifier<ReviewPrompter>, $FutureProvider<ReviewPrompter> {
  ReviewPrompterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewPrompterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewPrompterHash();

  @$internal
  @override
  $FutureProviderElement<ReviewPrompter> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReviewPrompter> create(Ref ref) {
    return reviewPrompter(ref);
  }
}

String _$reviewPrompterHash() => r'e90a67f6fb17577d67821b86cd7cc91f492e1917';
