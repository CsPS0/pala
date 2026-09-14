"use client";

import React, { useState } from "react";
import {
  History,
  Sparkles,
  ShieldAlert,
  GitBranch,
  PenTool,
  Smartphone,
  Monitor,
  Terminal,
  ExternalLink,
  Zap,
  Calendar,
  Layers,
  Globe,
  BookOpen,
  ChevronDown,
  ChevronsUpDown,
  GraduationCap,
  Home,
  Code,
  Search,
  X,
} from "lucide-react";

export interface TimelineEvent {
  id: string;
  period: string;
  title: string;
  subtitle: string;
  repo?: string;
  url?: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  tag: string;
  tagColor: "orange" | "danger" | "warning" | "blue" | "purple" | "green";
  description: string;
  highlight?: boolean;
  isBreach?: boolean;
}

export interface TimelineEra {
  id: string;
  period: string;
  title: string;
  badge: string;
  description?: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  nodeColor: "orange" | "danger" | "warning" | "blue" | "purple" | "green";
  isMultiColumn?: boolean;
  items: TimelineEvent[];
}

const SECTION_1_TIMELINE: TimelineEra[] = [
  {
    id: "s1-pioneers",
    period: "1999–2000-es évek",
    title: "Pronote & WebUntis",
    badge: "1999–",
    icon: Globe,
    nodeColor: "blue",
    items: [
      {
        id: "pronote-webuntis",
        period: "1999–napjainkig",
        title: "Pronote (Franciaország) & WebUntis (Ausztria / Németország)",
        subtitle: "Index Éducation • Untis GmbH • Iskolai ERP & digitális napló",
        icon: Globe,
        tag: "Európai úttörők",
        tagColor: "blue",
        description:
          "Franciaországban a Pronote (1999), a német nyelvterületen pedig a WebUntis (2000) vált az iskolai órarendek, jegyek és mulasztások digitális kezelésének alapkövévé. Decentralizált modellben, intézményenkénti licenceléssel terjedtek el, egészséges versenyt fenntartva a piacon.",
      },
    ],
  },
  {
    id: "s1-us-lms",
    period: "2010-es évek",
    title: "PowerSchool, Canvas & Google Classroom",
    badge: "2010–",
    icon: Layers,
    nodeColor: "purple",
    items: [
      {
        id: "cloud-lms",
        period: "2010–napjainkig",
        title: "PowerSchool, Canvas LMS & Google Classroom",
        subtitle: "Észak-amerikai és nemzetközi felhős platformok",
        icon: Layers,
        tag: "Felhő alapú LMS",
        tagColor: "purple",
        description:
          "Átfogó Learning Management System (LMS) platformok, amelyek nemcsak a jegyeket, hanem a digitális tananyagokat, online feladatbeadást és tanár-diák kommunikációt integrálták egyetlen felhős ökoszisztémába világszerte.",
      },
      {
        id: "better-canvas",
        period: "2021–napjainkig",
        title: "BetterCanvas (Nemzetközi Canvas bővítmény)",
        subtitle: "ksucup • Nyílt forráskódú hallgatói böngészőbővítmény",
        repo: "ksucup/BetterCanvas",
        url: "https://github.com/ksucup/BetterCanvas",
        icon: Sparkles,
        tag: "Diákbővítmény (500k+)",
        tagColor: "blue",
        description:
          "A világ egyik legelterjedtebb hallgatói kiegészítője a nemzetközileg népszerű Canvas LMS rendszerhez. Sötét témát, átlagkalkulátort, közvetlen feladatszervezőt és testreszabható vizuális vezérlőpultot adott a diákok kezébe, több mint félmillió aktív felhasználóval.",
      },
    ],
  },
  {
    id: "s1-community",
    period: "2017–napjainkig",
    title: "Nyílt forráskódú európai diák-kliensek",
    badge: "2017–2026",
    description:
      "A hivatalos nemzeti iskolai appok hiányosságaira adott nemzetközi diákválaszok Európa-szerte:",
    icon: Sparkles,
    nodeColor: "green",
    isMultiColumn: true,
    items: [
      {
        id: "wulkanowy",
        period: "2017–napjainkig",
        title: "Wulkanowy (Lengyelország)",
        subtitle: "wulkanowy • VULCAN UONET+ alternatív kliens (Kotlin & Swift)",
        repo: "wulkanowy/wulkanowy",
        url: "https://github.com/wulkanowy/wulkanowy",
        icon: Smartphone,
        tag: "A lengyel Filc",
        tagColor: "orange",
        description:
          "Lengyelországban a VULCAN UONET+ a domináns állami iskolai napló. A hivatalos app nehézkességeire válaszul lengyel diákok létrehozták a Wulkanowy nevű nyílt forráskódú klienst. Több százezer diák használja Androidon és iOS-en, modern Material You dizájnnal, widgetekkel és offline támogatással.",
      },
      {
        id: "betteruntis",
        period: "2017–napjainkig",
        title: "BetterUntis (Németország & Ausztria)",
        subtitle: "SapuSeven • WebUntis alternatív kliens (Kotlin, F-Droid)",
        repo: "SapuSeven/BetterUntis",
        url: "https://github.com/SapuSeven/BetterUntis",
        icon: Monitor,
        tag: "Nyílt Untis kliens",
        tagColor: "blue",
        description:
          "A német nyelvterületen elterjedt Untis órarendi rendszer alternatív, nyílt forráskódú kliense. Letisztult heti órarend-nézetet, tanári helyettesítés-értesítéseket, offline szinkronizációt és reklámmentes asztali widgeteket nyújt.",
      },
      {
        id: "discipulus",
        period: "2020–napjainkig",
        title: "Discipulus & MagisterJS (Hollandia)",
        subtitle: "DiscipulusApp & simplyGits • Magister 6 kliens (Flutter)",
        repo: "DiscipulusApp/Discipulus",
        url: "https://github.com/DiscipulusApp/Discipulus",
        icon: Layers,
        tag: "Holland közösség",
        tagColor: "purple",
        description:
          "A holland középiskolákban használt Magister rendszerhez készült nyílt forráskódú Flutter kliens és a MagisterJS API. Android, iOS, macOS, Windows és Linux rendszerekre is elérhetővé tette a modern, gyors és reszponzív digitális ellenőrzőt.",
      },
      {
        id: "papillon",
        period: "2020–napjainkig",
        title: "Papillon & YNotes (Franciaország)",
        subtitle: "the-papillon-project/papillon & EduWireApps/ynotes",
        repo: "the-papillon-project/papillon",
        url: "https://github.com/the-papillon-project/papillon",
        icon: Sparkles,
        tag: "Francia diákmozgalom",
        tagColor: "green",
        description:
          "A francia Pronote és EcoleDirecte appok lassúsága miatt francia diákok létrehozták a Papillon (React Native) és az YNotes (Flutter) klienst. Ez igazolja, hogy a közösségi kliensfejlesztés nemzetközi szinten is a diákprogramozók fontos gyakorlóterepe.",
      },
    ],
  },
];

