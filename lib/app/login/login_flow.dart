part of '../cli_app.dart';

extension PalaAppLoginFlow on PalaApp {
  Future<void> _performLoginFlow() async {
      final loginMode = Select(
        prompt: 'Válassz bejelentkezési opciót',
        options: [
          'Kréta bejelentkezés (Valós intézményi fiók)',
          'Demó profil betöltése (Teszt Elek - Offline tesztadatok)',
        ],
      ).interact();

      if (loginMode == 1) {
        isDemo = true;
        _client = DemoKretaClient();
        print('\n\x1B[1;32m[+] Demó profil sikeresen betöltve: Teszt Elek (Pala Minta Gimnázium)\x1B[0m\n');
        await _mainMenu();
        return;
      }

      final hasCodeChoice = Select(
        prompt: 'Tudod az intézmény kódját?',
        options: ['Igen, tudom a kódját', 'Nem, keresés név alapján'],
      ).interact();
  
      String instituteCode = '';
  
      if (hasCodeChoice == 1) {
        while (instituteCode.isEmpty) {
          final query = Utf8Input(prompt: 'Keresés az iskola neve alapján (min 3 karakter)').interact();
          if (query.length >= 3) {
            print('Keresés folyamatban...');
            final results = await KretaClient.searchSchools(query);
            
            if (results.isEmpty) {
              print('Nem található a keresésnek megfelelő iskola.');
            } else {
              final keys = results.keys.toList();
              final options = keys.map((k) => '${results[k]} (Kód: $k)').toList();
              options.add('Új keresés');
              
              final choice = Select(
                prompt: 'Válaszd ki a megfelelőt',
                options: options,
              ).interact();
              
              if (choice < keys.length) {
                instituteCode = keys[choice];
                print('Kiválasztott intézménykód: $instituteCode\n');
              }
            }
          }
        }
      } else {
        instituteCode = Utf8Input(prompt: 'Intézmény kódja (pl. bmszc-neumann)').interact();
      }
  
      _client = KretaClient(instituteCode: instituteCode);
      _client!.onTokenRefreshed = () async {
        await _saveAuth();
      };
      
      final authMethod = Select(
        prompt: 'Válassz bejelentkezési módszert',
        options: [
          'CLI Automatikus bejelentkezés (Ajánlott)',
          'Webes bejelentkezés (Böngészőn keresztül, CAPTCHA vagy kétlépcsős azonosítás esetén)',
        ],
      ).interact();

      bool success = false;

      if (authMethod == 1) {
        success = await _browserLogin();
      } else {
        final username = Utf8Input(prompt: 'Felhasználónév (oktatási azonosító)').interact();
        final password = Password(prompt: 'Jelszó (születési dátum vagy megadott jelszó)').interact();

        if (username.isEmpty || password.isEmpty) {
          print('Hiba: Minden mezőt ki kell tölteni!');
          return;
        }

        print('\nBelépés folyamatban...');
        try {
          success = await _client!.login(username, password);
        } on InteractiveLoginRequired catch (e) {
          print('\n\x1B[33m$e\x1B[0m');
          success = await _browserLogin();
        }
      }
  
      if (!success) {
        print('Sikertelen bejelentkezés.');
        return;
      }
  
      print('Sikeres bejelentkezés!\n');
  
      final remember = Confirm(
        prompt: 'Szeretnéd, hogy a rendszer megjegyezze a bejelentkezést?',
        defaultValue: true,
      ).interact();
  
      if (remember) {
        await _saveAuth();
        print('Bejelentkezés elmentve.\n');
        
        if (Platform.isWindows) {
          final enableDaemon = Confirm(
            prompt: 'Szeretnéd bekapcsolni az automatikus háttér-értesítéseket bejelentkezéskor/óránként? (Ezt később a beállításokban is módosíthatod)',
            defaultValue: false,
          ).interact();
          _setupDaemon(enableDaemon);
        }
      }
  
      await _mainMenu();
    }

  /// Login on Kréta's own page in the system browser. Captcha and two-factor
  /// steps happen there, done by the user; Pala only gets the final code.
  Future<bool> _browserLogin() async {
    final url = KretaAPI.authorizeUrl(instituteCode: _client!.instituteCode);

    print('\nHa a böngésző nem nyílna meg automatikusan, nyisd meg az alábbi linket (Ctrl+Kattintás):');
    print(url);

    print('\nMegnyitom a böngészőt a bejelentkezéshez...');
    PalaWebServer.openBrowser(url);

    print('\nJelentkezz be a Kréta oldalán (ha kéri, ott oldd meg a CAPTCHA-t és add meg a kétlépcsős azonosítás kódját).');
    print('Amikor egy "Nem található" vagy "mobil.e-kreta.hu" kezdetű oldalra dob,');
    print('KERESD MEG A CÍMSORBAN A "code=" RÉSZT, ÉS MÁSOLD KI CSAK AZ UTÁNA LÉVŐ KÓDOT!');
    print('(Például: 14EC942D... a következő & jelig)');

    String pastedCode = '';
    while (pastedCode.isEmpty) {
      if (Platform.isWindows) {
        pastedCode = Utf8Input(prompt: 'Ide másold be a kódot (vagy a teljes linket)').interact().trim();
      } else {
        stdout.write('Ide másold be a kódot (vagy a teljes linket): ');
        pastedCode = stdin.readLineSync()?.trim() ?? '';
      }

      if (pastedCode.isEmpty || pastedCode == 'P') {
        pastedCode = '';
      }
    }

    print('\nBelépés folyamatban a kóddal...');
    return _client!.webLogin(pastedCode);
  }
}
