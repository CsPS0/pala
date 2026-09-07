import 'dart:io';
import 'dart:convert';
import 'package:pala/utils/logger.dart';

class AppState {
  static final AppState instance = AppState._internal();
  
  bool isOffline = false;
  String themeMode = 'dark';
  bool showAsciiBanner = true;
  int parentalQuota = 5;

  AppState._internal() {
    loadTheme();
  }

  String get configDir {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/.config/pala';
  }

  void _ensureConfigDir() {
    final dir = Directory(configDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  void migrateOldFiles() {
    _ensureConfigDir();
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    
    // 1. Migrate from old ~/.config/folio if exists
    final oldConfigDir = Directory('$home/.config/folio');
    if (oldConfigDir.existsSync()) {
      try {
        final oldAuthInFolio = File('${oldConfigDir.path}/auth.json');
        if (oldAuthInFolio.existsSync() && !authFile.existsSync()) {
          oldAuthInFolio.copySync(authFile.path);
        }
        final oldStateInFolio = File('${oldConfigDir.path}/state.json');
        if (oldStateInFolio.existsSync() && !stateFile.existsSync()) {
          oldStateInFolio.copySync(stateFile.path);
        }
        final oldAliasesInFolio = File('${oldConfigDir.path}/aliases.json');
        if (oldAliasesInFolio.existsSync() && !aliasesFile.existsSync()) {
          oldAliasesInFolio.copySync(aliasesFile.path);
        }
        final oldCacheInFolio = File('${oldConfigDir.path}/cache.json');
        if (oldCacheInFolio.existsSync() && !File('$configDir/cache.json').existsSync()) {
          oldCacheInFolio.copySync('$configDir/cache.json');
        }
      } catch (e) {
        PalaLogger.debug('Failed to migrate from ~/.config/folio: $e');
      }
    }

    // 2. Migrate from legacy ~/.folio_*.json files
    final oldAuth = File('$home/.folio_auth.json');
    if (oldAuth.existsSync() && !authFile.existsSync()) {
      oldAuth.copySync(authFile.path);
      oldAuth.deleteSync();
    }
    
    final oldState = File('$home/.folio_state.json');
    if (oldState.existsSync() && !stateFile.existsSync()) {
      oldState.copySync(stateFile.path);
      oldState.deleteSync();
    }
    
    final oldCache = File('$home/.folio_cache.json');
    if (oldCache.existsSync() && !File('$configDir/cache.json').existsSync()) {
      oldCache.copySync('$configDir/cache.json');
      oldCache.deleteSync();
    }
  }

  File get stateFile {
    _ensureConfigDir();
    return File('$configDir/state.json');
  }

  File get authFile {
    _ensureConfigDir();
    return File('$configDir/auth.json');
  }

  Map<String, dynamic> _load(File file) {
    if (!file.existsSync()) return {};
    try {
      final content = file.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      PalaLogger.debug('Failed to load file ${file.path}: $e');
      return {};
    }
  }

  void _save(File file, Map<String, dynamic> data) {
    try {
      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      PalaLogger.debug('Failed to save file ${file.path}: $e');
    }
  }

  Map<String, dynamic> getAuthData() {
    return _load(authFile);
  }

  void saveAuthData(Map<String, dynamic> data) {
    _save(authFile, data);
  }

  Map<String, dynamic> getAppState() {
    return _load(stateFile);
  }

  void saveAppState(Map<String, dynamic> data) {
    _save(stateFile, data);
  }

  File get aliasesFile {
    _ensureConfigDir();
    return File('$configDir/aliases.json');
  }

  Map<String, String> getAliases() {
    final data = _load(aliasesFile);
    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  String applyAlias(String original) {
    if (Platform.environment['NO_RENAME'] == '1') return original;
    final aliases = getAliases();
    return aliases[original] ?? original;
  }

  void loadTheme() {
    final state = getAppState();
    if (state.containsKey('themeMode')) {
      themeMode = state['themeMode'];
    } else if (state.containsKey('theme')) {
      // Legacy accent-picker field from older Pala versions; migrate to a
      // dark/light mode instead of trying to preserve the old accent name.
      themeMode = 'dark';
    }
    if (state.containsKey('showAsciiBanner')) {
      showAsciiBanner = state['showAsciiBanner'] == true;
    }
    if (state.containsKey('parentalQuota') && state['parentalQuota'] is int) {
      parentalQuota = state['parentalQuota'];
    }
  }

  void setParentalQuota(int quota) {
    parentalQuota = quota;
    final state = getAppState();
    state['parentalQuota'] = parentalQuota;
    saveAppState(state);
  }

  void saveTheme(String newThemeMode) {
    themeMode = newThemeMode;
    final state = getAppState();
    state['themeMode'] = themeMode;
    saveAppState(state);
  }

  void setTheme(String newTheme) => saveTheme(newTheme);

  void setShowAsciiBanner(bool val) {
    showAsciiBanner = val;
    final state = getAppState();
    state['showAsciiBanner'] = showAsciiBanner;
    saveAppState(state);
  }

  void setAlias(String original, String alias) {
    final state = getAppState();
    if (state['aliases'] == null) state['aliases'] = <String, dynamic>{};
    state['aliases'][original] = alias;
    saveAppState(state);
  }

  void removeAlias(String original) {
    final state = getAppState();
    if (state['aliases'] != null) {
      state['aliases'].remove(original);
      saveAppState(state);
    }
  }

  void clearAllData() {
    if (stateFile.existsSync()) {
      stateFile.deleteSync();
    }
    if (authFile.existsSync()) {
      authFile.deleteSync();
    }
    final secureFile = File('$configDir/.secure_token');
    if (secureFile.existsSync()) {
      secureFile.deleteSync();
    }
    final cacheDir = Directory('$configDir/cache');
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }
}