const SECTION_2_TIMELINE: TimelineEra[] = [
  {
    id: "s2-paper",
    period: "2000-es évek",
    title: "A papír alapú ellenőrző könyvek kora",
    badge: "–2010",
    icon: BookOpen,
    nodeColor: "warning",
    items: [
      {
        id: "paper-era",
        period: "A digitalizáció előtt",
        title: "Hagyományos papír ellenőrzők és osztálynaplók",
        subtitle: "Kézzel írt osztályzatok és havi szülői aláírások",
        icon: BookOpen,
        tag: "Papíralapú kor",
        tagColor: "warning",
        description:
          "A 2000-es évek közepéig a magyar iskolákban kizárólag a kézzel vezetett papír ellenőrző könyv és a fizikai osztálynapló létezett. A tanárok tollal írták be a jegyeket, az átlagokat félévkor manuálisan számolták, az ellenőrzőt pedig a szülők havonta írták alá.",
      },
    ],
  },
  {
    id: "s2-mozanaplo",
    period: "2010–2015",
    title: "A MozaNapló és a MozaWeb fénykora",
    badge: "2010–2015",
    icon: History,
    nodeColor: "orange",
    items: [
      {
        id: "mozanaplo-glory",
        period: "2010–2015",
        title: "MozaNapló (MozaWeb oktatási platform)",
        subtitle: "Mozaik Kiadó (Szeged) • Digitális tankönyvek & 3D modellek",
        url: "https://www.mozaweb.hu",
        icon: History,
        tag: "Digitális úttörő",
        tagColor: "orange",
        description:
          "A szegedi Mozaik Kiadó által fejlesztett MozaNapló volt az egyik legelső és legfejlettebb elektronikus napló Magyarországon. Integrálva volt a mozaBook digitális tankönyvekkel, 3D animációkkal és interaktív feladatokkal. A 2010-es évek elejére a hazai iskolák jelentős részében piacvezetővé vált a Magiszter és más helyi megoldások mellett.",
      },
    ],
  },
  {
    id: "s2-kreta-start",
    period: "2015–2018",
    title: "A KRÉTA állami bevezetése és a központosítás",
    badge: "2015–2018",
    icon: ShieldAlert,
    nodeColor: "blue",
    items: [
      {
        id: "kreta-centralization",
        period: "2015–2018",
        title: "KRÉTA — Állami központosított tanulmányi rendszer",
        subtitle: "Klebelsberg Központ (KLIK) & EMMI • eKréta Informatikai Zrt.",
        icon: ShieldAlert,
        tag: "Állami monopólium",
        tagColor: "blue",
        description:
          "2015 és 2018 között az állami oktatásirányítás elindította a Köznevelési Regisztrációs és Tanulmányi Alaprendszer (KRÉTA) országos bevezetését. Célul tűzték ki az összes állami fenntartású általános iskola, gimnázium és technikum egyetlen központi szoftverbe terelését, fokozatosan felszámolva a piacon versenyző független e-naplókat.",
      },
    ],
  },
];

