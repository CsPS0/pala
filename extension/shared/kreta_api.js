// Pala Extension - Kréta API Client & Demo Engine

const DEMO_STUDENT = {
  Nev: "Teszt Elek",
  SzuletesiDatum: "2008-03-15",
  OktatasiAzonosito: "72458912345",
  Gondviselok: [{ Nev: "Teszt Gábor", Email: "szulo@teszt.hu" }],
  Intezmeny: { Nev: "Pala Minta Gimnázium", Kod: "klik039000" }
};

const DEMO_GRADES = [
  { Id: 101, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Függvények & Analízis", RogzitesDatuma: new Date().toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 102, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Nyugat költészete", RogzitesDatuma: new Date(Date.now() - 86400000).toISOString(), Tipus: { Leiras: "Szóbeli felelet" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 103, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "A reformkor nagyjai", RogzitesDatuma: new Date(Date.now() - 172800000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 104, Tantargy: { Nev: "Angol nyelv" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Conditionals & Essay", RogzitesDatuma: new Date(Date.now() - 259200000).toISOString(), Tipus: { Leiras: "Írásbeli dolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 105, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 100, Tema: "Elektrosztatika számítások", RogzitesDatuma: new Date(Date.now() - 345600000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 106, Tantargy: { Nev: "Informatika / Digitális kultúra" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Python algoritmusok & Adatbázisok", RogzitesDatuma: new Date(Date.now() - 432000000).toISOString(), Tipus: { Leiras: "Gyakorlati feladat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } }
];

function generateDemoTimetable() {
  const today = new Date();
  const subjects = [
    { name: "Matematika", room: "204", teacher: "Kovács Péter" },
    { name: "Magyar irodalom", room: "102", teacher: "Nagy Erika" },
    { name: "Történelem", room: "305", teacher: "Horváth László" },
    { name: "Angol nyelv", room: "201", teacher: "Kiss Andrea" },
    { name: "Fizika", room: "Fizika Ea.", teacher: "Szabó Zoltán" },
    { name: "Testnevelés", room: "Tornaterem", teacher: "Varga Dániel" }
  ];

  const timetable = [];
  for (let i = 0; i < subjects.length; i++) {
    const startHour = 8 + i;
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate(), startHour, 0);
    const end = new Date(today.getFullYear(), today.getMonth(), today.getDate(), startHour, 45);

    timetable.push({
      Id: 1000 + i,
      Oraszam: i + 1,
      KezdetIdopont: start.toISOString(),
      VegIdopont: end.toISOString(),
      Tantargy: { Nev: subjects[i].name },
      Terem: subjects[i].room,
      Tanar: subjects[i].teacher,
      Tema: `Tananyag ${i + 1}. fejezet`,
      Allapot: { Nev: "Megtartott" }
    });
  }
  return timetable;
}

const DEMO_HOMEWORK = [
  { Id: 201, Tantargy: "Matematika", Hatarido: new Date(Date.now() + 86400000).toISOString(), Szoveg: "Tk. 142. oldal 5, 6, 7. feladatok kidolgozása", Tanar: "Kovács Péter" },
  { Id: 202, Tantargy: "Történelem", Hatarido: new Date(Date.now() + 172800000).toISOString(), Szoveg: "Forráselemzés a reformkori vitákról (vázlatkészítés)", Tanar: "Horváth László" },
  { Id: 203, Tantargy: "Fizika", Hatarido: new Date(Date.now() + 259200000).toISOString(), Szoveg: "Coulomb-törvény gyakorló feladatsor", Tanar: "Szabó Zoltán" }
];

const DEMO_EXAMS = [
  { Id: 301, Tantargy: "Matematika", Datum: new Date(Date.now() + 172800000).toISOString(), Tema: "Függvénytranszformációk & Szélsőérték", Tipus: "Témazáró dolgozat" },
  { Id: 302, Tantargy: "Angol nyelv", Datum: new Date(Date.now() + 345600000).toISOString(), Tema: "C1 Unit 4 Vocabulary & Grammar", Tipus: "Szódolgozat" }
];

const DEMO_ABSENCES = [
  { Id: 401, Datum: new Date(Date.now() - 604800000).toISOString(), Tantargy: "Biológia", IgazolasAllapota: "Igazolt", Tipus: "Szülői igazolás", KesesPercben: 0 },
  { Id: 402, Datum: new Date(Date.now() - 604800000).toISOString(), Tantargy: "Kémia", IgazolasAllapota: "Igazolt", Tipus: "Szülői igazolás", KesesPercben: 0 }
];

class KretaApi {
  static async login(instituteCode, username, password) {
    const tokenUrl = "https://idp.e-kreta.hu/connect/token";
    const body = new URLSearchParams({
      userName: username,
      password: password,
      institute_code: instituteCode,
      client_id: "kreta-ellenorzo-mobile-ios",
      grant_type: "password"
    });

    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString()
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Kréta bejelentkezési hiba (${response.status}): ${errText}`);
    }

    return await response.json();
  }

  static async getStudentData(instituteCode, accessToken) {
    const base = `https://${instituteCode}.e-kreta.hu/ellenorzo/V3/Sajat`;
    const headers = {
      "Authorization": `Bearer ${accessToken}`,
      "User-Agent": "PalaBrowserExtension/1.0",
      "Accept": "application/json"
    };

    const [studentRes, gradesRes, timetableRes, hwRes, examsRes, absencesRes] = await Promise.all([
      fetch(`${base}/TanuloAdatlap`, { headers }),
      fetch(`${base}/Ertekelesek`, { headers }),
      fetch(`${base}/OrarendElemek`, { headers }),
      fetch(`${base}/HaziFeladatok`, { headers }),
      fetch(`${base}/BejelentettSzamonkeresek`, { headers }),
      fetch(`${base}/Mulasztasok`, { headers })
    ]);

    return {
      student: studentRes.ok ? await studentRes.json() : null,
      grades: gradesRes.ok ? await gradesRes.json() : [],
      timetable: timetableRes.ok ? await timetableRes.json() : [],
      homework: hwRes.ok ? await hwRes.json() : [],
      exams: examsRes.ok ? await examsRes.json() : [],
      absences: absencesRes.ok ? await absencesRes.json() : []
    };
  }

  static getDemoDataset() {
    return {
      student: DEMO_STUDENT,
      grades: DEMO_GRADES,
      timetable: generateDemoTimetable(),
      homework: DEMO_HOMEWORK,
      exams: DEMO_EXAMS,
      absences: DEMO_ABSENCES,
      isDemo: true
    };
  }
}

// Export for extension contexts
if (typeof window !== "undefined") {
  window.KretaApi = KretaApi;
}
