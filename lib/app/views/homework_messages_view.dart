part of '../cli_app.dart';

extension PalaAppHomeworkView on PalaApp {
  Future<void> _showHomework() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Házi feladatok',
          options: ['Legutóbbi 10 házi feladat', 'Összes házi feladat', 'Vissza'],
        ).interact();
  
        if (action == 2) return;
        _clearScreen();
        print('\n--- Házi feladatok ---');
        final hw = await _client!.getHomework();
        if (hw != null) {
          if (hw.isEmpty) {
            print('Nincs megjeleníthető házi feladat.');
          } else {
            final limit = action == 0 ? 10 : hw.length;
            for (var item in hw.take(limit)) {
              final date = item.assignedDate?.toString().split(' ').first.split('T').first ?? '';
              final subject = item.subject;
              final text = item.text;
              
              print('[$date] $subject');
              print('  Feladat: $text');
              print('  Határidő: ${item.deadline?.toString().split(' ').first.split('T').first ?? '?'}');
              print('---');
            }
            if (action == 0 && hw.length > 10) {
              print('  ... és még ${hw.length - 10} régebbi házi feladat.');
            }
          }
        } else {
          print('Nem sikerült lekérdezni a házi feladatokat.');
        }
        _pause();
      }
    }

  Future<void> _showMessages() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Üzenetek',
          options: [
            '[+] Új üzenet küldése tanárnak',
            'Legutóbbi 5 üzenet (Gyorsolvasás)',
            'Üzenetek listázása és részletek',
            'Vissza'
          ],
        ).interact();
  
        if (action == 3) return;
        if (action == 0) {
          await _sendMessageFlow();
          continue;
        }

        _clearScreen();
        print('\n--- Üzenetek ---');
        final messages = await _client!.getMessages();
        if (messages == null) {
          print('Nem sikerült lekérdezni az üzeneteket.');
          _pause();
          continue;
        }

        if (messages.isEmpty) {
          print('Nincs beérkezett üzenet.');
          _pause();
          continue;
        }

        messages.sort((a, b) {
          final dateA = a.sentDate ?? DateTime(2000);
          final dateB = b.sentDate ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

        if (action == 1) {
          final limit = 5;
          print('Üzenetek teljes tartalmának letöltése...\n');
          for (var msg in messages.take(limit)) {
            final dateStr = msg.sentDate?.toString().substring(0, 16) ?? '';
            final felado = msg.senderName;
            final targy = msg.subject;
            final isRead = msg.isRead;
            
            final full = await _loadFullMessage(msg);
            final text = _messageBodyText(msg, full);
            final attachments = (full ?? msg).attachments;

            String marker = isRead ? " " : "*";
            print('----------------------------------------');
            print('[$marker] Dátum: $dateStr');
            print('Feladó: \x1B[1;36m$felado\x1B[0m');
            print('Tárgy: \x1B[1;33m$targy\x1B[0m');
            print('Üzenet:\n$text\n');
            
            if (attachments.isNotEmpty) {
              print('Csatolmányok:');
              for (var att in attachments) {
                print('  - ${att.name} (ID: ${att.id})');
              }
              final downloadAns = Utf8Input(prompt: 'Szeretnél letölteni csatolmányt ebből az üzenetből? (i/N)').interact().trim().toLowerCase();
              if (downloadAns == 'i' || downloadAns == 'y') {
                await _downloadAttachmentFlow(attachments);
              }
            }
          }
          _pause();
        } else {
          // List messages and let user choose using PaginatedMenu
          final List<String> formattedOptions = [];
          for (var msg in messages) {
            final dateStr = msg.sentDate?.toString().substring(0, 10) ?? '';
            final felado = msg.senderName;
            final targy = msg.subject.length > 30 ? '${msg.subject.substring(0, 27)}...' : msg.subject;
            final marker = msg.isRead ? " " : "*";
            formattedOptions.add('[$marker] $dateStr - $felado - $targy');
          }
          
          while (true) {
            _clearScreen();
            _showMainMenuBanner();
            
            final choice = PaginatedMenu(
              prompt: 'Válassz üzenetet a megtekintéshez:',
              allOptions: formattedOptions,
              pageSize: 15,
            ).interact();

            if (choice == -1) {
              break;
            }

            final msg = messages[choice];
            _clearScreen();
            print('\n--- Üzenet Részletei ---');
            final dateStr = msg.sentDate?.toString().substring(0, 16) ?? '';
            print('Dátum: $dateStr');
            print('Feladó: \x1B[1;36m${msg.senderName}\x1B[0m');
            print('Tárgy: \x1B[1;33m${msg.subject}\x1B[0m');
            print('----------------------------------------');

            print('Üzenet letöltése...');
            final full = await _loadFullMessage(msg);
            final attachments = (full ?? msg).attachments;
            _clearScreen();
            print('\n--- Üzenet Részletei ---');
            print('Dátum: $dateStr');
            print('Feladó: \x1B[1;36m${msg.senderName}\x1B[0m');
            print('Tárgy: \x1B[1;33m${msg.subject}\x1B[0m');
            print('----------------------------------------');

            print('Szöveg:\n${_messageBodyText(msg, full)}\n');

            if (attachments.isNotEmpty) {
              print('----------------------------------------');
              print('Csatolmányok:');
              for (var att in attachments) {
                print('  - ${att.name}');
              }
              print('');
              final downloadAns = Utf8Input(prompt: 'Szeretnél letölteni valamilyen csatolmányt? (i/N)').interact().trim().toLowerCase();
              if (downloadAns == 'i' || downloadAns == 'y') {
                await _downloadAttachmentFlow(attachments);
              }
            } else {
              _pause();
            }
          }
        }
      }
    }

  Future<void> _downloadAttachmentFlow(List<MessageAttachment> attachments) async {
    if (attachments.isEmpty) return;
    
    final options = attachments.map((a) => a.name).toList();
    options.add('Mégse');
    
    final choice = Select(
      prompt: 'Válassz csatolmányt a letöltéshez:',
      options: options,
    ).interact();
    
    if (choice == options.length - 1) return;
    
    final selected = attachments[choice];
    print('Letöltés folyamatban: ${selected.name}...');
    final file = await _client!.saveAttachment(selected.id, selected.name);
    if (file != null) {
      print('\x1B[92mSikeresen letöltve! Fájl helye: ${file.path}\x1B[0m');
    } else if (_client is DemoKretaClient) {
      print('\x1B[33mDemó módban a csatolmányok nem tölthetők le.\x1B[0m');
    } else {
      print('\x1B[31mA csatolmány most nem tölthető le. Ellenőrizd az internetkapcsolatot, és próbáld újra.\x1B[0m');
    }
    _pause();
  }

  /// The message with its full text and attachments, or null when it cannot
  /// be loaded. The inbox list only carries a short preview of the body.
  Future<Message?> _loadFullMessage(Message msg) async {
    if (msg.id == 0) return null;
    try {
      return await _client!.getMessage(msg.id);
    } catch (e) {
      PalaLogger.debug('Failed to fetch message ${msg.id}: $e');
      return null;
    }
  }

  /// The body as plain text. Without the full message only the preview from
  /// the list is known, and the reader is told so.
  String _messageBodyText(Message preview, Message? full) {
    if (full != null) {
      final text = htmlToText(full.text);
      return text.isNotEmpty ? text : '(Nincs szöveges tartalom.)';
    }
    final text = htmlToText(preview.text);
    return '\x1B[33mA teljes szöveg most nem tölthető be, csak az eleje látszik.\x1B[0m\n$text';
  }

  Future<void> _sendMessageFlow() async {
    _clearScreen();
    _showMainMenuBanner();
    print('\n--- Új üzenet írása tanárnak ---');

    print('Tanárok listájának betöltése...');
    final teachers = await _client!.getTeachers() ?? [];
    if (teachers.isEmpty) {
      print('Nem található elérhető tanár az intézményben.');
      _pause();
      return;
    }

    final mode = Select(
      prompt: 'Válassz szerkesztési módot',
      options: [
        'Webes Szerkesztő (Böngészőben - Ajánlott)',
        'Helyi Szövegszerkesztő (Terminál)',
        'Mégse',
      ],
    ).interact();

    if (mode == 2) return;

    final student = await _client!.getStudentData(silent: true);
    final studentName = student?.name ?? 'Diák';

    if (mode == 0) {
      print('\n\x1B[1;33m[+] Helyi webszerver indítása és böngésző megnyitása...\x1B[0m');
      print('Az üzenet megírásához és elküldéséhez használd a megnyílt böngészőablakot.');
      print('\x1B[90m(Várakozás az elküldésre a böngészőből... Nyomj Ctrl+C-t ha meg szeretnéd szakítani)\x1B[0m\n');

      final result = await WebComposerServer.start(
        teachers: teachers,
        studentName: studentName,
      );

      if (result != null) {
        print('Üzenet fogadva a böngészőből!');
        print('Küldés a Kréta rendszeren keresztül...');
        final success = await _client!.sendMessage(
          subject: result.subject,
          text: result.text,
          recipientIds: result.recipientIds,
          attachmentPaths: result.attachmentPaths,
        );

        if (success) {
          print('\n\x1B[1;32m[OK] Az üzenet sikeresen elküldve!\x1B[0m\n');
        } else {
          print('\n\x1B[1;31m[HIBA] Hiba történt az üzenet elküldése során.\x1B[0m\n');
        }
      } else {
        print('\n\x1B[90mÜzenetküldés megszakítva.\x1B[0m\n');
      }
      _pause();
    } else if (mode == 1) {
      final teacherOptions = teachers.map((t) {
        final name = t['nev'] ?? t['name'] ?? 'Tanár';
        final sub = t['tantargyak'] ?? t['subjects'] ?? '';
        return sub.toString().isNotEmpty ? '$name ($sub)' : name.toString();
      }).toList();
      teacherOptions.add('Mégse');

      final teacherChoice = Select(
        prompt: 'Válassz címzett tanárt',
        options: teacherOptions,
      ).interact();

      if (teacherChoice == teacherOptions.length - 1) return;
      final selectedTeacher = teachers[teacherChoice];
      final recipientId = int.tryParse((selectedTeacher['azonosito'] ?? selectedTeacher['id'] ?? '0').toString()) ?? 0;

      final subject = Utf8Input(prompt: 'Üzenet tárgya').interact().trim();
      if (subject.isEmpty) {
        print('A tárgy nem lehet üres!');
        _pause();
        return;
      }

      print('\nÍrd be az üzenet szövegét:');
      final text = Utf8Input(prompt: 'Üzenet törzse').interact().trim();
      if (text.isEmpty) {
        print('Az üzenet szövege nem lehet üres!');
        _pause();
        return;
      }

      final confirm = Confirm(
        prompt: 'Biztosan elküldöd az üzenetet a következőnek: ${selectedTeacher['nev']}?',
        defaultValue: true,
      ).interact();

      if (confirm) {
        print('Küldés folyamatban...');
        final success = await _client!.sendMessage(
          subject: subject,
          text: text,
          recipientIds: [recipientId],
        );
        if (success) {
          print('\n\x1B[1;32m[OK] Az üzenet sikeresen elküldve!\x1B[0m\n');
        } else {
          print('\n\x1B[1;31m[HIBA] Hiba történt az üzenet elküldése során.\x1B[0m\n');
        }
      }
      _pause();
    }
  }

}