const SECTION_3_TIMELINE: TimelineEra[] = [
  {
    id: "era-szivacs",
    period: "2018–2019",
    title: "A kezdetek: Szivacs Napló",
    badge: "2018–2019",
    icon: History,
    nodeColor: "orange",
    items: [
      {
        id: "szivacs",
        period: "2018–2019",
        title: "Szivacs Napló",
        subtitle: "Botos András (Boa) • Flutter",
        repo: "boapps/Szivacs-Naplo",
        url: "https://github.com/boapps/Szivacs-Naplo",
        icon: History,
        tag: "Az első úttörő",
        tagColor: "orange",
        description:
          "Botos András (Boa) fejlesztette Flutter nyelven. Ez volt az első széles körben ismertté vált nyílt forráskódú kliens. Áttekinthető felületet, faliújságot, jegyátlag-számítást és több fiók egyidejű kezelését biztosította. A projekt fejlesztése 2019 végén leállt, miután az e-Kréta szerveroldali lassításokat és korlátozásokat vezetett be a kliens API-hívásaira.",
      },
    ],
  },
  {
    id: "era-filc",
    period: "2019–2022",
    title: "A virágkor: Filc Napló",
    badge: "2019–2022",
    icon: Sparkles,
    nodeColor: "purple",
    items: [
      {
        id: "filc",
        period: "2019–2022",
        title: "Filc Napló",
        subtitle: "annon vezetésével • Flutter",
        repo: "filc/filc",
        url: "https://github.com/filc/filc",
        icon: Sparkles,
        tag: "A legelterjedtebb kliens",
        tagColor: "purple",
        description:
          "A Szivacs után megjelent Filc Napló (annon vezetésével) Flutter alapokon indult. Kiforrott felületet, dinamikus sötét témát, jegyeloszlási statisztikákat és értesítéseket adott. Éveken keresztül a legelterjedtebb alternatív klienssé vált a diákok körében.",
      },
    ],
  },
  {
    id: "era-niche-early",
    period: "2019–2021",
    title: "Korai rétegprojektek, API dokumentáció és tanári napló",
    badge: "2019–2021",
    description:
      "A Filc fénykorában és a pandémia idején a fejlesztők elkezdték feltérképezni az API-t, és megjelentek az első alternatív és tanári kísérletek:",
    icon: Code,
    nodeColor: "blue",
    isMultiColumn: true,
    items: [
      {
        id: "arisztokreta",
        period: "2020",
        title: "Arisztokréta",
        subtitle: "Coware-Apps • TypeScript & Ionic keretrendszer",
        repo: "Coware-Apps/ellenorzo",
        url: "https://github.com/Coware-Apps/ellenorzo",
        icon: Smartphone,
        tag: "Megszűnt / Archivált",
        tagColor: "danger",
        description:
          "A Coware Apps által 2020 elején indított nyílt forráskódú, KRÉTA-kompatibilis ellenőrző alkalmazás. TypeScript és webes technológiák (Ionic) segítségével kísérletezett a diákok számára letisztultabb felület létrehozásával.",
      },
      {
        id: "naploplus",
        period: "2019–2020",
        title: "Napló+ (Tanári Napló)",
        subtitle: "Coware-Apps • Független KRÉTA-kompatibilis tanári alkalmazás",
        repo: "Coware-Apps/naplo",
        url: "https://github.com/Coware-Apps/naplo",
        icon: PenTool,
        tag: "Megszűnt / Archivált",
        tagColor: "danger",
        description:
          "A diákappok ritka, egyedi ellenpárja. Nem a diákoknak, hanem a pedagógusoknak készült: független, nyílt forráskódú tanári napló, amelynek célja a lassú hivatalos felület kiváltása és az adminisztráció, hiányzásrögzítés és jegybeírás felgyorsítása volt.",
      },
      {
        id: "asztal-api",
        period: "2020–2021",
        title: "Asztal & e-Kréta Docs v3",
        subtitle: "bczsalba • Minimalista Python asztali kliens és API specifikáció",
        repo: "bczsalba/ekreta-docs-v3",
        url: "https://github.com/bczsalba/ekreta-docs-v3",
        icon: Terminal,
        tag: "API dokumentáció",
        tagColor: "green",
        description:
          "Bence Csanád Zalba (bczsalba) által készített minimalista Python Kréta-kliens és az ekreta-docs-v3 projekt. Utóbbi a Kréta v2 és v3 REST API végpontjainak, OAuth2 hitelesítésének első átfogó, nyilvános dokumentációja volt, amely éveken át hivatkozási alapul szolgált a közösség fejlesztőinek.",
      },
    ],
  },
  {
    id: "era-breach",
    period: "2022 ősz",
    title: "Fordulópont: Kréta-feltörés",
    badge: "2022 ősz",
    icon: ShieldAlert,
    nodeColor: "danger",
    items: [
      {
        id: "breach",
        period: "2022 ősz",
        title: "Kréta-feltörés",
        subtitle: "Biztonsági incidens & API szigorítások",
        icon: ShieldAlert,
        tag: "Fordulópont",
        tagColor: "danger",
        isBreach: true,
        description:
          "2022 szeptemberében ismeretlen elkövetők sikeres adathalász támadást hajtottak végre az e-Kréta Zrt. munkatársa ellen. A támadók hozzáfértek a belső forráskódokhoz, adminisztrációs felületekhez és a fejlesztői kommunikációhoz. Az incidens hatására az üzemeltetők elkezdték szigorítani a Kréta REST API végpontjait és az azonosítási folyamatokat.",
      },
    ],
  },
  {
    id: "era-refilc",
    period: "2022–2023",
    title: "Közösségi átvétel: reFilc és a QwIT",
    badge: "2022–2023",
    icon: GitBranch,
    nodeColor: "blue",
    items: [
      {
        id: "refilc",
        period: "2022–2023",
        title: "reFilc és a QwIT csapata",
        subtitle: "reFilc / QwIT Development • app-legacy",
        repo: "QwIT-Development/app-legacy",
        url: "https://github.com/QwIT-Development/app-legacy",
        icon: GitBranch,
        tag: "Közösségi átvétel",
        tagColor: "blue",
        description:
          "Az eredeti Filc projekt inaktivitása után új csapat vette át a kódbázis karbantartását. Megszületett a reFilc, amely kezelte a változó API-végpontokat. A csapat később a QwIT-Development szervezetbe tömörült, a régi reFilc Flutter-kódbázist pedig átnevezték app-legacy-ra.",
      },
    ],
  },
  {
    id: "era-modern",
    period: "2023–2026",
    title: "Párhuzamos modern kliensek és új generáció",
    badge: "2023–2026",
    description:
      "A Kréta-ökoszisztéma szétválása és kibontakozása: független fejlesztők és csapatok egymással párhuzamosan indítottak asztali, mobil, parancssori és kiterjesztéses projekteket.",
    icon: Layers,
    nodeColor: "orange",
    isMultiColumn: true,
    items: [
      {
        id: "firka",
        period: "2023–napjainkig",
        title: "Firka",
        subtitle: "QwIT-Development • Újraírás & Bővítmény",
        repo: "QwIT-Development/firka",
        url: "https://github.com/QwIT-Development/firka",
        icon: PenTool,
        tag: "Teljes újraírás",
        tagColor: "purple",
        description:
          "A QwIT fejlesztői úgy döntöttek, hogy a régi, nehezen karbantartható app-legacy kódot nem foltozzák tovább. A Firka néven futó projektet a nulláról írják újra teljesen modern dizájnnal és optimalizált motorral. Ezzel párhuzamosan böngészőbővítményt (firka-extension) is fejlesztettek az e-Kréta webes felületének megszépítésére.",
      },
      {
        id: "folio",
        period: "2023–2024",
        title: "Folio",
        subtitle: "Zan1456 • Android Material You",
        repo: "Zan1456/folio",
        url: "https://github.com/Zan1456/folio",
        icon: Smartphone,
        tag: "Material You & Fork",
        tagColor: "green",
        description:
          "Amíg az új Firka teljes átírása folyamatban van, Zan1456 elkészítette a Folio projektet. Ez a QwIT app-legacy kódbázis közvetlen forkja. A Folio Material You dizájnt kapott, optimalizálta az erőforrás-használatot, és pótolta a régi kliens régóta kért hiányosságait kizárólag modern Android felületekre koncentrálva.",
      },
      {
        id: "toll",
        period: "2023–2024",
        title: "Toll",
        subtitle: "doomhyena • Asztali Wails v2 (Go + React)",
        repo: "doomhyena/toll",
        url: "https://github.com/doomhyena/toll",
        icon: Monitor,
        tag: "Asztali kliens",
        tagColor: "blue",
        description:
          "A mobilappok mellett megjelentek az asztali megoldások is. A doomhyena által készített Toll egy asztali (desktop) e-Kréta kliens Windows, Linux és macOS rendszerekre. A projekt technológiai háttere a Wails v2: a backend Go nyelven kezeli a Kréta Mobile API-t és a tokeneket, a kezelőfelület pedig React és TypeScript alapú.",
      },
      {
        id: "rsfilc",
        period: "2023–napjainkig",
        title: "rsfilc",
        subtitle: "Kovács Jeromos (jarjk) • Rust CLI & TUI",
        repo: "jarjk/rsfilc",
        url: "https://github.com/jarjk/rsfilc",
        icon: Terminal,
        tag: "Rust parancssor",
        tagColor: "warning",
        description:
          "A terminálos és alacsony szintű eszközök képviselője. Kovács Jeromos (jarjk) Rust nyelven írta meg ezt a parancssoros (CLI) Kréta-klienst. Saját Rust API-csomagot (ekreta) használ, gyors adatgyorsítótárazást, offline működést (NO_NET mód) és héj-kiegészítéseket (bash, zsh, fish, elvish) kínál.",
      },
      {
        id: "kreta-iot",
        period: "2025–napjainkig",
        title: "Kréta Okosotthon & Eszközök",
        subtitle: "majorcs & daaniiieel • Home Assistant & Todoist integráció",
        repo: "majorcs/kreta-homeassistant",
        url: "https://github.com/majorcs/kreta-homeassistant",
        icon: Home,
        tag: "IoT & Okosotthon",
        tagColor: "blue",
        description:
          "A Kréta-ökoszisztéma kilépett a képernyőkről: a majorcs által készített Home Assistant integráció lehetővé tette a másnapi első óra, a házi feladatok és órarend közvetlen megjelenítését okosotthonos fali paneleken, míg a Homie a feladatok szinkronizálását automatizálta Todoistbe.",
      },
      {
        id: "pala",
        period: "2024–napjainkig",
        title: "Pala",
        subtitle: "CsPS0 • TUI, Asztali, Mobil és Bővítmény",
        repo: "CsPS0/pala",
        url: "https://github.com/CsPS0/pala",
        icon: Zap,
        tag: "Új generáció",
        tagColor: "orange",
        highlight: true,
        description:
          "A Pala a legújabb generációs, alternatív kliensek sorába tartozó nyílt forráskódú projekt a GitHubon. Az elődeihez hasonlóan az e-Kréta hivatalos megoldásainak leváltására jött létre, célja az egyszerűbb felépítés és a közvetlen kezelhetőség.",
      },
    ],
  },
];

