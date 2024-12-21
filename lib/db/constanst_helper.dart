import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const shortcutKey = "Pboard_ShortcutKey";
  static const loginInLaunchKey = "Pboard_LoginInLaunchKey";
  static const maxItemStoreKey = "Pboard_MaxItemStoreKey";

  static void setShortcutKey(String string) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(shortcutKey, string);
  }
  static Future<String> getShortcutKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String value = prefs.getString(shortcutKey)??"";
    return Future.value(value);
  }

  static void setMaxItemStoreKey(int count) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(maxItemStoreKey, count);
  }
  static Future<int> getMaxItemStoreKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int value = prefs.getInt(maxItemStoreKey)??50;
    return Future.value(value);
  }

  static void setLoginInLaunchKey(bool status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginInLaunchKey, status);
  }
  static Future<bool> getLoginInLaunchKey() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool value = prefs.getBool(loginInLaunchKey) ?? false;
    return Future.value(value);
  }

}