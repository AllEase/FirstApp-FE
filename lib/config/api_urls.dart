import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiUrls {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get signup => '$baseUrl/firstApp/signup/';
  static String get login => '$baseUrl/firstApp/login/';
  static String get sendOtp => '$baseUrl/firstApp/sendOtp/';
  static String get verifyOtp => '$baseUrl/firstApp/verifyOtp/';
  static String get addProduct => '$baseUrl/firstApp/addProduct/';
  static String get getUserDetails => '$baseUrl/firstApp/getUserDetails/';
  static String get getHomePageList => '$baseUrl/firstApp/getHomePageList/';
  static String get getOwnProducts => '$baseUrl/firstApp/getOwnProducts/';
  static String get toggleProduct => '$baseUrl/firstApp/toggleProduct/';
  static String get getSavedlist => '$baseUrl/firstApp/getSavedlist/';
  static String get saveAddresses => '$baseUrl/firstApp/saveAddresses/';
  static String get getProductDetails => '$baseUrl/firstApp/getProductDetails/';
  static String get createOrder => '$baseUrl/firstApp/createOrder/';
  static String get verifyPayment => '$baseUrl/firstApp/verifyPayment/';
  static String get getUserOrders => '$baseUrl/firstApp/getUserOrders/';
}
