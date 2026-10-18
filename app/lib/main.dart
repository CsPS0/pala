import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';
import 'core/adaptive/adaptive_scaffold.dart';
import 'core/theme/m3_theme.dart';
import 'state/app_model.dart';
import 'state/session_store.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android/iOS have no HOME/USERPROFILE env var and a read-only process
  // working directory, so the shared package's default '~/.config/pala'
  // (falling back to './.config/pala') can't be created there. Point it at
  // a writable app-specific directory instead.
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationSupportDirectory();
    AppState.configDirOverride = dir.path;
    EncryptionUtil.configDirOverride = dir.path;
    AppState.cacheDirOverride = '${(await getTemporaryDirectory()).path}/pala';
  }
  await SessionStore.initKey();

  await initializeDateFormatting('hu_HU', null);
  final appModel = AppModel();
  runApp(PalaMobileApp(appModel: appModel));
}

class PalaMobileApp extends StatelessWidget {
  final AppModel appModel;

  const PalaMobileApp({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pala',
          debugShowCheckedModeBanner: false,
          theme: appModel.isDarkMode ? M3Theme.darkTheme : M3Theme.lightTheme,
          home: appModel.isAuthenticated
              ? PalaShell(appModel: appModel)
              : LoginView(appModel: appModel),
        );
      },
    );
  }
}

/// Unified adaptive shell delegating to [AdaptiveScaffold] to evaluate the 600dp breakpoint.
class PalaShell extends StatelessWidget {
  final AppModel appModel;

  const PalaShell({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(appModel: appModel);
  }
}
