import 'dart:ffi';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const ShortcutKey = "Pboard_ShortcutKey";
  static const LoginInLaunchKey = "Pboard_LoginInLaunchKey";
  static const MaxItemStoreKey = "Pboard_MaxItemStoreKey";

  static void setShortcutKey(String string) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(ShortcutKey, string);
  }
  static Future<String> getShortcutKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String value = prefs.getString(ShortcutKey)??"";
    return Future.value(value);
  }

  static void setMaxItemStoreKey(int count) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(MaxItemStoreKey, count);
  }
  static Future<int> getMaxItemStoreKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int value = prefs.getInt(MaxItemStoreKey)??50;
    return Future.value(value);
  }

  static void setLoginInLaunchKey(bool status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LoginInLaunchKey, status);
  }
  static Future<bool> getLoginInLaunchKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool value = prefs.getBool(LoginInLaunchKey) ?? false;
    return Future.value(value);
  }

}