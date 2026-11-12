import 'package:flutter/material.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';

class VoteLoginScreen extends StatefulWidget {
  const VoteLoginScreen({super.key, required this.voteApi, required this.vrchatApi});

  final VoteApiHandler voteApi;
  final VrchatApiHandler vrchatApi;

  @override
  State<VoteLoginScreen> createState() => _VoteLoginScreenState();
}

class _VoteLoginScreenState extends State<VoteLoginScreen> {
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _votingPasswordController = TextEditingController();
  final _votingPasswordController2 = TextEditingController();

  bool _isLoading = true;
  String? _message;

  @override
  void dispose() {
    _tokenController.dispose();
    _votingPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentUser = widget.vrchatApi.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _message = "VRChat user failed to load";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    if (!widget.voteApi.isRegisteredUser){

      final hasUpper = RegExp(r'[A-Z]').hasMatch(_votingPasswordController.text);
      final hasLower = RegExp(r'[a-z]').hasMatch(_votingPasswordController.text);
      final hasDigit = RegExp(r'\d').hasMatch(_votingPasswordController.text);
      final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_votingPasswordController.text);

      if(_votingPasswordController2.text != _votingPasswordController.text){
        setState(() {
          _isLoading = false;
          _message = "Password's do not match;";
        });
        return;
      }

      if(!hasUpper || !hasLower || !hasDigit || !hasSpecial || _votingPasswordController.text.length < 10){
        setState(() {
          _isLoading = false;
          _message = "Your password needs to have 10 digits, a capital letter, a digit and a special character.";
        });
        return;
      }


      if (await widget.voteApi.createAccount(
        username: currentUser.displayName,
        userId: currentUser.id,
        eMail: _emailController.text,
        password: _votingPasswordController.text,
        registrationToken: _tokenController.text,
        iconLink: currentUser.iconUrl ?? "",
      )) {
        if(await widget.voteApi.login(_emailController.text, _votingPasswordController.text)){
          _message = "Login successful";
        }
        else{
          _message = "Account creation successful, but some error caused login to fail.";
        }
      }
      else{
        _message = "Account creation failed, check if your token is correct.";
      }
    }
    else{
      if(await widget.voteApi.login(_emailController.text, _votingPasswordController.text)){

      }
      else{
        _message = "Login failed, check your password and try again.";
      }
    }

    setState(() {
      _isLoading = false;
    });
  }


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final currentUser = widget.vrchatApi.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = "VRChat user failed to load";
      });
      return;
    }

    await widget.voteApi.userExists(userId: currentUser.id);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
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
                widget.voteApi.isRegisteredUser == true ? 
                  Text("A voting account is linked to your VRC account, please enter your VRCWR login credentials:")
                  :
                  Text("There is no voting account linked to your VRC account, create a VRCWR account with your activation key:"),
                const SizedBox(height: 16),
                if (widget.voteApi.isRegisteredUser == false) ...[
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'Registration Key'),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: 16),

                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _votingPasswordController,
                  decoration: const InputDecoration(labelText: 'Password (not your VRC password)'),
                  obscureText: true,
                  onSubmitted: (_) => _isLoading ? null : _submit(),
                ),
                if (widget.voteApi.isRegisteredUser == false) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _votingPasswordController2,
                    decoration: const InputDecoration(labelText: 'Repeat password'),
                    obscureText: true,
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
                      : Text(widget.voteApi.isRegisteredUser == true ? 'Login' : 'Register'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
                if (widget.voteApi.lastErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(widget.voteApi.lastErrorMessage!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      );
  }
}
