import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get signup => '$baseUrl/firstApp/signup/';
  static String get login => '$baseUrl/firstApp/login/';
  static String get sendOtp => '$baseUrl/firstApp/sendOtp/';
  static String get verifyOtp => '$baseUrl/firstApp/verifyOtp/';
  static String get addProduct => '$baseUrl/firstApp/addProduct/';
  static String get getUserDetails => '$baseUrl/firstApp/getUserDetails/';
  static String get getHomePageList => '$baseUrl/firstApp/getHomePageList/';
  static String get getOwnProducts => '$baseUrl/firstApp/getOwnProducts/';
  static String get toggleFavorite => '$baseUrl/firstApp/toggleFavorite/';
  static String get getWishlist => '$baseUrl/firstApp/getWishlist/';
}
