import '../../container_injector.dart';
import 'presentation/bloc/navigation_bloc/navigation_bloc.dart';

void initNavigation() {
  sl.registerFactory(NavigationBloc.new);
}
