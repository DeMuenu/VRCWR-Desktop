import 'package:flutter/material.dart';
import 'package:VRCWR/backend/vrchatApiHandler.dart';

class VRCLoginScreen extends StatefulWidget {
  const VRCLoginScreen({super.key, required this.api});

  final VrchatApiHandler api;

  @override
  State<VRCLoginScreen> createState() => _VRCLoginScreenState();
}

class _VRCLoginScreenState extends State<VRCLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();

  bool _isLoading = false;
  bool _requiresTwoFactorAuth = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {

      if (_requiresTwoFactorAuth) {
        final verified = await widget.api.verify2FACode(
          _twoFactorController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _message = verified
                ? 'Login successful.'
                : 'The verification code was not accepted.';
          });
        }
      } else {
        final loggedIn = await widget.api.loginToVrchat(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _requiresTwoFactorAuth = widget.api.requires2FA;
            _message = _requiresTwoFactorAuth
                ? 'Enter your two-factor authentication code.'
                : loggedIn
                ? 'Login successful.'
                : 'Login failed. Please check your credentials.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Unable to log in: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Login to your VRChat account.", textAlign: TextAlign.center, style: TextStyle(fontSize: 40),),
                const SizedBox(height: 16),
                Text("Your login information never leaves your device, a cookie is saved locally to sign you in automatically when you open the app next time. If you decide to create a VRCWR account later on; Your VRC user-ID, username and profile picture will be linked it to prevent spam.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15),),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSubmitted: (_) => _isLoading ? null : _submit(),
                  autofillHints: const [AutofillHints.password],
                ),
                if (_requiresTwoFactorAuth) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _twoFactorController,
                    decoration: const InputDecoration(
                      labelText: 'Two-factor authentication code',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _isLoading ? null : _submit(),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
    );
  }
}