const SECTION_4_TIMELINE: TimelineEra[] = [
  {
    id: "s4-origins",
    period: "1997–2010-es évek",
    title: "A Neptun születése és országos egyeduralma",
    badge: "1997–",
    icon: BookOpen,
    nodeColor: "blue",
    items: [
      {
        id: "neptun-origins",
        period: "1997–napjainkig",
        title: "Neptun Egységes Tanulmányi Rendszer",
        subtitle: "SDA Informatika Zrt. (korábban Neptun Kft.) • ASP.NET WebForms",
        url: "https://www.neptun.hu",
        icon: BookOpen,
        tag: "Felsőoktatási monopólium",
        tagColor: "blue",
        description:
          "1997-ben indult útjára a magyar egyetemek és főiskolák (BME, ELTE, Corvinus, Debreceni Egyetem, PTE, SZTE, Óbudai Egyetem) központi tanulmányi rendszere. Az évtizedek során fokozatosan kiszorította a rivális ETR-t (Egységes Tanulmányi Rendszer). A félévkezdési tárgyfelvételi szerverösszeomlások, a 10 perces inaktivitási kijelentkeztetés és a nehézkes táblázatok hallgatók százezreinek mindennapi küzdelmévé váltak.",
      },
    ],
  },
  {
    id: "s4-npu",
    period: "2014–2022",
    title: "A Neptun PowerUp! (NPU) forradalma",
    badge: "2014–2022",
    icon: Sparkles,
    nodeColor: "green",
    items: [
      {
        id: "npu-original",
        period: "2014–2022",
        title: "Neptun PowerUp! (NPU)",
        subtitle: "Solymosi Máté (szalio / solymosi) • Chrome & Firefox kiegészítő",
        repo: "solymosi/npu",
        url: "https://github.com/solymosi/npu",
        icon: Sparkles,
        tag: "Megszűnt / Archivált",
        tagColor: "danger",
        highlight: true,
        description:
          "Solymosi Máté (szalio) által fejlesztett böngészőbővítmény, amely több mint 20 000 egyetemista legfontosabb eszközévé vált országszerte. Megoldotta a hírhedt automatikus kidobást (Keep-Alive munkamenet-megőrzés), bevezette az azonnali KKI és tanulmányi átlagszámítást, a betelt kurzusok helyfigyelőjét, az egykattintásos tárgyfelvételt, a naptárexportot (.ics) és a modern sötét témát.",
      },
    ],
  },
  {
    id: "s4-modern",
    period: "2020–2026",
    title: "Új generációs egyetemi kliensek és kiegészítők",
    badge: "2020–2026",
    description:
      "Automatizált CAPTCHA-megoldók, alternatív mobilkliensek és az új Neptun felülethez készült modern átiratok:",
    icon: Layers,
    nodeColor: "orange",
    isMultiColumn: true,
    items: [
      {
        id: "csn",
        period: "2023–napjainkig",
        title: "CSN — Captcha Solver for Neptun",
        subtitle: "LetsUpdate • Kliensoldali OCR / Képfelismerés",
        repo: "LetsUpdate/CSN",
        url: "https://github.com/LetsUpdate/CSN",
        icon: Zap,
        tag: "Tárgyfelvételi védelem",
        tagColor: "warning",
        description:
          "Amikor a tárgyfelvételi roham lassítására a Neptun kötelező matematikai és képes CAPTCHA-kat vezetett be, egyetemisták elkészítették a CSN kiegészítőt. Ez másodpercek töredéke alatt, helyi képelemzéssel automatikusan kitöltötte az ellenőrzőkódot, visszaadva az esélyegyenlőséget a diákoknak.",
      },
      {
        id: "szaturn",
        period: "2021–2023",
        title: "Szaturn",
        subtitle: "davidsusu • Modern felületi motor a Neptunhoz",
        repo: "davidsusu/szaturn",
        url: "https://github.com/davidsusu/szaturn",
        icon: Monitor,
        tag: "UI újragondolás",
        tagColor: "blue",
        description:
          "Nyílt forráskódú böngészőbővítmény, amely modern, kártyás, reszponzív felületté alakította át az ASP.NET WebForms alapú nehézkes táblázatokat, bizonyítva, hogy a Neptunból is lehet tiszta webes alkalmazást faragni.",
      },
      {
        id: "karmin",
        period: "2024–napjainkig",
        title: "Karmin (ELTE Neptun Mobil)",
        subtitle: "Nanda070 • Flutter / Dart natív mobilalkalmazás",
        repo: "Nanda070/karmin",
        url: "https://github.com/Nanda070/karmin",
        icon: Smartphone,
        tag: "Megszűnt / Archivált",
        tagColor: "danger",
        description:
          "Független, nyílt forráskódú Flutter mobilalkalmazás az ELTE hallgatói számára. A hivatalos Neptun mobilapp nehézkessége és fagyásai helyett natív, letisztult mobilos felületet nyújt a kurzusok, jegyek és vizsgaidőpontok zsebben követésére.",
      },
      {
        id: "npu-next",
        period: "2024–2026",
        title: "Neptun PowerUp! Next & NG",
        subtitle: "rozsadomb, l1pz & klevcsoo • TypeScript & React átiratok",
        repo: "rozsadomb/neptun-powerup",
        url: "https://github.com/rozsadomb/neptun-powerup",
        icon: Sparkles,
        tag: "Új generáció",
        tagColor: "green",
        description:
          "Amikor az egyetemek 2024 és 2026 között elkezdték bevezetni a megújult Neptun webes felületet, az eredeti NPU kódját az új generációs hallgatói fejlesztők modern technológiákkal (TypeScript, modern WebExtensions API) újraírták, életben tartva a kidobásvédelmet és a gyors tárgyfelvételt.",
      },
    ],
  },
];

