import 'package:equatable/equatable.dart';

/// Represents an ad unit configuration
class AdUnit extends Equatable {
  final String id;
  final AdType type;
  final bool isLoaded;
  final bool isFailed;

  const AdUnit({
    required this.id,
    required this.type,
    this.isLoaded = false,
    this.isFailed = false,
  });

  AdUnit copyWith({String? id, AdType? type, bool? isLoaded, bool? isFailed}) {
    return AdUnit(
      id: id ?? this.id,
      type: type ?? this.type,
      isLoaded: isLoaded ?? this.isLoaded,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  @override
  List<Object?> get props => [id, type, isLoaded, isFailed];
}

enum AdType { banner, interstitial, rewarded, native, appOpen }
