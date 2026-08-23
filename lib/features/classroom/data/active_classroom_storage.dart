import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActiveClassroomStorage {
  String? read();
  void write(String shareCode);
  void clear();
}

class MemoryActiveClassroomStorage implements ActiveClassroomStorage {
  String? _shareCode;

  @override
  String? read() => _shareCode;

  @override
  void write(String shareCode) => _shareCode = shareCode;

  @override
  void clear() => _shareCode = null;
}

class SharedPreferencesActiveClassroomStorage
    implements ActiveClassroomStorage {
  SharedPreferencesActiveClassroomStorage(this._preferences);

  static const _key = 'seat_mate_active_classroom_share_code';

  final SharedPreferences _preferences;

  @override
  String? read() => _preferences.getString(_key);

  @override
  void write(String shareCode) {
    unawaited(_preferences.setString(_key, shareCode));
  }

  @override
  void clear() {
    unawaited(_preferences.remove(_key));
  }
}
