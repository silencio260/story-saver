import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabSelected>((event, emit) {
      if (state.currentIndex != event.index) {
        AnalyticsService.track('navigation_tab_selected', {
          'tab_index': event.index,
        });
      }
      emit(NavigationState(currentIndex: event.index));
    });
  }
}
