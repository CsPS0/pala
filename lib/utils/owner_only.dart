import 'dart:io';

final Set<String> _restricted = {};

/// Creates [path] as a folder if needed and, on Linux and macOS, makes it
/// readable only by the current user (700). The login data, the key file and
/// the offline cache (which holds the student's personal data) all live in
/// such folders, so other accounts on a shared machine cannot read them.
/// Windows profile folders are already private to the user.
void ensureOwnerOnlyDir(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  if (!(Platform.isLinux || Platform.isMacOS) || !_restricted.add(path)) return;
  try {
    Process.runSync('chmod', ['700', path]);
  } catch (_) {}
}
