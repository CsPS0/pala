class Student {
  final String name;
  final String institutionName;
  final String? uid;
  final String? birthName;
  final String? birthPlace;
  final String? mothersName;
  final String? email;
  final String? phone;
  final List<String> addresses;
  final String? birthDate;
  final List<Map<String, dynamic>> guardians;
  final DateTime? nextDowntime;

  /// Kréta's institute code (IntezmenyAzonosito).
  final String? schoolCode;

  /// The class name, from the Osztaly group of OsztalyCsoportok (see [classNameOf]);
  /// TanuloAdatlap itself does not send it.
  final String? className;

  /// Bank account number and owner name, sent when the school recorded them.
  final String? bankAccount;
  final String? bankAccountOwner;

  const Student({
    required this.name,
    required this.institutionName,
    this.uid,
    this.birthName,
    this.birthPlace,
    this.mothersName,
    this.email,
    this.phone,
    this.addresses = const [],
    this.birthDate,
    this.guardians = const [],
    this.nextDowntime,
    this.schoolCode,
    this.className,
    this.bankAccount,
    this.bankAccountOwner,
  });

  Student withClassName(String? name) => Student(
        name: this.name,
        institutionName: institutionName,
        uid: uid,
        birthName: birthName,
        birthPlace: birthPlace,
        mothersName: mothersName,
        email: email,
        phone: phone,
        addresses: addresses,
        birthDate: birthDate,
        guardians: guardians,
        nextDowntime: nextDowntime,
        schoolCode: schoolCode,
        className: name,
        bankAccount: bankAccount,
        bankAccountOwner: bankAccountOwner,
      );

  factory Student.fromJson(Map<String, dynamic> json) {
    final inst = json['Intezmeny'];
    final settings = inst?['TestreszabasBeallitasok'];
    final nextDowntimeRaw = settings?['KovetkezoTelepitesDatuma'];
    DateTime? parsedNextDowntime;
    if (nextDowntimeRaw != null) {
      parsedNextDowntime = DateTime.tryParse(nextDowntimeRaw.toString())?.toLocal();
    }

    return Student(
      name: json['Nev'] ?? 'Ismeretlen',
      institutionName: json['IntezmenyNev'] ?? json['Intezmeny']?['TeljesNev'] ?? 'Ismeretlen intézmény',
      uid: json['Uid']?.toString(),
      birthName: json['SzuletesiNev'],
      birthPlace: json['SzuletesiHely'],
      mothersName: json['AnyjaNeve'],
      email: json['EmailCim'],
      phone: json['Telefonszam'],
      addresses: (json['Cimek'] as List?)?.map((e) => e.toString()).toList() ?? [],
      birthDate: json['SzuletesiDatum'],
      guardians: (json['Gondviselok'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      nextDowntime: parsedNextDowntime,
      schoolCode: json['IntezmenyAzonosito']?.toString(),
      bankAccount: json['Bankszamla']?['BankszamlaSzam']?.toString(),
      bankAccountOwner: json['Bankszamla']?['BankszamlaTulajdonosNeve']?.toString(),
    );
  }
}

/// The student's class name from Kréta's OsztalyCsoportok list: the group
/// whose Tipus is "Osztaly", else the first group, else null. The extension
/// mirrors this in `KretaApi.mainClassGroup`.
String? classNameOf(List<dynamic> groups) {
  final maps = groups.whereType<Map>().toList();
  if (maps.isEmpty) return null;
  final group = maps.firstWhere(
    (g) => g['Tipus']?.toString().toLowerCase() == 'osztaly',
    orElse: () => maps.first,
  );
  return group['Nev']?.toString();
}
