part of '../cli_app.dart';

extension PalaAppExportView on PalaApp {
  Future<void> _exportToCsv() async {
      if (!await _ensureClientReady()) return;
      _clearScreen();
      print('\n--- Adatok exportálása (CSV) ---');
      print('Jegyek és mulasztások lekérése...');
      
      final grades = await _client!.getGrades();
      final absences = await _client!.getAbsences();
      
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
        final desktopPath = p.join(home, 'Desktop');
        final desktop = Directory(desktopPath);
        final outDir = desktop.existsSync() ? desktop.path : home;

        if (grades != null && grades.isNotEmpty) {
          final csvFile = File(p.join(outDir, 'Pala_Jegyek.csv'));
          // The shared CSV format (utils/csv.dart): BOM, ';', every value quoted.
          csvFile.writeAsStringSync(toCsv(
            ['Tantárgy', 'Érték', 'Dátum', 'Téma'],
            grades.map((g) => [g.subject, g.displayValue, csvDate(g.date), g.theme ?? '']),
          ));
          print('Jegyek elmentve: ${csvFile.path}');
        }
        
        if (absences != null && absences.isNotEmpty) {
          final csvFile = File(p.join(outDir, 'Pala_Mulasztasok.csv'));
          csvFile.writeAsStringSync(toCsv(
            ['Tantárgy', 'Dátum', 'Igazolt', 'Típus'],
            absences.map((a) => [
                  a.subject,
                  csvDate(a.date),
                  AbsenceRules.status(a) == AbsenceStatus.excused ? 'Igen' : 'Nem',
                  a.type ?? '',
                ]),
          ));
          print('Mulasztások elmentve: ${csvFile.path}');
        }
      } catch (e) {
        print('Hiba a fájlok mentése során: $e');
      }
      
      print('');
      _pause();
    }

  Future<void> _exportToGit() async {
    if (!await _ensureClientReady()) return;
    _clearScreen();
    print('\n--- Git-alapú Jegy-történet (Export & Git) ---');
    
    // Check if git is installed
    try {
      final res = Process.runSync('git', ['--version']);
      if (res.exitCode != 0) throw Exception();
    } catch (_) {
      print('\n\x1B[1;31mHiba: A Git nincs telepítve vagy nincs a PATH-ban!\x1B[0m');
      print('A funkció használatához telepítsd a Git-et (https://git-scm.com/).');
      _pause();
      return;
    }

    print('Adatok lekérése a Kréta szerverről...');
    final grades = await _client!.getGrades();
    if (grades == null || grades.isEmpty) {
      print('Nem találhatók jegyek.');
      _pause();
      return;
    }

    try {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final gitDir = Directory(p.join(home, 'Pala_Jegyek_Git'));
      
      if (!gitDir.existsSync()) {
        gitDir.createSync(recursive: true);
        Process.runSync('git', ['init'], workingDirectory: gitDir.path);
        print('Git mappa létrehozva: ${gitDir.path}');
      }

      final jsonFile = File(p.join(gitDir.path, 'jegyek.json'));
      
      final Map<String, dynamic> outputData = {};
      
      for (var g in grades) {
        final subj = g.subject;
        if (outputData[subj] == null) outputData[subj] = [];
        outputData[subj].add({
          'datum': g.date?.toString().split(' ').first.split('T').first ?? '',
          'ertek': g.displayValue,
          'tema': g.theme ?? '',
          'tipus': g.type ?? ''
        });
      }
      
      // Sort to make diffs cleaner
      for (var subj in outputData.keys) {
        final List list = outputData[subj];
        list.sort((a, b) {
          final String da = a['datum'];
          final String db = b['datum'];
          return da.compareTo(db);
        });
      }
      
      // We use a custom pretty print so diffs look nice
      final encoder = JsonEncoder.withIndent('  ');
      jsonFile.writeAsStringSync(encoder.convert(outputData));

      // Git add
      Process.runSync('git', ['add', 'jegyek.json'], workingDirectory: gitDir.path);
      
      // Check if there are changes
      final statusRes = Process.runSync('git', ['status', '--porcelain'], workingDirectory: gitDir.path);
      
      if (statusRes.stdout.toString().trim().isEmpty) {
        print('\n\x1B[32mNincs új változás (minden jegy szinkronizálva)!\x1B[0m');
        print('Mappa: ${gitDir.path}');
      } else {
        final dateStr = DateTime.now().toString().split('.')[0];
        Process.runSync('git', ['commit', '-m', 'Jegyek frissítve: $dateStr'], workingDirectory: gitDir.path);
        print('\n\x1B[1;32mSikeresen mentve és kommitolva a Git repóba!\x1B[0m');
        print('Mappa: ${gitDir.path}');
        print('Dátum: $dateStr');
      }
      
    } catch (e) {
      print('\n\x1B[1;31mHiba történt az exportálás során: $e\x1B[0m');
    }
    
    _pause();
  }

}
