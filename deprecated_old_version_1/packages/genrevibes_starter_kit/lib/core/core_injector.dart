import 'package:get_it/get_it.dart';
import 'storage/local_storage.dart';

void initCore(GetIt sl) {
  // Local Storage
  sl.registerLazySingleton<LocalStorage>(() => SharedPreferencesStorage());
}