interface ChapterSeparator {
  id: string;
  number: string;
  title: string;
  subtitle: string;
  badge: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  accentColor: "blue" | "orange" | "purple" | "green";
  paragraphs: string[];
  timelineEras: TimelineEra[];
  defaultOpen?: boolean;
}

const CHAPTERS: ChapterSeparator[] = [
  {
    id: "chapter-1",
    number: "01",
    title: "Európai külföldi elektronikus ellenőrzők",
    subtitle: "Nemzetközi kitekintés: iskolai LMS rendszerek és külföldi közösségi kliensek",
    badge: "Nemzetközi kontextus",
    icon: Globe,
    accentColor: "blue",
    paragraphs: [
      "Nyugat-Európában és Észak-Amerikában a tanulmányi adminisztráció digitalizációja már a 2000-es évek elején megkezdődött. Franciaországban a Pronote és az EcoleDirecte, a német nyelvterületen (Németország, Ausztria) a WebUntis és a Schulportal, az Egyesült Államokban és Nagy-Britanniában pedig a PowerSchool, a Canvas és a Google Classroom vált meghatározóvá.",
      "A legtöbb európai országban decentralizált modell működik: az oktatási intézmények maguk választhatnak a piacon versenyző tanulmányi szoftverek közül. Ez a piaci verseny folyamatos innovációra ösztönözte a cégeket, szemben az egyetlen központi állami monopóliumra épülő megoldásokkal.",
      "A hivatalos iskolai alkalmazások hiányosságai nem kizárólag magyar sajátosságok: Franciaországban például a diákok a Papillon és az YNotes nevű nyílt forráskódú klienseket hozták létre a Pronote és EcoleDirecte rendszerekhez, Lengyelországban a Wulkanowy vált a VULCAN UONET+ alternatívájává, a német nyelvterületen pedig a BetterUntis kínál nyílt forráskódú órarendet. A diákfejlesztésű alternatív kliensek nemzetközi szinten is a tehetséges fiatal programozók legfontosabb gyakorlóterepei közé tartoznak.",
    ],
    timelineEras: SECTION_1_TIMELINE,
    defaultOpen: false,
  },
  {
    id: "chapter-2",
    number: "02",
    title: "A kezdet Magyarországon (MozaNapló és Kréta bejövetele)",
    subtitle: "A papíralapú ellenőrzőtől az első digitális naplókig, majd az állami központosításig",
    badge: "2000-es évek – 2018",
    icon: BookOpen,
    accentColor: "orange",
    paragraphs: [
      "A 2000-es évek derekáig a magyar közoktatásban kizárólag a kézzel vezetett papír ellenőrző könyv és a fizikai osztálynapló létezett. A jegyeket a tanárok tollal írták be, a szülők havonta írták alá az ellenőrzőt, a félévi és év végi átlagszámítás pedig manuálisan történt.",
      "A szegedi Mozaik Kiadó által fejlesztett MozaNapló (a MozaWeb oktatási platform részeként) volt az egyik legelső és legfejlettebb elektronikus napló Magyarországon. Integrálva volt a digitális tankönyvekkel, 3D modellekkel és interaktív feladatokkal. A 2010-es évek elejére a hazai iskolák jelentős részében a MozaNapló vált a legelterjedtebb digitális naplóvá a Magiszter és egyéb helyi rendszerek mellett.",
      "2015 és 2018 között azonban az állami oktatásirányítás és a Klebelsberg Központ elindította a KRÉTA (Köznevelési Regisztrációs és Tanulmányi Alaprendszer) bevezetését. Célul tűzték ki az összes állami fenntartású általános iskola, gimnázium és technikum egyetlen központi szoftverbe terelését, felváltva a piacon addig versenyző független szoftvereket.",
    ],
    timelineEras: SECTION_2_TIMELINE,
    defaultOpen: false,
  },
  {
    id: "chapter-3",
    number: "03",
    title: "Kliensek születése, és a Kréta helyzete, a MozaWeb bukása",
    subtitle: "A Kréta-kliensek születése és evolúciója a Szivacs Naplótól a párhuzamos modern kliensekig és rétegprojektekig",
    badge: "2018–2026 Idővonal",
    icon: Zap,
    accentColor: "purple",
    paragraphs: [
      "A Kréta kötelezővé tételével a tankerületi iskolák kötelesek voltak átállni az új állami rendszerre, így a MozaNapló szinte egyik napról a másikra kiszorult az állami közoktatásból. A Mozaik Kiadó ezután elsősorban a digitális tananyagai (mozaBook, mozaWeb) nemzetközi értékesítésére fókuszált, a MozaNapló pedig alapítványi és egyházi intézmények szűk körére szorult vissza.",
      "A Kréta egyeduralkodóvá válásával több mint egymillió diák és szülő kényszerült a rendszer mindennapi használatára. A hivatalos webes felület azonban nehézkes volt, a hivatalos mobilalkalmazás pedig lassú, instabil, hiányoztak belőle az áttekinthető átlagstatisztikák, és a reggeli vagy félévi szerverterhelések idején rendszeresen megbénult.",
      "A hivatalos mobilapp a háttérben egy viszonylag egyszerű REST API-t és OAuth2 azonosítást használt. Ezt felismerve lelkes középiskolás és egyetemista diákfejlesztők elkezdték visszafejteni a hálózati forgalmat. Rájöttek, hogy olyan egyedi klienseket hozhatnak létre, amelyek gyorsak, letisztultak, reklámmentesek, offline is működnek és azonnal kiszámolják a várható átlagokat. Ebből a szikrából született meg 2018-ban a Szivacs Napló, elindítva a magyar nyílt forráskódú Kréta-kliensek máig tartó történetét:",
    ],
    timelineEras: SECTION_3_TIMELINE,
    defaultOpen: true,
  },
  {
    id: "chapter-4",
    number: "04",
    title: "Egyetemi világ: A Neptun és a hallgatói kiegészítők",
    subtitle: "Felsőoktatási tanulmányi rendszerek, tárgyfelvételi szerverösszeomlások, a Neptun PowerUp! és a hallgatói kiegészítők",
    badge: "Felsőoktatás & Egyetemek",
    icon: GraduationCap,
    accentColor: "green",
    paragraphs: [
      "A középiskolai évek után az egyetemekre és főiskolákra (BME, ELTE, Debreceni Egyetem, Corvinus, SZTE, PTE, Óbudai Egyetem stb.) belépve a magyar diákok egy másik, még régebbi tanulmányi rendszerrel szembesülnek: az SDA Informatika Zrt. által fejlesztett Neptunnal.",
      "A Neptun hírhedté vált a félév eleji tárgyfelvételi és vizsgajelentkezési rohamokról: amikor tízezrek próbálnak egyszerre kurzust felvenni, a szerverek túlterhelődnek, az automatikus 10 perces inaktivitási időkorlát miatt a rendszer kidobja a várakozókat, a később bevezetett matematikai és képi CAPTCHA-k pedig tovább fokozták a stresszt.",
      "Ahogyan a középiskolában a Kréta, úgy az egyetemeken a Neptun hiányosságai hívták életre a magyar egyetemisták leginnovatívabb fejlesztéseit: a legendás Neptun PowerUp! (NPU) bővítménytől kezdve az automatizált CAPTCHA-megoldókon át a modern ELTE Karmin Flutter mobilkliensig és az új generációs NPU Next projektekig a hallgatói önszerveződés az egyetemi élet elengedhetetlen részévé vált.",
    ],
    timelineEras: SECTION_4_TIMELINE,
    defaultOpen: false,
  },
];

