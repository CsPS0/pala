import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';
import 'shells/desktop_shell.dart';
import 'shells/mobile_shell.dart';
import 'state/app_model.dart';
import 'theme/pala_theme.dart';
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
  }

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
          theme: appModel.isDarkMode ? PalaTheme.getDarkTheme() : PalaTheme.getLightTheme(),
          home: appModel.isAuthenticated
              ? PalaShell(appModel: appModel)
              : LoginView(appModel: appModel),
        );
      },
    );
  }
}

/// Picks the platform-appropriate shell. Desktop OSes (and any wide window,
/// e.g. a resized desktop build) get [DesktopShell]; Android/iOS and narrow
/// windows get [MobileShell]. Each shell owns its own navigation, screen
/// list, and layout — see the "shells" package doc comments for why they're
/// kept separate instead of one widget branching internally.
class PalaShell extends StatelessWidget {
  final AppModel appModel;

  const PalaShell({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        return isDesktop ? DesktopShell(appModel: appModel) : MobileShell(appModel: appModel);
      },
    );
  }
}
