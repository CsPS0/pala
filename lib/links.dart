/// Pala's public links, shown at the bottom of every client's settings.
/// The extension mirrors them in `KretaApi.palaLinks`. An empty URL hides
/// its entry (the Instagram account does not exist yet).
class PalaLinks {
  PalaLinks._();

  static const website = 'https://pala-app.hu';
  static const github = 'https://github.com/CsPS0/pala';
  static const instagram = '';

  static List<({String label, String url})> visible() => [
        (label: 'Weboldal', url: website),
        (label: 'GitHub', url: github),
        (label: 'Instagram', url: instagram),
      ].where((l) => l.url.isNotEmpty).toList();
}