const TAG_STYLES = {
  orange: "bg-[#ff8800]/15 text-[#ff8800] border-[#ff8800]/30",
  danger: "bg-[#ff453a]/15 text-[#ff453a] border-[#ff453a]/30",
  warning: "bg-[#ffd60a]/15 text-[#ffd60a] border-[#ffd60a]/30",
  blue: "bg-[#0a84ff]/15 text-[#0a84ff] border-[#0a84ff]/30",
  purple: "bg-[#bf5af2]/15 text-[#bf5af2] border-[#bf5af2]/30",
  green: "bg-[#30d158]/15 text-[#30d158] border-[#30d158]/30",
};

const NODE_STYLES = {
  orange: "border-[#ff8800] text-[#ff8800] bg-[#1b1511]",
  danger: "border-[#ff453a] text-[#ff453a] bg-[#1f1214]",
  warning: "border-[#ffd60a] text-[#ffd60a] bg-[#1c1a12]",
  blue: "border-[#0a84ff] text-[#0a84ff] bg-[#111722]",
  purple: "border-[#bf5af2] text-[#bf5af2] bg-[#191220]",
  green: "border-[#30d158] text-[#30d158] bg-[#121c15]",
};

const ACCENT_STYLES = {
  blue: {
    border: "border-[#0a84ff]/40",
    badge: "bg-[#0a84ff]/15 text-[#0a84ff] border-[#0a84ff]/30",
    icon: "bg-[#0a84ff]/10 text-[#0a84ff] border-[#0a84ff]/25",
  },
  orange: {
    border: "border-[#ff8800]/40",
    badge: "bg-[#ff8800]/15 text-[#ff8800] border-[#ff8800]/30",
    icon: "bg-[#ff8800]/10 text-[#ff8800] border-[#ff8800]/25",
  },
  purple: {
    border: "border-[#bf5af2]/40",
    badge: "bg-[#bf5af2]/15 text-[#bf5af2] border-[#bf5af2]/30",
    icon: "bg-[#bf5af2]/10 text-[#bf5af2] border-[#bf5af2]/25",
  },
  green: {
    border: "border-[#30d158]/40",
    badge: "bg-[#30d158]/15 text-[#30d158] border-[#30d158]/30",
    icon: "bg-[#30d158]/10 text-[#30d158] border-[#30d158]/25",
  },
};

