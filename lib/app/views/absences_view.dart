part of '../cli_app.dart';

extension PalaAppAbsencesView on PalaApp {
  Future<void> _showAbsences() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Mulasztások',
          options: [
            'Legutóbbi 10 mulasztás',
            'Összes mulasztás listázása',
            'Szülői igazolás keretfigyelő',
            'Szülői / Orvosi igazolás-kérvény készítése',
            'Veszélyzóna Kalkulátor (250 órás határ)',
            'Vissza'
          ],
        ).interact();
  
        if (action == 5) return;
        _clearScreen();
        
        final absences = await _client!.getAbsences();
        if (absences == null) {
          print('Nem sikerült lekérdezni a mulasztásokat.');
          print('');
          continue;
        }

        if (action == 2) {
          await _showParentalQuotaTracker(absences);
          continue;
        }

        if (action == 3) {
          await _showAbsenceCertificateGenerator(absences);
          continue;
        }

        if (action == 4) {
          _showAbsenceDangerZone(absences);
          continue;
        }

        print('\n--- Mulasztások ---');
        if (absences.isEmpty) {
          print('Nincsenek mulasztások.');
        } else {
          absences.sort((a, b) {
            final dateA = a.date ?? DateTime(2000);
            final dateB = b.date ?? DateTime(2000);
            return dateB.compareTo(dateA); // Legújabb elöl
          });
  
          final limit = action == 0 ? 10 : absences.length;
          for (var absence in absences.take(limit)) {
            final dateStr = absence.date?.toString().split(' ').first.split('T').first ?? '';
            final subject = absence.subject;
            final status = absence.status;
            
            String coloredStatus = status;
            final sLower = status.toLowerCase();
            final tLower = absence.type?.toLowerCase() ?? '';
            
            if (tLower == 'késés' || sLower == 'késés') {
              coloredStatus = '\x1B[38;5;208m$status\x1B[0m';
            } else if (sLower == 'igazolt') {
              coloredStatus = '\x1B[92m$status\x1B[0m';
            } else if (sLower == 'igazolando' || sLower == 'igazolandó') {
              coloredStatus = '\x1B[33m$status\x1B[0m';
            } else if (sLower == 'igazolatlan') {
              coloredStatus = '\x1B[31m$status\x1B[0m';
            }
            
            print('[$dateStr] $subject ($coloredStatus)');
          }
          if (action == 0 && absences.length > 10) {
            print('  ... és még ${absences.length - 10} régebbi mulasztás.');
          }
        }
        _pause();
      }
    }

  Future<void> _showAverages() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Tantárgyi átlagok',
          options: [
            'Átlagok részletesen (Táblázat)',
            'Átlagok grafikonon (Oszlopdiagram)',
            'Célátlag kalkulátor',
            'Bizonyítvány Tervező (Minden tárgy célzása)',
            'Jegy-trendek (Éves Grafikon)',
            'Vissza'
          ],
        ).interact();
  
        if (action == 5) return;
        if (action == 2) {
          await _showTargetAverageCalculator();
          continue;
        }
        if (action == 3) {
          await _showBulkGradeTargeter();
          continue;
        }
        
        if (action == 4) {
          _clearScreen();
          print('\n--- Jegy-trendek (Éves Grafikon) ---');
          print('Adatok lekérése...');
          final grades = await _client!.getGrades();
          if (grades != null && grades.isNotEmpty) {
            // 1. Generate weekly cumulative average trend data
            final now = DateTime.now();
            final currentYear = now.month >= 9 ? now.year : now.year - 1;
            final schoolStart = DateTime(currentYear, 9, 1);
            
            final values = <double>[];
            final labels = <String>[];
            
            DateTime currentWeekStart = schoolStart;
            while (currentWeekStart.isBefore(now)) {
              final cutoff = currentWeekStart.add(const Duration(days: 7));
              
              final gradesUpToWeek = grades.where((g) =>
                  g.date != null &&
                  g.date!.isBefore(cutoff) &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade
              ).toList();
              
              if (gradesUpToWeek.isNotEmpty) {
                double wSum = 0.0;
                double valSum = 0.0;
                for (var g in gradesUpToWeek) {
                  double w = g.weight;
                  if (w == 0) w = 100;
                  valSum += g.numericValue! * w;
                  wSum += w;
                }
                if (wSum > 0) {
                  values.add(valSum / wSum);
                  
                  final weekMonth = currentWeekStart.month;
                  final monthNamesShort = {
                    9: 'Sze', 10: 'Okt', 11: 'Nov', 12: 'Dec',
                    1: 'Jan', 2: 'Feb', 3: 'Már', 4: 'Ápr',
                    5: 'Máj', 6: 'Jún', 7: 'Júl', 8: 'Aug'
                  };
                  
                  // Label only the first week of each month
                  final isFirstOfMonth = values.length == 1 || 
                      currentWeekStart.month != currentWeekStart.subtract(const Duration(days: 7)).month;
                  
                  if (isFirstOfMonth) {
                    labels.add(monthNamesShort[weekMonth] ?? '   ');
                  } else {
                    labels.add('   ');
                  }
                }
              }
              currentWeekStart = currentWeekStart.add(const Duration(days: 7));
            }

            // 2. Grade distribution calculations
            final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
            int validGradesCount = 0;
            double sum = 0.0;
            double weightSum = 0.0;
            
            for (var g in grades) {
              if (g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade) {
                final val = g.numericValue!.toInt();
                distribution[val] = (distribution[val] ?? 0) + 1;
                validGradesCount++;
                
                double w = g.weight;
                if (w == 0) w = 100;
                sum += g.numericValue! * w;
                weightSum += w;
              }
            }

            // 3. Best/Worst month calculations (non-cumulative)
            final monthNamesLong = {
              9: 'Szeptember', 10: 'Október', 11: 'November', 12: 'December',
              1: 'Január', 2: 'Február', 3: 'Március', 4: 'Április',
              5: 'Május', 6: 'Június', 7: 'Július', 8: 'Augusztus'
            };
            
            final monthlySums = <int, double>{};
            final monthlyWeightSums = <int, double>{};
            for (var g in grades) {
              if (g.date != null &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade) {
                final m = g.date!.month;
                double w = g.weight;
                if (w == 0) w = 100;
                monthlySums[m] = (monthlySums[m] ?? 0.0) + g.numericValue! * w;
                monthlyWeightSums[m] = (monthlyWeightSums[m] ?? 0.0) + w;
              }
            }
            
            int? bestMonth;
            double bestMonthAvg = 0.0;
            int? worstMonth;
            double worstMonthAvg = 99.0;
            
            monthlySums.forEach((m, sumVal) {
              final wSum = monthlyWeightSums[m] ?? 0.0;
              if (wSum > 0) {
                final avg = sumVal / wSum;
                if (avg > bestMonthAvg) {
                  bestMonthAvg = avg;
                  bestMonth = m;
                }
                if (avg < worstMonthAvg) {
                  worstMonthAvg = avg;
                  worstMonth = m;
                }
              }
            });

            int modeGrade = 5;
            int modeCount = 0;
            distribution.forEach((grade, count) {
              if (count > modeCount) {
                modeCount = count;
                modeGrade = grade;
              }
            });

            // 4. Render Dashboard
            if (values.isNotEmpty) {
              print('\nAz év során így változott a kumulatív átlagod (hetente követve):');
              print(ChartGenerator.generateLineChart(values, labels: labels));
            } else {
              print('Nincsenek számítható jegyek a grafikonhoz.');
            }

            print('\n\x1B[1mTanulmányi statisztikák:\x1B[0m');
            final currentAvgStr = weightSum > 0 ? (sum / weightSum).toStringAsFixed(2) : '-';
            final bestMonthStr = bestMonth != null ? '${monthNamesLong[bestMonth]} (${bestMonthAvg.toStringAsFixed(2)})' : '-';
            final worstMonthStr = worstMonth != null ? '${monthNamesLong[worstMonth]} (${worstMonthAvg.toStringAsFixed(2)})' : '-';
            final modeName = {5: '5-ös', 4: '4-es', 3: '3-as', 2: '2-es', 1: '1-es'};
            final modeStr = modeCount > 0 ? '${modeName[modeGrade]} ($modeCount db)' : '-';
            
            print('  • Jelenlegi átlag: \x1B[1;36m$currentAvgStr\x1B[0m');
            print('  • Összes jegy száma: \x1B[1m$validGradesCount db\x1B[0m');
            print('  • Leggyakoribb jegy: \x1B[1m$modeStr\x1B[0m');
            if (bestMonth != null) {
              print('  • Legjobb hónap: \x1B[92m$bestMonthStr\x1B[0m');
            }
            if (worstMonth != null) {
              print('  • Leggyengébb hónap: \x1B[91m$worstMonthStr\x1B[0m');
            }

            print('\n\x1B[1mJegyek eloszlása:\x1B[0m');
            final gradeLabels = {
              5: '5 (Kiváló)   ',
              4: '4 (Jó)       ',
              3: '3 (Közepes)  ',
              2: '2 (Elégséges)',
              1: '1 (Elégtelen)',
            };
            
            final gradeColors = {
              5: '\x1B[94m', // Blue
              4: '\x1B[92m', // Green
              3: '\x1B[93m', // Yellow
              2: '\x1B[38;5;208m', // Orange
              1: '\x1B[91m', // Red
            };
            
            for (int grade = 5; grade >= 1; grade--) {
              final count = distribution[grade] ?? 0;
              final percent = validGradesCount > 0 ? (count / validGradesCount * 100) : 0.0;
              
              int barWidth = 0;
              if (validGradesCount > 0) {
                barWidth = ((count / validGradesCount) * 30).round();
              }
              final bar = '█' * barWidth;
              final color = gradeColors[grade] ?? '\x1B[0m';
              
              final label = gradeLabels[grade]!;
              final countStr = '$count db'.padLeft(5);
              final pctStr = '${percent.toStringAsFixed(1)}%'.padLeft(6);
              
              print('  $label | $color$bar\x1B[0m${" " * (30 - barWidth)} | $countStr ($pctStr)');
            }
          } else {
            print('Nincs elég adat a grafikonhoz.');
          }
          _pause();
          continue;
        }

        if (action == 1) {
          _clearScreen();
          print('\n--- Átlagok grafikonon ---');
          print('Adatok lekérése...');
          final averages = await _client!.getAverages();
          if (averages != null) {
            if (averages.isEmpty) {
              print('Nincsenek átlagok.');
            } else {
              final Map<String, double> chartData = {};
              for (var avg in averages) {
                final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
                final valueStr = avg['Ertek']?.toString() ?? '0';
                final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
                if (value > 0) {
                  chartData[subject] = value;
                }
              }
              if (chartData.isNotEmpty) {
                print(ChartGenerator.generateBarChart(chartData));
              } else {
                for (var avg in averages) {
                  final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
                  final value = avg['Ertek']?.toString() ?? '-';
                  print('$subject: $value');
                }
              }
            }
          } else {
            print('Nem sikerült lekérdezni az átlagokat.');
          }
          _pause();
          continue;
        }
        
        _clearScreen();
        print('\n--- Tantárgyi átlagok részletesen ---');
        print('Adatok lekérése...');
        
        final results = await Future.wait([
          _client!.getAverages(),
          _client!.getGroupAverages(),
          _client!.getGrades(),
        ]);
        
        final List<dynamic>? averages = results[0];
        final List<dynamic>? classAverages = results[1];
        final List<Grade>? grades = results[2] as List<Grade>?;

        if (averages != null) {
          if (averages.isEmpty) {
            print('Nincsenek átlagok.');
          } else {
            final Map<String, double> classAvgMap = {};
            if (classAverages != null) {
              for (var item in classAverages) {
                if (item is Map) {
                  final subject = item['Tantargy']?['Nev'] ?? 'Ismeretlen';
                  final valStr = (item['OsztalyAtlag'] ?? item['Atlag'] ?? item['Ertek'] ?? '0').toString();
                  final val = double.tryParse(valStr.replaceAll(',', '.')) ?? 0.0;
                  if (val > 0) {
                    classAvgMap[subject.toLowerCase()] = val;
                  }
                }
              }
            }

            print('\n--------------------------------------------------------------------------------');
            print('Tantárgy                     | Saját | Osztály | Eltérés | Trend | Határhelyzet');
            print('--------------------------------------------------------------------------------');
            for (var avg in averages) {
              final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final valStr = avg['Ertek']?.toString() ?? '0';
              final val = double.tryParse(valStr.replaceAll(',', '.')) ?? 0.0;
              if (val <= 0) continue;

              final classAvg = classAvgMap[subject.toLowerCase()] ?? 0.0;
              
              String classAvgStr = classAvg > 0 ? classAvg.toStringAsFixed(2) : ' - ';
              String devStr = ' - ';
              if (classAvg > 0) {
                final dev = val - classAvg;
                final devSign = dev >= 0 ? '+' : '';
                final devColor = dev >= 0 ? '\x1B[92m' : '\x1B[31m';
                devStr = '$devColor$devSign${dev.toStringAsFixed(2)}\x1B[0m';
              }

              final subjGrades = (grades ?? []).where((g) =>
                  g.subject.toLowerCase() == subject.toLowerCase() &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade
              ).toList();
              subjGrades.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
              String trendStr = '→';
              if (subjGrades.isNotEmpty) {
                final last3 = subjGrades.take(3).toList();
                final last3Avg = last3.map((g) => g.numericValue!).reduce((a, b) => a + b) / last3.length;
                if (last3Avg > val + 0.1) {
                  trendStr = '\x1B[92m↗\x1B[0m';
                } else if (last3Avg < val - 0.1) {
                  trendStr = '\x1B[31m↘\x1B[0m';
                }
              }

              String warningStr = '';
              for (double boundary in [1.5, 2.5, 3.5, 4.5]) {
                if ((val - boundary).abs() <= 0.101) {
                  final targetInt = boundary.ceil();
                  if (val < boundary) {
                    warningStr = '\x1B[33mKözel a $targetInt-eshez!\x1B[0m';
                  } else {
                    warningStr = '\x1B[31mVeszélyben a $targetInt-es!\x1B[0m';
                  }
                }
              }

              final displaySubj = subject.length > 28 ? '${subject.substring(0, 25)}...' : subject;
              
              final pSubj = displaySubj.padRight(28);
              final pSajat = val.toStringAsFixed(2).padRight(5);
              final pClass = classAvgStr.padRight(7);
              
              final devLen = classAvg > 0 ? 5 : 3;
              final pDev = devStr + ' ' * (7 - devLen);
              
              final pTrend = trendStr + '   ';

              print('$pSubj | $pSajat | $pClass | $pDev | $pTrend | $warningStr');
            }
            print('--------------------------------------------------------------------------------');
          }
        } else {
          print('Nem sikerült lekérdezni az átlagokat.');
        }
        _pause();
      }
    }

  Future<void> _showBulkGradeTargeter() async {
    if (!await _ensureClientReady()) return;
    
    _clearScreen();
    print('\n--- Bizonyítvány Tervező (Minden tárgy célzása) ---');
    print('Adatok lekérése...');
    
    final grades = await _client!.getGrades();
    if (grades == null || grades.isEmpty) {
      print('Nincsenek elérhető jegyek a tervezéshez.');
      _pause();
      return;
    }

    // Group grades by subject
    final Map<String, List<Grade>> subjectGrades = {};
    for (var g in grades) {
      if (g.isSummaryGrade) continue;
      if (g.numericValue == null || g.numericValue! < 1 || g.numericValue! > 5) continue;
      
      final subj = g.subject;
      subjectGrades.putIfAbsent(subj, () => []);
      subjectGrades[subj]!.add(g);
    }

    if (subjectGrades.isEmpty) {
      print('Nincsenek érdemi (1-5) jegyeid a tervezéshez.');
      _pause();
      return;
    }

    final subjects = subjectGrades.keys.toList()..sort();
    
    print('\n--------------------------------------------------------------------------------');
    print('Tantárgy                     | Jelenlegi | Cél | Szükséges 100%-os 5-ösök száma');
    print('--------------------------------------------------------------------------------');
    
    for (var subj in subjects) {
      final items = subjectGrades[subj]!;
      double sum = 0.0;
      double weightSum = 0.0;
      for (var g in items) {
        double w = g.weight;
        if (w == 0) w = 100.0;
        sum += g.numericValue! * w;
        weightSum += w;
      }
      
      final currentAvg = sum / weightSum;
      
      // Determine the target and target average threshold
      double targetThreshold = 4.5;
      int targetInt = 5;
      
      if (currentAvg >= 4.5) {
        targetInt = 5;
        targetThreshold = 5.0;
      } else if (currentAvg >= 3.5) {
        targetInt = 5;
        targetThreshold = 4.5;
      } else if (currentAvg >= 2.5) {
        targetInt = 4;
        targetThreshold = 3.5;
      } else if (currentAvg >= 1.5) {
        targetInt = 3;
        targetThreshold = 2.5;
      } else {
        targetInt = 2;
        targetThreshold = 1.5;
      }

      String resultStr = '';
      if (currentAvg >= 4.5) {
        resultStr = '\x1B[92mElérted az 5-öst!\x1B[0m';
      } else {
        final requiredFives = (targetThreshold * weightSum - sum) / (500 - targetThreshold * 100);
        final count = requiredFives.ceil();
        if (count <= 0) {
          resultStr = '\x1B[92mMegvan a cél!\x1B[0m';
        } else {
          resultStr = '\x1B[1;36m$count db 5-ös\x1B[0m';
        }
      }
      
      final displaySubj = subj.length > 28 ? '${subj.substring(0, 25)}...' : subj;
      final pSubj = AppState.instance.applyAlias(displaySubj).padRight(28);
      final pAvg = currentAvg.toStringAsFixed(2).padRight(9);
      final pTarget = targetInt.toString().padRight(3);
      
      print('$pSubj | $pAvg | $pTarget | $resultStr');
    }
    print('--------------------------------------------------------------------------------');
    _pause();
  }

  void _showAbsenceDangerZone(List<Absence> absences) {
    _clearScreen();
    print('\n--- Veszélyzóna Kalkulátor ---');
    print('Kiszámoljuk, mennyire vagy közel a kritikus 250 órás (vagy 30%-os) határhoz.');
    int totalAbsences = absences.length;
    double percent = (totalAbsences / 250.0) * 100;
    print('Összes mulasztott órád: \x1B[1;36m$totalAbsences / 250\x1B[0m (\x1B[1;33m${percent.toStringAsFixed(1)}%\x1B[0m)');
    
    if (totalAbsences >= 250) {
      print('\x1B[1;31m[!] FIGYELEM: Átlépted a 250 órás határt! Osztályozóvizsgára kötelezhetnek!\x1B[0m');
    } else if (totalAbsences >= 200) {
      print('\x1B[1;31m[!] KÖZEL A HATÁR: Nagyon vigyázz, majdnem elérted a 250 órát!\x1B[0m');
    } else if (totalAbsences >= 150) {
      print('\x1B[1;33m[!] FIGYELMEZTETÉS: Kezd felgyűlni a hiányzásod.\x1B[0m');
    } else {
      print('\x1B[1;32m[OK] Biztonságos zónában vagy.\x1B[0m');
    }

    final Map<String, int> missedBySubject = {};
    for (var a in absences) {
      final s = AppState.instance.applyAlias(a.subject);
      missedBySubject[s] = (missedBySubject[s] ?? 0) + 1;
    }
    print('\nTantárgyak szerinti mulasztások (Figyelj a 30%-os szabályra!):');
    final sortedMissed = missedBySubject.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (var e in sortedMissed.take(5)) {
      print(' - ${e.key}: \x1B[1;33m${e.value} óra\x1B[0m');
    }
    print('');
    _pause();
  }

  Future<void> _showParentalQuotaTracker(List<Absence> absences) async {
    _clearScreen();
    print('\n--- Szülői Igazolás Keretfigyelő ---');
    
    final quota = AppState.instance.parentalQuota;
    
    // Group absences by date where type or status indicates parental excuse
    final Map<String, List<Absence>> parentalAbsencesByDate = {};
    for (var a in absences) {
      final t = (a.type ?? '').toLowerCase();
      final s = a.status.toLowerCase();
      
      final isParental = t.contains('szülő') || t.contains('gondviselő') || 
                         s.contains('szülő') || s.contains('gondviselő');
                         
      if (isParental) {
        final dateStr = a.date?.toString().split(' ').first.split('T').first ?? 'Ismeretlen dátum';
        parentalAbsencesByDate.putIfAbsent(dateStr, () => []);
        parentalAbsencesByDate[dateStr]!.add(a);
      }
    }

    final usedDays = parentalAbsencesByDate.keys.length;
    final remainingDays = quota - usedDays;
    int totalParentalLessons = 0;
    for (var list in parentalAbsencesByDate.values) {
      totalParentalLessons += list.length;
    }

    print('Iskolai szülői igazolási keret: \x1B[1;36m$quota nap / tanév\x1B[0m');
    print('Felhasznált napok:              \x1B[1;33m$usedDays nap\x1B[0m ($totalParentalLessons tanítási óra)');
    
    if (remainingDays < 0) {
      print('Hátralévő keret:                \x1B[1;31m${remainingDays.abs()} nappal TÚLLÉPVE!\x1B[0m');
      print('\n\x1B[1;31m[!] FIGYELEM: Átlépted a szülői igazolások megengedett keretét!\x1B[0m');
      print('Az iskola házirendje szerint a további hiányzásokhoz orvosi igazolás vagy igazgatói engedély szükséges.');
    } else if (remainingDays == 0) {
      print('Hátralévő keret:                \x1B[1;31m0 nap (Keret kimerült)\x1B[0m');
      print('\n\x1B[1;33m[!] FIGYELMEZTETÉS: Minden szülői igazolási napodat felhasználtad!\x1B[0m');
    } else if (remainingDays == 1) {
      print('Hátralévő keret:                \x1B[1;33m1 nap\x1B[0m');
      print('\n\x1B[1;33m[!] Már csak 1 igazolható napod maradt a tanévben.\x1B[0m');
    } else {
      print('Hátralévő keret:                \x1B[1;32m$remainingDays nap\x1B[0m');
      print('\n\x1B[1;32m[OK] Rendelkezel még szabad szülői igazolási kerettel.\x1B[0m');
    }

    if (parentalAbsencesByDate.isNotEmpty) {
      print('\n--- Felhasznált Szülői Igazolások Részletesen ---');
      final sortedDates = parentalAbsencesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
      for (var date in sortedDates) {
        final items = parentalAbsencesByDate[date]!;
        final subjects = items.map((e) => AppState.instance.applyAlias(e.subject)).toSet().join(', ');
        print(' - \x1B[1m$date\x1B[0m (${items.length} óra): $subjects');
      }
    } else {
      print('\nMég nem használtál fel szülői igazolást ebben a tanévben.');
    }

    print('\n[K] Keret módosítása  |  [Enter] Vissza');
    stdout.write('> ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == 'k') {
      final newQuotaStr = Utf8Input(prompt: 'Új szülői igazolási keret (napok száma)').interact().trim();
      final newQuota = int.tryParse(newQuotaStr);
      if (newQuota != null && newQuota > 0 && newQuota <= 30) {
        AppState.instance.setParentalQuota(newQuota);
        print('\x1B[1;32m[OK] Szülői keret sikeresen beállítva: $newQuota nap.\x1B[0m');
        _pause();
      }
    }
  }

  Future<void> _showAbsenceCertificateGenerator(List<Absence> absences) async {
    _clearScreen();
    print('\n--- Szülői / Orvosi Igazolás-kérvény Készítése ---');
    print('Hivatalos mulasztási igazolás vagy kérvény generálása az osztályfőnöknek.\n');

    // Filter unexcused or pending absences
    final unexcused = absences.where((a) {
      final s = a.status.toLowerCase();
      final t = (a.type ?? '').toLowerCase();
      return s == 'igazolando' || s == 'igazolandó' || s == 'igazolatlan' || t == 'igazolandó' || t == 'igazolatlan';
    }).toList();

    // Group unexcused by date
    final Map<String, List<Absence>> unexcusedByDate = {};
    for (var a in unexcused) {
      final dateStr = a.date?.toString().split(' ').first.split('T').first ?? 'Ismeretlen dátum';
      unexcusedByDate.putIfAbsent(dateStr, () => []);
      unexcusedByDate[dateStr]!.add(a);
    }

    final modeOptions = <String>[];
    if (unexcusedByDate.isNotEmpty) {
      modeOptions.add('Igazolandó mulasztások kiválasztása a Krétából (${unexcusedByDate.length} nap érhető el)');
    }
    modeOptions.add('Egyéni dátumtartomány megadása');
    modeOptions.add('Mégse');

    final modeChoice = Select(
      prompt: 'Válassz forrást az igazoláshoz',
      options: modeOptions,
    ).interact();

    if (modeChoice == modeOptions.length - 1) return;

    List<String> selectedDates = [];
    int totalMissedHours = 0;
    String missedDetails = '';

    final isKretas = unexcusedByDate.isNotEmpty && modeChoice == 0;

    if (isKretas) {
      final sortedUnexcusedDates = unexcusedByDate.keys.toList()..sort((a, b) => b.compareTo(a));
      final dateOptions = sortedUnexcusedDates.map((d) {
        final items = unexcusedByDate[d]!;
        final subjs = items.map((e) => AppState.instance.applyAlias(e.subject)).take(3).join(', ');
        return '$d (${items.length} óra: $subjs${items.length > 3 ? '...' : ''})';
      }).toList();

      final dateIndex = Select(
        prompt: 'Válaszd ki az igazolandó napot',
        options: dateOptions,
      ).interact();

      final chosenDate = sortedUnexcusedDates[dateIndex];
      selectedDates = [chosenDate];
      final items = unexcusedByDate[chosenDate]!;
      totalMissedHours = items.length;
      missedDetails = items.map((e) => AppState.instance.applyAlias(e.subject)).toSet().join(', ');
    } else {
      final nowStr = DateTime.now().toString().split(' ').first;
      final startDate = Utf8Input(prompt: 'Hiányzás kezdő dátuma (ÉÉÉÉ-HH-NN)', defaultValue: nowStr).interact().trim();
      final endDate = Utf8Input(prompt: 'Hiányzás záró dátuma (ÉÉÉÉ-HH-NN)', defaultValue: startDate).interact().trim();
      
      if (startDate == endDate) {
        selectedDates = [startDate];
      } else {
        selectedDates = [startDate, endDate];
      }

      final hoursStr = Utf8Input(prompt: 'Mulasztott tanítási órák száma', defaultValue: '6').interact().trim();
      totalMissedHours = int.tryParse(hoursStr) ?? 6;
      missedDetails = 'Egész napos távollét';
    }

    // Select reason
    final reasonOptions = [
      'Betegség / Rosszullét (Orvosi kezelés nélkül, szülői felelősségre)',
      'Orvosi vizsgálat / Szakorvosi ellátás',
      'Családi ok / Rendkívüli családi esemény',
      'Hivatalos tanulmányi verseny / Iskolai rendezvény',
      'Egyéni indoklás megadása',
      'Mégse'
    ];

    final reasonChoice = Select(
      prompt: 'Válaszd ki a hiányzás indokát',
      options: reasonOptions,
    ).interact();

    if (reasonChoice == reasonOptions.length - 1) return;

    String reasonText = reasonOptions[reasonChoice];
    if (reasonChoice == 4) {
      reasonText = Utf8Input(prompt: 'Add meg a pontos indoklást').interact().trim();
      if (reasonText.isEmpty) reasonText = 'Családi ok';
    }

    // Get student details
    final student = await _client!.getStudentData(silent: true);
    final studentName = student?.name ?? 'Diák';
    final instituteName = student?.institutionName ?? 'Oktatási Intézmény';
    final defaultGuardian = (student?.guardians != null && student!.guardians.isNotEmpty)
        ? (student.guardians.first['Nev'] ?? student.guardians.first['name'] ?? student.mothersName ?? 'Gondviselő')
        : (student?.mothersName ?? 'Gondviselő');

    final guardianName = Utf8Input(
      prompt: 'Gondviselő / Szülő neve',
      defaultValue: defaultGuardian.toString(),
    ).interact().trim();

    final dateRangeStr = selectedDates.length == 1
        ? selectedDates.first
        : '${selectedDates.first} - ${selectedDates.last}';

    final todayStr = DateTime.now().toString().split(' ').first;

    final documentText = '''
================================================================================
                          SZÜLŐI IGAZOLÁS / NYILATKOZAT
================================================================================

Címzett:
  $instituteName
  Tisztelt Osztályfőnök / Iskolavezetés

Alulírott $guardianName, mint $studentName tanuló gondviselője, ezúton igazolom és kérem gyermekem távollétének igazolását.

A mulasztás adatai:
  - Időszak:      $dateRangeStr
  - Órák száma:   $totalMissedHours tanítási óra
  - Érintett:     $missedDetails
  - Távollét oka: $reasonText

Kérem a Tisztelt Osztályfőnököt, hogy a fent megjelölt időszakban történt mulasztást a hatályos házirend és szülői jogköröm alapján szíveskedjék IGAZOLTNAK tekinteni.

Kelt: $todayStr


Tisztelettel:


_____________________________
$guardianName
(Gondviselő aláírása)
================================================================================
''';

    _clearScreen();
    print(documentText);

    final action = Select(
      prompt: 'Mit szeretnél tenni a dokumentummal?',
      options: [
        'Küldés az Osztályfőnöknek (Web / Terminál Üzenetküldővel)',
        'Mentés fájlba (Asztal / Dokumentumok)',
        'Mindkettő (Küldés és Mentés)',
        'Mégse'
      ],
    ).interact();

    if (action == 3) return;

    if (action == 1 || action == 2) {
      await _exportExcuseDocument(documentText, 'Pala_Szuloi_Igazolas_${selectedDates.first.replaceAll('-', '_')}');
    }

    if (action == 0 || action == 2) {
      final teachers = await _client!.getTeachers();
      if (teachers != null && teachers.isNotEmpty) {
        print('\n\x1B[1;33m[+] Üzenetküldő megnyitása az igazolás elküldéséhez...\x1B[0m\n');
        
        final subject = 'Szülői igazolás ($dateRangeStr) - $studentName';

        final result = await WebComposerServer.start(
          teachers: teachers,
          preselectedSubject: subject,
          studentName: guardianName,
        );

        if (result != null) {
          final success = await _client!.sendMessage(
            subject: result.subject,
            text: result.text,
            recipientIds: result.recipientIds,
            attachmentPaths: result.attachmentPaths,
          );
          if (success) {
            print('\n\x1B[1;32m[OK] Az igazolás sikeresen elküldve a Kréta rendszeren keresztül!\x1B[0m\n');
          } else {
            print('\n\x1B[1;31m[HIBA] Nem sikerült elküldeni az igazolást.\x1B[0m\n');
          }
        }
      } else {
        print('\nNem sikerült lekérdezni a tanárok listáját az üzenetküldéshez.');
      }
      _pause();
    }
  }

  Future<void> _exportExcuseDocument(String content, String defaultBaseName) async {
    try {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final desktop = Directory(p.join(home, 'Desktop'));
      final targetDir = desktop.existsSync() ? desktop.path : home;
      final targetFile = File(p.join(targetDir, '$defaultBaseName.txt'));

      targetFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
      targetFile.writeAsStringSync(content, mode: FileMode.write);
      print('\n\x1B[1;32m[OK] Igazolás dokumentum sikeresen elmentve:\x1B[0m');
      print('    \x1B[1;36m${targetFile.path}\x1B[0m\n');
    } catch (e) {
      print('\nHiba a dokumentum mentése során: $e');
    }
    _pause();
  }
}
