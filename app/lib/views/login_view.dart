import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pala/api/client.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class LoginView extends StatefulWidget {
  final AppModel appModel;

  const LoginView({super.key, required this.appModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _schoolSearchController = TextEditingController();
  final _instituteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSearchingSchools = false;
  Map<String, String> _schoolSuggestions = {};
  Timer? _searchDebounce;

  @override
  void dispose() {
    _schoolSearchController.dispose();
    _instituteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSchoolSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _schoolSuggestions = {};
        _isSearchingSchools = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingSchools = true);
      try {
        final results = await KretaClient.searchSchools(query.trim());
        if (mounted) {
          setState(() {
            _schoolSuggestions = results;
            _isSearchingSchools = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearchingSchools = false);
      }
    });
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        final text = data.text!.replaceAll(RegExp(r'[\r\n]+'), '');
        setState(() {
          controller.text = text;
          controller.selection = TextSelection.collapsed(offset: text.length);
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    final inst = _instituteController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (inst.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek töltsd ki az összes mezőt!')),
      );
      return;
    }

    final success = await widget.appModel.login(
      instituteCode: inst,
      username: user,
      password: pass,
    );

    if (!success && mounted && widget.appModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.appModel.errorMessage!),
          backgroundColor: PalaTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PALA',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? 'Kréta Desktop Kliens' : 'Kréta Mobil Kliens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Jelentkezz be az e-napló fiókodba',
                      style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // School search input
                        Text(
                          'Intézmény Kereső',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _schoolSearchController,
                          onChanged: _onSchoolSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'pl. Klébelsberg vagy klik123...',
                            suffixIcon: _isSearchingSchools
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : Icon(Icons.search, size: 20),
                          ),
                        ),

                        // Suggestions list
                        if (_schoolSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: Material(
                              color: PalaTheme.sidebar,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: PalaTheme.border),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _schoolSuggestions.length,
                                separatorBuilder: (context, index) => Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final code = _schoolSuggestions.keys.elementAt(idx);
                                  final name = _schoolSuggestions[code]!;
                                  return ListTile(
                                    dense: true,
                                    title: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text(code, style: TextStyle(fontSize: 11, color: PalaTheme.textMuted)),
                                    onTap: () {
                                      setState(() {
                                        _instituteController.text = code;
                                        _schoolSearchController.text = name;
                                        _schoolSuggestions = {};
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Intézmény Azonosító (Kréta kód)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                              ),
                            ),
                            InkWell(
                              onTap: () => _pasteInto(_instituteController),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.content_paste_outlined, size: 13, color: primary),
                                    const SizedBox(width: 4),
                                    Text('Beillesztés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => _pasteInto(_instituteController),
                          },
                          child: TextField(
                            controller: _instituteController,
                            enableInteractiveSelection: true,
                            contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState),
                            decoration: InputDecoration(
                              hintText: 'pl. klik123456',
                              suffixIcon: IconButton(
                                tooltip: 'Beillesztés vágólapról',
                                icon: Icon(Icons.content_paste_outlined, size: 18),
                                onPressed: () => _pasteInto(_instituteController),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Felhasználónév (Oktatási Azonosító)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                              ),
                            ),
                            InkWell(
                              onTap: () => _pasteInto(_usernameController),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.content_paste_outlined, size: 13, color: primary),
                                    const SizedBox(width: 4),
                                    Text('Beillesztés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => _pasteInto(_usernameController),
                          },
                          child: TextField(
                            controller: _usernameController,
                            keyboardType: TextInputType.text,
                            enableInteractiveSelection: true,
                            contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState),
                            decoration: InputDecoration(
                              hintText: '7xxxxxxxxxx vagy felhasználónév',
                              suffixIcon: IconButton(
                                tooltip: 'Beillesztés vágólapról',
                                icon: Icon(Icons.content_paste_outlined, size: 18),
                                onPressed: () => _pasteInto(_usernameController),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Jelszó',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                              ),
                            ),
                            InkWell(
                              onTap: () => _pasteInto(_passwordController),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.content_paste_outlined, size: 13, color: primary),
                                    const SizedBox(width: 4),
                                    Text('Beillesztés', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => _pasteInto(_passwordController),
                          },
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enableInteractiveSelection: true,
                            contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Beillesztés vágólapról',
                                    icon: Icon(Icons.content_paste_outlined, size: 18),
                                    onPressed: () => _pasteInto(_passwordController),
                                  ),
                                  IconButton(
                                    tooltip: _obscurePassword ? 'Megjelenítés' : 'Elrejtés',
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: widget.appModel.isLoading ? null : _handleLogin,
                            child: widget.appModel.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : Text('Bejelentkezés'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Demo Login Button
                  OutlinedButton.icon(
                    onPressed: widget.appModel.isLoading ? null : () => widget.appModel.loginDemo(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: PalaTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: PalaTheme.text,
                    ),
                    icon: Icon(Icons.play_arrow_outlined, size: 18),
                    label: Text(
                      'Belépés Teszt Elek demó fiókkal',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