function EventCard({ event }: { event: TimelineEvent }) {
  const IconComp = event.icon;
  const tagStyle = TAG_STYLES[event.tagColor];

  return (
    <div
      className={`rounded-2xl p-5 sm:p-6 transition-colors flex flex-col justify-between h-full ${
        event.highlight
          ? "bg-[#1b1b1f] border-2 border-[#ff8800]"
          : event.isBreach
          ? "bg-[#171214] border border-[#ff453a]/40 hover:border-[#ff453a]/70"
          : "bg-[#151518] border border-[#28282d] hover:border-[#ff8800]/50"
      }`}
    >
      <div>
        {/* Card Header: Period & Tag */}
        <div className="flex flex-wrap items-center gap-2 mb-3">
          <span className="inline-flex items-center gap-1.5 text-xs font-mono font-bold text-[#f3f3f6] bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded-lg">
            <Calendar size={12} className="text-[#ff8800]" />
            <span>{event.period}</span>
          </span>
          <span className={`text-[10px] font-bold border px-2.5 py-0.5 rounded-full ${tagStyle}`}>
            {event.tag}
          </span>
        </div>

        {/* Title & Subtitle */}
        <h3 className="flex items-center gap-2 text-lg sm:text-xl font-black text-[#f3f3f6] mb-1">
          <IconComp size={17} className="text-[#8c8c94] shrink-0" />
          <span>{event.title}</span>
        </h3>
        <p
          className={`text-xs font-semibold mb-3 ${
            event.highlight
              ? "text-[#ff8800]"
              : event.isBreach
              ? "text-[#ff453a]"
              : "text-[#8c8c94]"
          }`}
        >
          {event.subtitle}
        </p>

        {/* Body Text */}
        <p className="text-xs sm:text-sm text-[#c5c5cc] leading-relaxed mb-5">
          {event.description}
        </p>
      </div>

      {/* Footer Link */}
      <div className="pt-3 border-t border-[#28282d]/80 flex items-center justify-between text-xs mt-auto">
        {event.repo && event.url ? (
          <a
            href={event.url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 font-bold text-[#f3f3f6] hover:text-[#ff8800] transition-colors"
          >
            <span className="font-mono text-[11px]">{event.repo}</span>
            <ExternalLink size={12} />
          </a>
        ) : event.url ? (
          <a
            href={event.url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 font-bold text-[#f3f3f6] hover:text-[#ff8800] transition-colors"
          >
            <span className="font-mono text-[11px]">Hivatalos oldal</span>
            <ExternalLink size={12} />
          </a>
        ) : (
          event.isBreach && (
            <span className="text-[11px] font-semibold text-[#ff453a]">
              A modern Kréta API biztonsági architektúra kezdete
            </span>
          )
        )}
      </div>
    </div>
  );
}

function SectionTimeline({ timelineEras }: { timelineEras: TimelineEra[] }) {
  return (
    <div className="relative pl-6 sm:pl-10 space-y-10 sm:space-y-12 before:absolute before:left-3 sm:before:left-5 before:top-4 before:bottom-4 before:w-px before:bg-[#28282d] pt-2">
      {timelineEras.map((era) => {
        const EraIcon = era.icon;
        const nodeStyle = NODE_STYLES[era.nodeColor];

        return (
          <div key={era.id} className="relative">
            {/* Timeline Spine Node */}
            <div
              className={`absolute -left-[30px] sm:-left-[44px] top-1.5 w-8 h-8 sm:w-10 sm:h-10 rounded-xl sm:rounded-2xl border flex items-center justify-center z-10 ${nodeStyle}`}
            >
              <EraIcon size={18} />
            </div>

            {/* Era Content Container */}
            <div className="space-y-4">
              {/* If era has multiple parallel columns, show a section header */}
              {era.isMultiColumn ? (
                <div className="space-y-4">
                  <div className="space-y-1.5">
                    <span className="text-xs font-mono font-black text-[#ff8800] bg-[#ff8800]/10 border border-[#ff8800]/30 px-2.5 py-0.5 rounded-md inline-block">
                      {era.badge}
                    </span>
                    <h4 className="text-base sm:text-lg font-black text-[#f3f3f6]">
                      {era.title}
                    </h4>
                    {era.description && (
                      <p className="text-xs sm:text-sm text-[#8c8c94] leading-relaxed">
                        {era.description}
                      </p>
                    )}
                  </div>

                  {/* Multi-column grid: between 2023 and 2026 clients run beside each other */}
                  <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5 items-stretch">
                    {era.items.map((event) => {
                      const isLastFeatured = event.highlight;
                      return (
                        <div
                          key={event.id}
                          className={isLastFeatured ? "md:col-span-2 xl:col-span-2" : "col-span-1"}
                        >
                          <EventCard event={event} />
                        </div>
                      );
                    })}
                  </div>
                </div>
              ) : (
                /* Single-column chronological era milestone */
                <div>
                  {era.items.map((event) => (
                    <EventCard key={event.id} event={event} />
                  ))}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function ClientHistory() {
  const [openChapters, setOpenChapters] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(CHAPTERS.map((c) => [c.id, Boolean(c.defaultOpen)]))
  );
  const [selectedEra, setSelectedEra] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState<string>("");

  const toggleChapter = (id: string) => {
    setOpenChapters((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const setAllChapters = (open: boolean) => {
    setOpenChapters(Object.fromEntries(CHAPTERS.map((c) => [c.id, open])));
  };

  const normalizedQuery = searchQuery.trim().toLowerCase();

  const filteredChapters = CHAPTERS.filter((chapter) => {
    if (selectedEra !== "all" && chapter.id !== selectedEra) {
      return false;
    }
    if (!normalizedQuery) return true;

    if (
      chapter.title.toLowerCase().includes(normalizedQuery) ||
      chapter.subtitle.toLowerCase().includes(normalizedQuery)
    ) {
      return true;
    }

    return chapter.timelineEras.some((era) =>
      era.title.toLowerCase().includes(normalizedQuery) ||
      era.items.some(
        (item) =>
          item.title.toLowerCase().includes(normalizedQuery) ||
          item.subtitle.toLowerCase().includes(normalizedQuery) ||
          item.description.toLowerCase().includes(normalizedQuery) ||
          (item.repo && item.repo.toLowerCase().includes(normalizedQuery)) ||
          item.period.toLowerCase().includes(normalizedQuery)
      )
    );
  }).map((chapter) => {
    if (!normalizedQuery) return chapter;
    const filteredEras = chapter.timelineEras.map((era) => {
      const eraMatches = era.title.toLowerCase().includes(normalizedQuery);
      if (eraMatches) return era;
      const matchingItems = era.items.filter(
        (item) =>
          item.title.toLowerCase().includes(normalizedQuery) ||
          item.subtitle.toLowerCase().includes(normalizedQuery) ||
          item.description.toLowerCase().includes(normalizedQuery) ||
          (item.repo && item.repo.toLowerCase().includes(normalizedQuery)) ||
          item.period.toLowerCase().includes(normalizedQuery)
      );
      return {
        ...era,
        items: matchingItems,
      };
    }).filter((era) => era.items.length > 0);

    return {
      ...chapter,
      timelineEras: filteredEras,
    };
  });

  const totalMatchCount = normalizedQuery
    ? filteredChapters.reduce(
        (acc, chap) =>
          acc + chap.timelineEras.reduce((eAcc, era) => eAcc + era.items.length, 0),
        0
      )
    : 0;

  const areAllOpen = Object.values(openChapters).every(Boolean);

  return (
    <section className="w-full space-y-8 sm:space-y-10">
      {/* Header and Lead */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
            ÖKOSZISZTÉMA & KÖZÖSSÉG
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-2">
            A Kréta- és Iskolai Kliensek Története
          </h1>
          <p className="text-xs sm:text-sm text-[#8c8c94] leading-relaxed max-w-3xl">
            A Kréta-kliensek fejlődése, a hazai és külföldi alternatív elektronikus naplók, valamint az egyetemi Neptun-kiegészítők átfogó közösségi krónikája.
          </p>
        </div>

        {/* Global Expand/Collapse Button */}
        <button
          onClick={() => setAllChapters(!areAllOpen)}
          className="inline-flex items-center gap-1.5 self-start sm:self-auto bg-[#1b1b1f] hover:bg-[#222227] text-[#8c8c94] hover:text-[#f3f3f6] border border-[#28282d] text-xs font-bold px-3 py-2 rounded-xl transition-colors cursor-pointer shrink-0"
        >
          <ChevronsUpDown size={14} />
          <span>{areAllOpen ? "Összes becsukása" : "Összes kinyitása"}</span>
        </button>
      </div>

      {/* Search & Era Filter Toolbar */}
      <div className="space-y-3 bg-[#151518] border border-[#28282d] p-3 sm:p-4 rounded-2xl">
        {/* Search Input Bar */}
        <div className="relative flex items-center">
          <Search size={16} className="absolute left-3.5 text-[#8c8c94] pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Keresés mérföldkövek és projektek között (pl. Filc, e-Szivacs, Neptun, 2022)..."
            className="w-full bg-[#111114] border border-[#28282d] focus:border-[#ff8800] rounded-xl pl-10 pr-10 py-2.5 text-xs sm:text-sm text-[#f3f3f6] placeholder-[#5f5f67] outline-none transition-colors"
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => setSearchQuery("")}
              className="absolute right-3 text-[#8c8c94] hover:text-white p-1 rounded-md cursor-pointer"
              aria-label="Keresés törlése"
            >
              <X size={14} />
            </button>
          )}
        </div>

        {/* Era Filter Pills Row */}
        <div className="flex items-center gap-1.5 sm:gap-2 overflow-x-auto no-scrollbar pt-1 text-xs">
          {[
            { id: "all", label: "Összes korszak" },
            { id: "chapter-1", label: "1. Nemzetközi LMS" },
            { id: "chapter-2", label: "2. MozaNapló & Kezdetek" },
            { id: "chapter-3", label: "3. Kréta & Filc/Pala" },
            { id: "chapter-4", label: "4. Egyetemi Neptun" },
          ].map((tab) => (
            <button
              key={tab.id}
              type="button"
              onClick={() => {
                setSelectedEra(tab.id);
                if (tab.id !== "all") {
                  setOpenChapters((prev) => ({ ...prev, [tab.id]: true }));
                }
              }}
              className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap cursor-pointer transition-all ${
                selectedEra === tab.id
                  ? "bg-[#ff8800] text-black"
                  : "bg-[#1b1b1f] hover:bg-[#222227] text-[#8c8c94] hover:text-[#f3f3f6] border border-[#28282d]"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search Results Summary */}
        {normalizedQuery && (
          <div className="text-xs text-[#8c8c94] pt-1 flex items-center justify-between">
            <span>
              {totalMatchCount > 0
                ? `${totalMatchCount} mérföldkő találat erre: "${searchQuery}"`
                : `Nincs találat erre a keresésre: "${searchQuery}"`}
            </span>
            <button
              type="button"
              onClick={() => setSearchQuery("")}
              className="text-[#ff8800] hover:underline cursor-pointer"
            >
              Keresés visszaállítása
            </button>
          </div>
        )}
      </div>

      {/* Chapters as Separator Dropdowns with their timelines inside */}
      <div className="space-y-6">
        {filteredChapters.map((chapter) => {
          const isOpen = normalizedQuery ? true : Boolean(openChapters[chapter.id]);
          const IconComp = chapter.icon;
          const styles = ACCENT_STYLES[chapter.accentColor];

          return (
            <div
              key={chapter.id}
              className={`rounded-2xl sm:rounded-3xl bg-[#151518] border transition-all overflow-hidden ${
                isOpen
                  ? `${styles.border} bg-[#16161a]`
                  : "border-[#28282d] hover:border-[#383840] hover:bg-[#19191d]"
              }`}
            >
              {/* Separator / Dropdown Header Button */}
              <button
                type="button"
                onClick={() => toggleChapter(chapter.id)}
                className="group w-full text-left p-5 sm:p-7 flex items-start sm:items-center justify-between gap-4 cursor-pointer select-none transition-colors"
                aria-expanded={isOpen}
              >
                <div className="flex items-start sm:items-center gap-3.5 sm:gap-5 flex-1 min-w-0">
                  <div
                    className={`w-11 h-11 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl border flex items-center justify-center shrink-0 ${styles.icon}`}
                  >
                    <IconComp size={20} />
                  </div>

                  <div className="space-y-1 min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-xs font-mono font-black text-[#ff8800]">
                        [{chapter.number}]
                      </span>
                      <span className={`text-[10px] font-bold border px-2.5 py-0.5 rounded-full ${styles.badge}`}>
                        {chapter.badge}
                      </span>
                    </div>

                    <h2 className="text-base sm:text-xl font-black text-[#f3f3f6] group-hover:text-[#ff8800] transition-colors">
                      {chapter.title}
                    </h2>
                    <p className="text-xs sm:text-sm text-[#8c8c94] line-clamp-1">
                      {chapter.subtitle}
                    </p>
                  </div>
                </div>

                <div
                  className={`shrink-0 mt-1 sm:mt-0 transition-transform duration-300 ${
                    isOpen ? "rotate-180 text-[#ff8800]" : "text-[#8c8c94]"
                  }`}
                >
                  <ChevronDown size={20} />
                </div>
              </button>

              {/* Separator Body: Narrative + Timeline Inside */}
              {isOpen && (
                <div className="px-5 sm:px-8 pb-8 pt-2 border-t border-[#28282d]/80 animate-fadeIn space-y-8">
                  {/* Context Narrative */}
                  <div className="space-y-3 text-xs sm:text-sm text-[#c5c5cc] leading-relaxed">
                    {chapter.paragraphs.map((p, pIdx) => (
                      <p key={pIdx}>{p}</p>
                    ))}
                  </div>

                  <SectionTimeline timelineEras={chapter.timelineEras} />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
