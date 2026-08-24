import '../models/models.dart';
import 'client.dart';
import 'demo_data.dart';

/// A mock [KretaClient] implementation for offline development, testing, and demos.
/// Returns deterministic data for "Teszt Elek" without making any network requests.
class DemoKretaClient extends KretaClient {
  DemoKretaClient() : super(instituteCode: DemoData.schoolCode) {
    accessToken = 'DEMO-ACCESS-TOKEN';
    refreshToken = 'DEMO-REFRESH-TOKEN';
  }

  @override
  Future<bool> login(String username, String password) async {
    return true;
  }

  @override
  Future<bool> webLogin(String pastedUrl) async {
    return true;
  }

  @override
  Future<bool> refreshAccessToken() async {
    return true;
  }

  @override
  Future<Student?> getStudentData({bool silent = false}) async {
    return DemoData.getStudent();
  }

  @override
  Future<List<Grade>?> getGrades() async {
    return DemoData.getGrades();
  }

  @override
  Future<List<dynamic>?> getAverages() async {
    return DemoData.getAverages();
  }

  @override
  Future<List<dynamic>?> getGroupAverages() async {
    return DemoData.getGroupAverages();
  }

  @override
  Future<List<TimetableEntry>?> getTimetable(DateTime start, DateTime end) async {
    return DemoData.getTimetable(start: start, end: end);
  }

  @override
  Future<List<Exam>?> getExams() async {
    return DemoData.getExams();
  }

  @override
  Future<List<Homework>?> getHomework({DateTime? start, String? id}) async {
    return DemoData.getHomework(start: start, id: id);
  }

  @override
  Future<List<Message>?> getMessages() async {
    return DemoData.getMessages();
  }

  @override
  Future<String?> getMessageContent(int id) async {
    final messages = DemoData.getMessages();
    final msg = messages.firstWhere((m) => m.id == id, orElse: () => messages.first);
    return msg.text;
  }

  @override
  Future<List<Absence>?> getAbsences() async {
    return DemoData.getAbsences();
  }
}
