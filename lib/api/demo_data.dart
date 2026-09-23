import '../models/models.dart';

/// Provides rich, realistic mock data for "Teszt Elek" in Pala TUI.
class DemoData {
  static const String studentName = 'Teszt Elek';
  static const String schoolName = 'Pala Minta Gimnázium és Technikum';
  static const String schoolCode = 'pala-minta-001';

  static Student getStudent() {
    return Student(
      name: '$studentName (Demó)',
      institutionName: schoolName,
      uid: 'DEMO-STUDENT-UID-001',
      birthName: studentName,
      birthPlace: 'Budapest',
      mothersName: 'Minta Mária',
      email: 'teszt.elek@pala.hu',
      phone: '+36 30 123 4567',
      addresses: const ['1054 Budapest, Szemere utca 12.'],
      birthDate: '2008-04-01',
      guardians: const [
        {
          'Nev': 'Minta Mária',
          'EmailCim': 'minta.maria@pelda.hu',
          'Telefonszam': '+36 30 987 6543',
          'Tipus': {'Nev': 'Anyja'}
        }
      ],
    );
  }

  /// Generates realistic grades spanning from September 1 to June 21.
  static List<Grade> getGrades() {
    final now = DateTime.now();
    final currentAcademicYear = (now.month >= 9) ? now.year : now.year - 1;
    final y1 = currentAcademicYear;
    final y2 = currentAcademicYear + 1;

    DateTime d(int year, int month, int day, [int hour = 10, int minute = 0]) {
      return DateTime(year, month, day, hour, minute);
    }

    return [
      // --- MATEMATIKA (Tanár: Dr. Számoló Szilárd) ---
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 8),
        type: 'Írásbeli röpdolgozat',
        theme: 'Halmazelmélet alapjai',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 100,
        date: d(y1, 9, 22),
        type: 'Órai feladat',
        theme: 'Algebrai átalakítások',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y1, 10, 15),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Halmazok és másodfokú egyenletek',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 3,
        textValue: 'Közepes (3)',
        weight: 100,
        date: d(y1, 11, 12),
        type: 'Szóbeli felelet',
        theme: 'Trigonometrikus függvények',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 50,
        date: d(y1, 12, 5),
        type: 'Házi feladat',
        theme: 'Szögfüggvények alkalmazása',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 200,
        date: d(y1, 12, 18),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Geometria és szögfüggvények összefoglalás',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 14),
        type: 'Írásbeli röpdolgozat',
        theme: 'Vektorok a síkban',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 2, 16),
        type: 'Órai munka',
        theme: 'Sorozatok: számtani sorozat',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 200,
        date: d(y2, 3, 19),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Számtani és mértani sorozatok',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 4, 25),
        type: 'Szóbeli felelet',
        theme: 'Kombinatorika és valószínűségszámítás',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 5, 20),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Kombinatorika és statisztika',
        teacherName: 'Dr. Számoló Szilárd',
      ),
      Grade(
        subject: 'Matematika',
        subjectCategory: 'Matematika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 15),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Dr. Számoló Szilárd',
      ),

      // --- MAGYAR NYELV ÉS IRODALOM (Tanár: Arany Jánosné) ---
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 14),
        type: 'Szóbeli felelet',
        theme: 'A felvilágosodás eszméi és műfajai',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 100,
        date: d(y1, 10, 8),
        type: 'Fogalmazás',
        theme: 'Csokonai Vitéz Mihály költészete',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y1, 11, 20),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'A magyar reformkor irodalma',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 12, 14),
        type: 'Szavalat',
        theme: 'Vörösmarty Mihály: Szózat',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 100,
        date: d(y2, 2, 20),
        type: 'Írásbeli röpdolgozat',
        theme: 'Petőfi Sándor tájköltészete',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 4, 10),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Arany János balladái',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 5, 28),
        type: 'Kiselőadás',
        theme: 'Ady Endre Új versek kötete',
        teacherName: 'Arany Jánosné',
      ),
      Grade(
        subject: 'Magyar nyelv és irodalom',
        subjectCategory: 'Humán',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 16),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Arany Jánosné',
      ),

      // --- TÖRTÉNELEM (Tanár: Kossuth Lajos) ---
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 18),
        type: 'Szóbeli felelet',
        theme: 'Az ipari forradalom kezdetei',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 200,
        date: d(y1, 10, 24),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'A polgári átalakulás kora Európában',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 11, 30),
        type: 'Írásbeli röpdolgozat',
        theme: 'Széchenyi és Kossuth programja',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y1, 12, 19),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Az 1848-49-es forradalom és szabadságharc',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 100,
        date: d(y2, 3, 10),
        type: 'Szóbeli felelet',
        theme: 'A dualizmus kora Magyarországon',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 4, 28),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Az első világháború okai és következményei',
        teacherName: 'Kossuth Lajos',
      ),
      Grade(
        subject: 'Történelem',
        subjectCategory: 'Társadalomtudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 16),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Kossuth Lajos',
      ),

      // --- ANGOL NYELV (Tanár: Smith John) ---
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 25),
        type: 'Szókincs teszt',
        theme: 'Vocabulary: Technology & Science',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 10, 18),
        type: 'Gyakorlati feladat',
        theme: 'Listening Comprehension B2',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 4,
        textValue: 'Jó (4)',
        weight: 200,
        date: d(y1, 11, 25),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Conditionals & Passive Voice',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 12, 10),
        type: 'Szóbeli felelet',
        theme: 'Speaking: Environmental issues',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 2, 28),
        type: 'Írásbeli röpdolgozat',
        theme: 'Reported Speech',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 4, 18),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'B2 Mock Exam: Reading & Writing',
        teacherName: 'Smith John',
      ),
      Grade(
        subject: 'Angol nyelv',
        subjectCategory: 'Idegen nyelv',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 17),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Smith John',
      ),

      // --- DIGITÁLIS KULTÚRA (Tanár: Neumann János) ---
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 29),
        type: 'Gyakorlati feladat',
        theme: 'Adatbázisok tervezése és SQL alapok',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y1, 11, 10),
        type: 'Projektmunka',
        theme: 'Webes TUI kliens fejlesztése Dart nyelven',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 12, 12),
        type: 'Gyakorlati feladat',
        theme: 'Algoritmusok és adatszerkezetek',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 3, 14),
        type: 'Gyakorlati feladat',
        theme: 'Hálózatbiztonság és titkosítás (AES-GCM)',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 5, 12),
        type: 'Gyakorlati témazáró dolgozat',
        theme: 'Komplex szoftverfejlesztési projekt',
        teacherName: 'Neumann János',
      ),
      Grade(
        subject: 'Digitális kultúra',
        subjectCategory: 'Informatika',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 16),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Neumann János',
      ),

      // --- FIZIKA (Tanár: Eötvös Loránd) - Bukásra áll ---
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y1, 10, 2),
        type: 'Szóbeli felelet',
        theme: 'Kinematika: egyenesvonalú egyenletes mozgás',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y1, 10, 25),
        type: 'Írásbeli röpdolgozat',
        theme: 'Vektoriális sebesség és pillanatnyi gyorsulás',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 200,
        date: d(y1, 11, 15),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Newton törvényei és dinamikai alapegyenlet',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y1, 12, 17),
        type: 'Laboratóriumi mérési jegyzőkönyv',
        theme: 'Súrlódási együttható vizsgálata lejtőn',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y2, 3, 5),
        type: 'Írásbeli röpdolgozat',
        theme: 'Munka, mechanikai energia és teljesítmény',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 3,
        textValue: 'Közepes (3)',
        weight: 100,
        date: d(y2, 4, 18),
        type: 'Házi feladat',
        theme: 'Energiamegmaradás törvényének alkalmazása',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 200,
        date: d(y2, 5, 8),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Elektrosztatika és egyenáramú áramkörök',
        teacherName: 'Eötvös Loránd',
      ),
      Grade(
        subject: 'Fizika',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 6, 17),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Eötvös Loránd',
      ),

      // --- KÉMIA (Tanár: Irinyi János) - Bukásra áll ---
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y1, 10, 12),
        type: 'Írásbeli röpdolgozat',
        theme: 'Atomszerkezet és periódusos rendszer felépítése',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y1, 11, 5),
        type: 'Órai munka',
        theme: 'Elektronkonfiguráció gyakorló feladatok',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 200,
        date: d(y1, 12, 3),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Kémiai kötések és anyagi halmazok',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y2, 3, 14),
        type: 'Szóbeli felelet',
        theme: 'Termokémia, reakciósebesség és dinamikus egyensúly',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 4, 10),
        type: 'Laboratóriumi jegyzőkönyv',
        theme: 'Sav-bázis indikátorok vizsgálata és pH mérés',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 200,
        date: d(y2, 5, 15),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Sav-bázis titrálás és redoxireakciók',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 6, 10),
        type: 'Írásbeli röpdolgozat',
        theme: 'Szervetlen kémiai reakcióegyenletek rendezése',
        teacherName: 'Irinyi János',
      ),
      Grade(
        subject: 'Kémia',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y2, 6, 18),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás (javítóvizsgára utalva)',
        teacherName: 'Irinyi János',
      ),

      // --- BIOLÓGIA (Tanár: Szent-Györgyi Albert) ---
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 10, 5),
        type: 'Kiselőadás',
        theme: 'A C-vitamin felfedezése és hatásai',
        teacherName: 'Szent-Györgyi Albert',
      ),
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y1, 11, 28),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Sejttan és biokémiai folyamatok',
        teacherName: 'Szent-Györgyi Albert',
      ),
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Szent-Györgyi Albert',
      ),
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 4, 12),
        type: 'Gyakorlati órai munka',
        theme: 'Mikroszkópos metszetkészítés',
        teacherName: 'Szent-Györgyi Albert',
      ),
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 200,
        date: d(y2, 5, 25),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Az emberi szervezet: idegrendszer és hormonok',
        teacherName: 'Szent-Györgyi Albert',
      ),
      Grade(
        subject: 'Biológia',
        subjectCategory: 'Természettudomány',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 18),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Szent-Györgyi Albert',
      ),

      // --- TESTNEVELÉS ÉS EGÉSZSÉGFEJLESZTÉS (Tanár: Hajós Alfréd) ---
      Grade(
        subject: 'Testnevelés és egészségfejlesztés',
        subjectCategory: 'Testnevelés',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 9, 30),
        type: 'Gyakorlati feladat',
        theme: '2000 m síkfutás állóképességi felmérés',
        teacherName: 'Hajós Alfréd',
      ),
      Grade(
        subject: 'Testnevelés és egészségfejlesztés',
        subjectCategory: 'Testnevelés',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y1, 11, 18),
        type: 'Gyakorlati feladat',
        theme: 'Kötélmászás és szekrényugrás',
        teacherName: 'Hajós Alfréd',
      ),
      Grade(
        subject: 'Testnevelés és egészségfejlesztés',
        subjectCategory: 'Testnevelés',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Hajós Alfréd',
      ),
      Grade(
        subject: 'Testnevelés és egészségfejlesztés',
        subjectCategory: 'Testnevelés',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 3, 27),
        type: 'Gyakorlati feladat',
        theme: 'Kosárlabda büntetődobás és ziccer',
        teacherName: 'Hajós Alfréd',
      ),
      Grade(
        subject: 'Testnevelés és egészségfejlesztés',
        subjectCategory: 'Testnevelés',
        numericValue: 5,
        textValue: 'Jeles (5)',
        weight: 100,
        date: d(y2, 6, 19),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Hajós Alfréd',
      ),

      // --- FÖLDRAJZ (Tanár: Teleki Pál) ---
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y1, 10, 16),
        type: 'Térképismereti dolgozat',
        theme: 'Európa domborzata és vaktérkép',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 1,
        textValue: 'Elégtelen (1)',
        weight: 100,
        date: d(y1, 11, 20),
        type: 'Írásbeli röpdolgozat',
        theme: 'Földrajzi fokhálózat és időzónák számítása',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 200,
        date: d(y1, 12, 8),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'A Föld belső szerkezete és lemeztektonika',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 1, 23),
        type: 'Félévi értékelés',
        theme: 'I. félévi lezárás',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 3,
        textValue: 'Közepes (3)',
        weight: 100,
        date: d(y2, 4, 5),
        type: 'Szóbeli felelet',
        theme: 'A Kárpát-medence természeti és gazdasági földrajza',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 200,
        date: d(y2, 5, 30),
        type: 'Írásbeli témazáró dolgozat',
        theme: 'Globális környezeti kihívások és éghajlatváltozás',
        teacherName: 'Teleki Pál',
      ),
      Grade(
        subject: 'Földrajz',
        subjectCategory: 'Természettudomány',
        numericValue: 2,
        textValue: 'Elégséges (2)',
        weight: 100,
        date: d(y2, 6, 19),
        type: 'Év végi értékelés',
        theme: 'Év végi lezárás',
        teacherName: 'Teleki Pál',
      ),
    ];
  }

  /// Class/Group averages per subject.
  static List<Map<String, dynamic>> getGroupAverages() {
    return [
      {'Tantargy': {'Nev': 'Matematika'}, 'OsztalyAtlag': 3.82},
      {'Tantargy': {'Nev': 'Magyar nyelv és irodalom'}, 'OsztalyAtlag': 4.15},
      {'Tantargy': {'Nev': 'Történelem'}, 'OsztalyAtlag': 3.95},
      {'Tantargy': {'Nev': 'Angol nyelv'}, 'OsztalyAtlag': 4.30},
      {'Tantargy': {'Nev': 'Digitális kultúra'}, 'OsztalyAtlag': 4.60},
      {'Tantargy': {'Nev': 'Fizika'}, 'OsztalyAtlag': 3.45},
      {'Tantargy': {'Nev': 'Kémia'}, 'OsztalyAtlag': 3.70},
      {'Tantargy': {'Nev': 'Biológia'}, 'OsztalyAtlag': 4.25},
      {'Tantargy': {'Nev': 'Testnevelés és egészségfejlesztés'}, 'OsztalyAtlag': 4.85},
      {'Tantargy': {'Nev': 'Földrajz'}, 'OsztalyAtlag': 4.10},
    ];
  }

  /// Subject averages calculated for Teszt Elek.
  static List<Map<String, dynamic>> getAverages() {
    return [
      {'Tantargy': {'Nev': 'Matematika'}, 'Atlag': 4.30},
      {'Tantargy': {'Nev': 'Magyar nyelv és irodalom'}, 'Atlag': 4.50},
      {'Tantargy': {'Nev': 'Történelem'}, 'Atlag': 4.60},
      {'Tantargy': {'Nev': 'Angol nyelv'}, 'Atlag': 4.85},
      {'Tantargy': {'Nev': 'Digitális kultúra'}, 'Atlag': 5.00},
      {'Tantargy': {'Nev': 'Fizika'}, 'Atlag': 1.72},
      {'Tantargy': {'Nev': 'Kémia'}, 'Atlag': 1.27},
      {'Tantargy': {'Nev': 'Biológia'}, 'Atlag': 5.00},
      {'Tantargy': {'Nev': 'Testnevelés és egészségfejlesztés'}, 'Atlag': 5.00},
      {'Tantargy': {'Nev': 'Földrajz'}, 'Atlag': 2.11},
    ];
  }

  /// The demo school rotates an A/B week, alternating by week of the year.
  static bool isDemoAWeek(DateTime monday, [bool? overrideAWeek]) {
    // UTC so a daylight-saving change can't shorten a day.
    final dayOfYear = DateTime.utc(monday.year, monday.month, monday.day).difference(DateTime.utc(monday.year, 1, 1)).inDays;
    return overrideAWeek ?? ((dayOfYear ~/ 7) + 1) % 2 != 0;
  }

  static String weekType(DateTime monday, [bool? overrideAWeek]) =>
      isDemoAWeek(monday, overrideAWeek) ? 'A hét' : 'B hét';

  /// Returns dynamic timetable for requested Monday-Friday dates.
  static List<TimetableEntry> getTimetable({DateTime? start, DateTime? end, bool? overrideAWeek}) {
    final now = DateTime.now();
    DateTime baseMonday = start ?? now.subtract(Duration(days: now.weekday - 1));
    baseMonday = DateTime(baseMonday.year, baseMonday.month, baseMonday.day);

    final timetable = <TimetableEntry>[];

    final isAWeek = isDemoAWeek(baseMonday, overrideAWeek);

    final weeklySchedule = [
      // Monday (1) - 8 periods
      [
        ('Matematika', 'Dr. Számoló Szilárd', '204-es terem', '07:55', '08:40', 'Másodfokú egyenletek és függvények', false, false),
        ('Magyar nyelv és irodalom', 'Arany Jánosné', '108-as terem', '08:50', '09:35', 'A magyar felvilágosodás korszaka', false, false),
        ('Történelem', 'Kossuth Lajos', '215-ös terem', '09:45', '10:30', 'A reformkor gazdasági törekvései', false, false),
        ('Digitális kultúra', 'Neumann János', 'Infó labor 1', '10:45', '11:30', 'Dart CLI és objektumorientált programozás', false, false),
        ('Fizika', 'Eötvös Loránd', 'Fizika előadó', '11:40', '12:25', 'Newton törvényei és gravitáció', true, false),
        ('Angol nyelv', 'Smith John', 'Nyelvi terem 3', '12:45', '13:30', 'Conditional sentences practice B2', false, false),
        ('Kémia', 'Irinyi János', 'Kémia labor', '13:40', '14:25', 'Sav-bázis titrálási kísérletek', false, false),
        ('Testnevelés és egészségfejlesztés', 'Hajós Alfréd', 'Tornaterem', '14:35', '15:20', 'Kosárlabda technikai gyakorlatok', false, false),
      ],
      // Tuesday (2) - 7 periods (Alternating subject on period 3 for A/B week)
      [
        ('Angol nyelv', 'Smith John', 'Nyelvi terem 3', '07:55', '08:40', 'Vocabulary expansion: Ecology & Environment', false, false),
        ('Matematika', 'Dr. Számoló Szilárd', '204-es terem', '08:50', '09:35', 'Geometria: Síkvektorok és koordinátageometria', false, false),
        isAWeek
            ? ('Biológia', 'Szent-Györgyi Albert', 'Bio labor', '09:45', '10:30', 'A sejt felépítése és biokémiai folyamatai', false, false)
            : ('Földrajz', 'Teleki Pál', '105-ös terem', '09:45', '10:30', 'A Föld belső szerkezete és lemeztektonika', false, false),
        ('Kémia', 'Irinyi János', 'Kémia előadó', '10:45', '11:30', 'Redoxireakciók és égési folyamatok', true, false),
        ('Testnevelés és egészségfejlesztés', 'Hajós Alfréd', 'Tornaterem', '11:40', '12:25', 'Erőnléti állapotfelmérés', false, false),
        ('Földrajz', 'Teleki Pál', '105-ös terem', '12:45', '13:30', 'A Kárpát-medence természeti kincsei', false, false),
        ('Fizika', 'Eötvös Loránd', 'Fizika előadó', '13:40', '14:25', 'Elektrosztatika: Coulomb-törvény feladatok', false, true),
      ],
      // Wednesday (3) - 0 periods (Tanítás nélküli nap / Szabadnap)
      <(String, String, String, String, String, String, bool, bool)>[],
      // Thursday (4) - 8 periods (Alternating subject on period 7 for A/B week)
      [
        ('Kémia', 'Irinyi János', 'Kémia előadó', '07:55', '08:40', 'Szerves kémia alapjai és szénhidrogének', false, false),
        ('Biológia', 'Szent-Györgyi Albert', 'Bio labor', '08:50', '09:35', 'Fotoszintézis, sejtlégzés és anyagcsere', false, false),
        ('Angol nyelv', 'Smith John', 'Nyelvi terem 3', '09:45', '10:30', 'Reading comprehension B2 mock test', true, false),
        ('Magyar nyelv és irodalom', 'Arany Jánosné', '108-as terem', '10:45', '11:30', 'Kölcsey Ferenc: Himnusz elemzés', false, false),
        ('Történelem', 'Kossuth Lajos', '215-ös terem', '11:40', '12:25', 'Az 1848-as márciusi forradalom eseményei', false, false),
        ('Földrajz', 'Teleki Pál', '105-ös terem', '12:45', '13:30', 'Európa gazdasági körzetei és integráció', false, false),
        isAWeek
            ? ('Matematika', 'Dr. Számoló Szilárd', '204-es terem', '13:40', '14:25', 'Trigonometrikus azonosságok feladatmegoldás', false, false)
            : ('Fizika', 'Eötvös Loránd', 'Fizika előadó', '13:40', '14:25', 'Laboratóriumi mérési gyakorlat', false, false),
        ('Digitális kultúra', 'Neumann János', 'Infó labor 1', '14:35', '15:20', 'Adatbázisok: Relációs adatmodellek és SQL', false, false),
      ],
      // Friday (5) - 7 periods
      [
        ('Matematika', 'Dr. Számoló Szilárd', '204-es terem', '07:55', '08:40', 'Valószínűségszámítás alapjai és kombinatorika', false, false),
        ('Digitális kultúra', 'Neumann János', 'Infó labor 1', '08:50', '09:35', 'Szoftverfejlesztési projektmunkák bemutatója', true, false),
        ('Fizika', 'Eötvös Loránd', 'Fizika előadó', '09:45', '10:30', 'Optika: Fénytörés és lencsék képalkotása', false, false),
        ('Angol nyelv', 'Smith John', 'Nyelvi terem 3', '10:45', '11:30', 'Academic writing & Essay structure', false, false),
        ('Testnevelés és egészségfejlesztés', 'Hajós Alfréd', 'Sportpálya', '11:40', '12:25', 'Foci és atlétika bajnokság', false, false),
        ('Osztályfőnöki', 'Kossuth Lajos', '215-ös terem', '12:45', '13:30', 'DÖK választás és osztálykirándulás megbeszélése', false, false),
        ('Magyar nyelv és irodalom', 'Arany Jánosné', '108-as terem', '13:40', '14:25', 'Vörösmarty Mihály: Szózat és gondolati lírája', false, false),
      ],
    ];

    for (int dayIdx = 0; dayIdx < 5; dayIdx++) {
      final dayDate = baseMonday.add(Duration(days: dayIdx));
      final lessons = weeklySchedule[dayIdx];

      for (int lessonIdx = 0; lessonIdx < lessons.length; lessonIdx++) {
        final (subject, teacher, room, startStr, endStr, theme, isSubst, isCanc) = lessons[lessonIdx];
        final startParts = startStr.split(':').map(int.parse).toList();
        final endParts = endStr.split(':').map(int.parse).toList();

        final startDt = DateTime(dayDate.year, dayDate.month, dayDate.day, startParts[0], startParts[1]);
        final endDt = DateTime(dayDate.year, dayDate.month, dayDate.day, endParts[0], endParts[1]);

        timetable.add(
          TimetableEntry(
            subject: subject,
            theme: theme,
            startTime: startDt,
            endTime: endDt,
            date: dayDate,
            lessonNumber: lessonIdx + 1,
            uid: 'DEMO-LESSON-$dayIdx-$lessonIdx',
            teacher: teacher,
            substituteTeacher: isSubst ? 'Jedlik Ányos' : null,
            room: room,
            status: isCanc ? 'Elmarad' : 'Megtartva',
            typeName: isCanc ? 'Elmaradt tanóra' : 'Normál tanóra',
          ),
        );
      }
    }

    return timetable;
  }

  /// Announced upcoming / yearly exams.
  static List<Exam> getExams() {
    final now = DateTime.now();
    return [
      Exam(
        subject: 'Matematika',
        date: now.add(const Duration(days: 3, hours: 2)),
        mode: 'Írásbeli témazáró dolgozat',
        theme: 'Másodfokú egyenletek és trigonometria',
        uid: 'DEMO-EXAM-1',
      ),
      Exam(
        subject: 'Történelem',
        date: now.add(const Duration(days: 6, hours: 3)),
        mode: 'Írásbeli témazáró dolgozat',
        theme: 'A reformkor Magyarországon és az áprilisi törvények',
        uid: 'DEMO-EXAM-2',
      ),
      Exam(
        subject: 'Angol nyelv',
        date: now.add(const Duration(days: 9, hours: 1)),
        mode: 'B2 Szóbeli modulvizsga',
        theme: 'Global Environmental Issues & Technology',
        uid: 'DEMO-EXAM-3',
      ),
      Exam(
        subject: 'Fizika',
        date: now.add(const Duration(days: 12, hours: 4)),
        mode: 'Írásbeli röpdolgozat',
        theme: 'Munka, energia és teljesítmény',
        uid: 'DEMO-EXAM-4',
      ),
      Exam(
        subject: 'Kémia',
        date: now.add(const Duration(days: 15, hours: 2)),
        mode: 'Laboratóriumi gyakorlati felmérés',
        theme: 'Sav-bázis indikátorok és pH mérés',
        uid: 'DEMO-EXAM-5',
      ),
    ];
  }

  /// Homework assignments.
  static List<Homework> getHomework({DateTime? start, String? id}) {
    final now = DateTime.now();
    return [
      Homework(
        uid: 'DEMO-HW-1',
        subject: 'Matematika',
        text: 'Tankönyv 142. oldal 12-es, 15-ös és 18/b feladatok kidolgozása a füzetbe.',
        assignedDate: now.subtract(const Duration(days: 2)),
        deadline: now.add(const Duration(days: 2)),
      ),
      Homework(
        uid: 'DEMO-HW-2',
        subject: 'Magyar nyelv és irodalom',
        text: 'Kölcsey Ferenc: Parainesis részlet elolvasása és vázlatkészítés a főbb erényekről.',
        assignedDate: now.subtract(const Duration(days: 1)),
        deadline: now.add(const Duration(days: 3)),
      ),
      Homework(
        uid: 'DEMO-HW-3',
        subject: 'Digitális kultúra',
        text: 'A Pala TUI új Demó módjának tesztelése és a visszajelzések leadása.',
        assignedDate: now.subtract(const Duration(days: 3)),
        deadline: now.add(const Duration(days: 4)),
      ),
      Homework(
        uid: 'DEMO-HW-4',
        subject: 'Történelem',
        text: 'Forráselemzés a Munkafüzet 88. oldalán: Széchenyi és Kossuth vitája.',
        assignedDate: now.subtract(const Duration(days: 4)),
        deadline: now.add(const Duration(days: 1)),
      ),
      Homework(
        uid: 'DEMO-HW-5',
        subject: 'Angol nyelv',
        text: 'Write a 150-word essay about the impact of artificial intelligence on high school education.',
        assignedDate: now.subtract(const Duration(days: 2)),
        deadline: now.add(const Duration(days: 5)),
      ),
    ];
  }

  static List<Message>? _cachedMessages;

  /// Electronic diary messages.
  static List<Message> getMessages() {
    if (_cachedMessages != null) return _cachedMessages!;
    final now = DateTime.now();
    _cachedMessages = [
      Message(
        id: 101,
        senderName: 'Kossuth Lajos (Osztályfőnök)',
        subject: 'Osztálykirándulás részletei és tudnivalók',
        sentDate: now.subtract(const Duration(days: 2, hours: 3)),
        isRead: false,
        text: 'Kedves Diákok és Szülők!\n\nA tavaszi osztálykirándulásunk időpontja május 22-24. Úti cél: Dunakanyar és Visegrád. A részletes programot és a felszereléslistát a csatolt dokumentumban találjátok.\n\nÜdvözlettel:\nKossuth Lajos',
        attachments: [
          MessageAttachment(id: 1, name: 'Visegrad_programterv.pdf'),
          MessageAttachment(id: 2, name: 'Szuloi_nyilatkozat.docx'),
        ],
      ),
      Message(
        id: 102,
        senderName: 'Dr. Igazgató István (Intézményvezető)',
        subject: 'Tájékoztatás a tavaszi szünetről és a fogadóóráról',
        sentDate: now.subtract(const Duration(days: 5, hours: 8)),
        isRead: true,
        text: 'Tisztelt Szülők, Kedves Diákok!\n\nÉrtesítem Önöket, hogy a tavaszi szülői értekezlet és fogadóóra április 16-án, szerdán 17:00 órai kezdettel kerül megrendezésre a szaktantermi épületben.',
        attachments: [],
      ),
      Message(
        id: 103,
        senderName: 'Neumann János (Digitális kultúra)',
        subject: 'Országos Programozási Verseny felhívás',
        sentDate: now.subtract(const Duration(days: 8, hours: 2)),
        isRead: true,
        text: 'Sziasztok!\n\nLehetőség van jelentkezni az idei Nemes Tihamér és OKTV programozási versenyekre. A felkészítő szakkör minden csütörtökön 15:00-kor lesz az 1-es infó laborban.',
        attachments: [
          MessageAttachment(id: 3, name: 'Versenykiiras_2026.pdf'),
        ],
      ),
      Message(
        id: 104,
        senderName: 'Pala Rendszerértesítő',
        subject: 'Üdvözöl a Pala Demó Üzemmódja!',
        sentDate: now.subtract(const Duration(days: 12)),
        isRead: true,
        text: 'Sikeresen elindítottad a Pala TUI demó profilját (Teszt Elek). Minden funkció – a grafikonoktól a Pala Wrappedig – teljes mértékben elérhető és tesztelhető offline módban.',
        attachments: [],
      ),
      Message(
        id: 108,
        senderName: 'Teleki Pál (Földrajz)',
        subject: 'Helyettesítés csütörtökön',
        sentDate: now.subtract(const Duration(days: 4, hours: 6)),
        isRead: true,
        text: 'Kedves Diákok!\n\nCsütörtöki földrajz óráimat betegség miatt Irinyi János tanár úr helyettesíti. Kérlek, hozzátok magatokkal a munkafüzeteteket, önálló feladatlapot fogtok megoldani.',
        attachments: [],
      ),
      Message(
        id: 109,
        senderName: 'Pala Rendszerértesítő',
        subject: 'Emlékeztető: közösségi szolgálat óraszám',
        sentDate: now.subtract(const Duration(days: 20)),
        isRead: true,
        text: 'Az érettségi bizonyítvány feltétele az 50 óra igazolt közösségi szolgálat teljesítése. Jelenlegi állásod a Statisztikák menüpontban tekinthető meg.',
        attachments: [],
      ),
    ];
    return _cachedMessages!;
  }

  static List<Note>? _cachedNotes;

  /// Electronic diary notes and disciplinary/praise records.
  static List<Note> getNotes() {
    if (_cachedNotes != null) return _cachedNotes!;
    final now = DateTime.now();
    _cachedNotes = [
      Note(
        id: '105',
        type: 'Osztályfőnöki megrovás',
        senderName: 'Kossuth Lajos (Osztályfőnök)',
        title: 'Osztályfőnöki megrovás',
        content: 'Tájékoztatlak, hogy a 2026. szeptemberi hónapban tanúsított ismétlődő igazolatlan hiányzásaid és késéseid (Történelem, Kémia, Matematika, Angol nyelv) miatt osztályfőnöki megrovásban részesítelek. Kérlek, a jövőben minden hiányzást és késést haladéktalanul igazolj az ellenőrzőben, illetve a Beállítások menüben beállított szülői keret felhasználásával. Ismétlődés esetén a fegyelmi eljárás következő fokozata az igazgatói figyelmeztetés.\n\nÜdvözlettel:\nKossuth Lajos\nOsztályfőnök',
        date: now.subtract(const Duration(days: 6, hours: 1)),
      ),
      Note(
        id: '106',
        type: 'Igazgatói megrovás',
        senderName: 'Dr. Igazgató István (Intézményvezető)',
        title: 'Igazgatói megrovás',
        content: 'Az osztályfőnöki jelzés és a több alkalommal ismétlődő igazolatlan mulasztás, valamint a tanórai késések alapján az intézmény vezetőjeként igazgatói megrovás fegyelmező intézkedést alkalmazok veled szemben. Kérlek, a Házirendben foglaltaknak megfelelően pótold a hiányzó igazolásokat, és a jövőben kerüld az iskolai hiányzást és késést. További szabálysértés esetén a fegyelmi bizottság összehívására kerülhet sor.\n\nDr. Igazgató István\nIntézményvezető',
        date: now.subtract(const Duration(days: 5, hours: 4)),
      ),
      Note(
        id: '107',
        type: 'Szaktanári dicséret',
        senderName: 'Dr. Számoló Szilárd (Matematika)',
        title: 'Szaktanári dicséret – Zrínyi Ilona Matematikaverseny',
        content: 'Kedves Elek!\n\nGratulálok a Zrínyi Ilona Matematikaverseny megyei fordulóján elért kiváló, dobogós helyezésedhez! Kimagasló felkészültségedért és eredményedért szaktárgyi dicséretben részesítelek, mely bekerül a törzslapodba is.\n\nÜdvözlettel:\nDr. Számoló Szilárd',
        date: now.subtract(const Duration(days: 14, hours: 2)),
      ),
    ];
    return _cachedNotes!;
  }

  static void addSentMessage({required String subject, required String text, required String recipientName, List<String>? attachmentNames}) {
    final list = getMessages();
    final newId = 200 + list.length;
    final attachments = (attachmentNames ?? []).asMap().entries.map((e) => MessageAttachment(id: e.key + 10, name: e.value)).toList();
    list.insert(
      0,
      Message(
        id: newId,
        senderName: 'Címzett: $recipientName (Elküldve)',
        subject: subject,
        sentDate: DateTime.now(),
        isRead: true,
        text: text,
        attachments: attachments,
      ),
    );
  }

  /// Teachers directory in Pala Minta Gimnázium.
  static List<Map<String, dynamic>> getTeachers() {
    return [
      {'azonosito': 1, 'nev': 'Dr. Számoló Szilárd', 'tantargyak': 'Matematika'},
      {'azonosito': 2, 'nev': 'Arany Jánosné', 'tantargyak': 'Magyar nyelv és irodalom'},
      {'azonosito': 3, 'nev': 'Kossuth Lajos (Osztályfőnök)', 'tantargyak': 'Történelem, Osztályfőnöki'},
      {'azonosito': 4, 'nev': 'Smith John', 'tantargyak': 'Angol nyelv'},
      {'azonosito': 5, 'nev': 'Neumann János', 'tantargyak': 'Digitális kultúra, Informatika'},
      {'azonosito': 6, 'nev': 'Eötvös Loránd', 'tantargyak': 'Fizika'},
      {'azonosito': 7, 'nev': 'Irinyi János', 'tantargyak': 'Kémia'},
      {'azonosito': 8, 'nev': 'Szent-Györgyi Albert', 'tantargyak': 'Biológia'},
      {'azonosito': 9, 'nev': 'Hajós Alfréd', 'tantargyak': 'Testnevelés és egészségfejlesztés'},
      {'azonosito': 10, 'nev': 'Teleki Pál', 'tantargyak': 'Földrajz'},
      {'azonosito': 11, 'nev': 'Dr. Igazgató István', 'tantargyak': 'Intézményvezető'},
    ];
  }

  /// Realistic absences and delays.
  static List<Absence> getAbsences() {
    final now = DateTime.now();
    return [
      // Parental excused day (2 lessons)
      Absence(
        subject: 'Biológia',
        date: now.subtract(const Duration(days: 22)),
        status: 'Igazolt',
        type: 'Szülői igazolás',
      ),
      Absence(
        subject: 'Földrajz',
        date: now.subtract(const Duration(days: 22)),
        status: 'Igazolt',
        type: 'Szülői igazolás',
      ),
      // Medical excused day (3 lessons)
      Absence(
        subject: 'Matematika',
        date: now.subtract(const Duration(days: 8)),
        status: 'Igazolt',
        type: 'Orvosi igazolás',
      ),
      Absence(
        subject: 'Magyar nyelv és irodalom',
        date: now.subtract(const Duration(days: 8)),
        status: 'Igazolt',
        type: 'Orvosi igazolás',
      ),
      Absence(
        subject: 'Történelem',
        date: now.subtract(const Duration(days: 8)),
        status: 'Igazolt',
        type: 'Orvosi igazolás',
      ),
      // Delays
      Absence(
        subject: 'Testnevelés és egészségfejlesztés',
        date: now.subtract(const Duration(days: 3)),
        status: 'Igazolt',
        type: 'Késés',
        delayMinutes: 10,
      ),
      Absence(
        subject: 'Angol nyelv',
        date: now.subtract(const Duration(days: 15)),
        status: 'Igazolt',
        type: 'Késés',
        delayMinutes: 5,
      ),
      // Pending unexcused day ready for excuse letter generation
      Absence(
        subject: 'Fizika',
        date: now.subtract(const Duration(days: 1)),
        status: 'Igazolandó',
        type: 'Hiányzás',
      ),
      Absence(
        subject: 'Kémia',
        date: now.subtract(const Duration(days: 1)),
        status: 'Igazolandó',
        type: 'Hiányzás',
      ),
      Absence(
        subject: 'Matematika',
        date: now.subtract(const Duration(days: 1)),
        status: 'Igazolandó',
        type: 'Hiányzás',
      ),
      // Unexcused absences and repeated lateness: the reason behind the
      // osztályfőnöki/igazgatói megrovás messages below.
      Absence(
        subject: 'Történelem',
        date: now.subtract(const Duration(days: 19)),
        status: 'Igazolatlan',
        type: 'Hiányzás',
      ),
      Absence(
        subject: 'Kémia',
        date: now.subtract(const Duration(days: 19)),
        status: 'Igazolatlan',
        type: 'Hiányzás',
      ),
      Absence(
        subject: 'Matematika',
        date: now.subtract(const Duration(days: 11)),
        status: 'Igazolatlan',
        type: 'Késés',
        delayMinutes: 20,
      ),
      Absence(
        subject: 'Angol nyelv',
        date: now.subtract(const Duration(days: 6)),
        status: 'Igazolatlan',
        type: 'Késés',
        delayMinutes: 12,
      ),
    ];
  }
}
