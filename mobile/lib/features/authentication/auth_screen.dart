import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

enum _AuthStep { signIn, register, verify, requestReset, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthState();
}

class _AuthState extends ConsumerState<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final token = TextEditingController();
  final form = GlobalKey<FormState>();
  _AuthStep step = _AuthStep.signIn;
  bool busy = false, visible = false;
  String? message;
  NoticeKind messageKind = NoticeKind.info;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    token.dispose();
    super.dispose();
  }

  void navigate(_AuthStep next) {
    if (busy) return;
    setState(() {
      step = next;
      message = null;
      visible = false;
      password.clear();
    });
    form.currentState?.reset();
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        setState(() {
          message = errorMessage(e);
          messageKind = NoticeKind.error;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void success(String value) {
    if (mounted) {
      setState(() {
        message = value;
        messageKind = NoticeKind.success;
      });
    }
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final api = ref.read(apiProvider);
    await run(() async {
      switch (step) {
        case _AuthStep.signIn:
          await api.login(email.text.trim(), password.text);
          if (mounted) context.go('/home');
          break;
        case _AuthStep.register:
          final result = await api.request(
            'POST',
            '/auth/register',
            data: {'email': email.text.trim(), 'password': password.text},
          );
          if (!mounted) return;
          setState(() {
            step = _AuthStep.verify;
            password.clear();
            token.text = result['development_token'] ?? '';
          });
          success(
            result['development_token'] != null
                ? 'Account created. A development verification code is filled in for this local setup.'
                : '${result['message']} ${result['delivery']}',
          );
          break;
        case _AuthStep.verify:
          final result = await api.request(
            'POST',
            '/auth/verification/confirm',
            data: {'token': token.text.trim()},
          );
          if (!mounted) return;
          setState(() {
            step = _AuthStep.signIn;
            token.clear();
          });
          success('${result['message']} You can now sign in.');
          break;
        case _AuthStep.requestReset:
          final result = await api.request(
            'POST',
            '/auth/password/request',
            data: {'email': email.text.trim()},
          );
          if (!mounted) return;
          setState(() => step = _AuthStep.reset);
          success(result['message'].toString());
          break;
        case _AuthStep.reset:
          final result = await api.request(
            'POST',
            '/auth/password/confirm',
            data: {'token': token.text.trim(), 'password': password.text},
          );
          if (!mounted) return;
          setState(() {
            step = _AuthStep.signIn;
            password.clear();
            token.clear();
          });
          success('${result['message']} Sign in with your new password.');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final needsEmail = step != _AuthStep.reset;
    final needsPassword = {
      _AuthStep.signIn,
      _AuthStep.register,
      _AuthStep.reset,
    }.contains(step);
    final needsCode = step == _AuthStep.verify || step == _AuthStep.reset;
    final title = switch (step) {
      _AuthStep.signIn => 'Welcome back',
      _AuthStep.register => 'Create your account',
      _AuthStep.verify => 'Verify your email',
      _AuthStep.requestReset => 'Reset your password',
      _AuthStep.reset => 'Choose a new password',
    };
    final description = switch (step) {
      _AuthStep.signIn => 'A moment to check. A more informed next step.',
      _AuthStep.register =>
        'Keep your scan results and privacy controls in one place.',
      _AuthStep.verify => 'Enter the verification code sent to your email.',
      _AuthStep.requestReset =>
        'We will send recovery instructions if your email has an account.',
      _AuthStep.reset =>
        'Use the recovery code from your email and a new password.',
    };
    final label = switch (step) {
      _AuthStep.signIn => 'Sign in',
      _AuthStep.register => 'Create account',
      _AuthStep.verify => 'Verify email',
      _AuthStep.requestReset => 'Send recovery instructions',
      _AuthStep.reset => 'Save new password',
    };
    return Scaffold(
      appBar: AppBar(title: const Brand()),
      body: PageBody(
        maxWidth: 480,
        children: [
          PageHeading(
            title: title,
            subtitle: description,
            eyebrow: 'YOUR SECURE SPACE',
          ),
          SurfaceCard(
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (needsEmail) ...[
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: step == _AuthStep.verify
                              ? 'Email (for resending)'
                              : 'Email',
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (value) =>
                            step == _AuthStep.verify &&
                                (value == null || value.trim().isEmpty)
                            ? null
                            : value != null &&
                                  RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value.trim())
                            ? null
                            : 'Enter a valid email address.',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (needsCode) ...[
                      TextFormField(
                        controller: token,
                        enabled: !busy,
                        autocorrect: false,
                        textInputAction: needsPassword
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: step == _AuthStep.verify
                              ? 'Verification code'
                              : 'Recovery code',
                          helperText: 'Paste the full code from your email.',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter the code from your email.'
                            : null,
                        onFieldSubmitted: (_) {
                          if (!needsPassword) submit();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (needsPassword) ...[
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: !visible,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          step == _AuthStep.signIn
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        decoration: InputDecoration(
                          labelText: step == _AuthStep.reset
                              ? 'New password'
                              : 'Password',
                          helperText: step == _AuthStep.signIn
                              ? null
                              : 'Use at least 12 characters.',
                          suffixIcon: IconButton(
                            tooltip: visible
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: busy
                                ? null
                                : () => setState(() => visible = !visible),
                            icon: Icon(
                              visible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : step != _AuthStep.signIn && value.length < 12
                            ? 'Use at least 12 characters.'
                            : null,
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (message != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Notice(message!, kind: messageKind),
                      ),
                      const SizedBox(height: 16),
                    ],
                    BusyButton(label: label, busy: busy, onPressed: submit),
                    if (step == _AuthStep.signIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => navigate(_AuthStep.requestReset),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (step == _AuthStep.signIn) ...[
            OutlinedButton(
              onPressed: busy ? null : () => navigate(_AuthStep.register),
              child: const Text('Create an account'),
            ),
            TextButton(
              onPressed: busy ? null : () => navigate(_AuthStep.verify),
              child: const Text('Verify your email'),
            ),
          ] else
            TextButton.icon(
              onPressed: busy ? null : () => navigate(_AuthStep.signIn),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to sign in'),
            ),
          if (step == _AuthStep.verify)
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () {
                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email.text.trim())) {
                        setState(() {
                          message =
                              'Enter your email above to request a new code.';
                          messageKind = NoticeKind.error;
                        });
                        return;
                      }
                      run(() async {
                        final result = await ref
                            .read(apiProvider)
                            .request(
                              'POST',
                              '/auth/verification/request',
                              data: {'email': email.text.trim()},
                            );
                        success(result['message'].toString());
                      });
                    },
              child: const Text('Resend verification code'),
            ),
          if (step == _AuthStep.requestReset)
            TextButton(
              onPressed: busy ? null : () => navigate(_AuthStep.reset),
              child: const Text('I already have a recovery code'),
            ),
          if (step == _AuthStep.reset)
            TextButton(
              onPressed: busy ? null : () => navigate(_AuthStep.requestReset),
              child: const Text('Request another recovery email'),
            ),
          TextButton(
            onPressed: () => context.push('/help'),
            child: const Text('Privacy, terms & help'),
          ),
        ],
      ),
    );
  }
}
