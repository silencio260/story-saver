part of 'navigation_bloc.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class NavigationTabSelected extends NavigationEvent {
  const NavigationTabSelected(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}
