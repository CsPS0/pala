import 'dart:async';
import 'package:flutter/material.dart';
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
                      child: const Text(
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
                  const Center(
                    child: Text(
                      'Kréta Mobil Kliens',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
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
                        const Text(
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
                                : const Icon(Icons.search, size: 20),
                          ),
                        ),

                        // Suggestions list
                        if (_schoolSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 160),
                            child: Material(
                              color: PalaTheme.sidebar,
                              borderRadius: BorderRadius.circular(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: PalaTheme.border),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _schoolSuggestions.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final code = _schoolSuggestions.keys.elementAt(idx);
                                  final name = _schoolSuggestions[code]!;
                                  return ListTile(
                                    dense: true,
                                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text(code, style: const TextStyle(fontSize: 11, color: PalaTheme.textMuted)),
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
                        const Text(
                          'Intézmény Azonosító (Kréta kód)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _instituteController,
                          decoration: const InputDecoration(
                            hintText: 'pl. klik123456',
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Felhasználónév (Oktatási Azonosító)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: '7xxxxxxxxxx vagy felhasználónév',
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Jelszó',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                                : const Text('Bejelentkezés'),
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
                      side: const BorderSide(color: PalaTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: PalaTheme.text,
                    ),
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: const Text(
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
