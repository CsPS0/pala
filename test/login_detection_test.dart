import 'package:pala/api/client.dart';
import 'package:test/test.dart';

// Every Kréta login page loads this script, captcha or not.
const _recaptchaScript = '<script src="https://www.recaptcha.net/recaptcha/api.js" async defer></script>';
const _loginForm = '<input type="password" id="Password" name="Password" class="form-control">';

void main() {
  group('interactiveLoginReason', () {
    test('login form again means wrong credentials, even with the recaptcha script', () {
      expect(interactiveLoginReason('$_recaptchaScript$_loginForm'), isNull);
    });

    test('rendered captcha widget', () {
      const html = '$_recaptchaScript$_loginForm<div class="g-recaptcha" data-sitekey="abc"></div>';
      expect(interactiveLoginReason(html), InteractiveLoginReason.captcha);
    });

    test('two-factor code field', () {
      const html = '<input type="text" id="VerificationCode" name="VerificationCode">';
      expect(interactiveLoginReason(html), InteractiveLoginReason.verificationCode);
    });

    test('any other page is an unknown extra step', () {
      expect(interactiveLoginReason('<html><body>Valami más</body></html>'), InteractiveLoginReason.unknown);
    });
  });

  group('KretaClient.codeFromPasted', () {
    test('full redirect URL', () {
      expect(
        KretaClient.codeFromPasted('https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect?code=ABC123&state=x'),
        'ABC123',
      );
    });

    test('code in the fragment', () {
      expect(KretaClient.codeFromPasted('https://mobil.e-kreta.hu/oauthredirect#code=ABC123&state=x'), 'ABC123');
    });

    test('bare code, with or without the rest of the query', () {
      expect(KretaClient.codeFromPasted('  ABC123 '), 'ABC123');
      expect(KretaClient.codeFromPasted('ABC123&scope=openid'), 'ABC123');
    });
  });

  test('InteractiveLoginRequired message is Hungarian and points to the Kréta page', () {
    final message = const InteractiveLoginRequired(InteractiveLoginReason.verificationCode).toString();
    expect(message, contains('kétlépcsős'));
    expect(message, contains('Kréta saját oldalán'));
  });
}
