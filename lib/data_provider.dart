import 'dart:math';
import 'package:flutter/material.dart';

class DataProvider extends ChangeNotifier {
  late String _data;
  bool _isLoading = false;
  bool _isFetching = false;

  String get data => _data;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;

  Future<String> getData() async {
    await Future.delayed(Duration(seconds: 2));
    return 'async-data ${Random().nextInt(100)}';
  }

  Future<void> fetch() async {
    if (_isFetching) return;
    _isLoading = true;
    _isFetching = true;
    _data = await getData();
    _isLoading = false;
    _isFetching = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();
    _data = await getData();
    _isFetching = false;
    notifyListeners();
  }
}
