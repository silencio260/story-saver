import 'package:flutter/widgets.dart';

class TopNavProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }
}
