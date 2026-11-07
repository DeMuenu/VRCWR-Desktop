import 'package:flutter/material.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcworldvoterdesktop/backend/voteApiHandler.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';

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

  bool _isLoading = true;
  String? _message;

  @override
  void dispose() {
    _tokenController.dispose();
    _votingPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    if (!widget.voteApi.isRegisteredUser){
      if (widget.vrchatApi.currentUser == null){
        setState(() {
          _isLoading = true;
          _message = "VRChat user failed to load";
        });
      }
      if(await widget.voteApi.createAccount(widget.vrchatApi.currentUser!.id, _votingPasswordController.text, _emailController.text, _tokenController.text)){
        if(await widget.voteApi.login(widget.vrchatApi.currentUser!.id, _votingPasswordController.text)){
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
      if(await widget.voteApi.login(widget.vrchatApi.currentUser!.id, _votingPasswordController.text)){

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
    await widget.voteApi.doesAccountExists();
    setState(() {
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.voteApi.isRegisteredUser == true ? 
                  Text("A voting account is linked to your VRC account, please enter your voting password:")
                  :
                  Text("There is no voting account linked to your VRC account, register with your key.\nThe only unencrypted data saved on the voting server is your VRC userId and your VRC username."),
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
                  autofillHints: const [AutofillHints.password], //TODO check password strenght
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
