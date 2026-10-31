import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala_app/state/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('hu_HU', null);
    SharedPreferences.setMockInitialValues({});
  });

  group('AppModel message recipient', () {
    test('resolves a known teacher to their own ID', () async {
      final appModel = AppModel();
      await appModel.loginDemo();

      expect(appModel.teacherIdFor('Arany Jánosné'), 2);
    });

    test('refuses to send to a name that is not an addressable teacher', () async {
      final appModel = AppModel();
      await appModel.loginDemo();

      expect(appModel.teacherIdFor('Nem Létező Tanár'), isNull);
      final sent = await appModel.sendMessage(
        recipientName: 'Nem Létező Tanár',
        subject: 'Teszt',
        messageText: 'Teszt',
      );
      expect(sent, isFalse);
      expect(appModel.errorMessage, contains('Ismeretlen címzett'));
    });
  });
}
