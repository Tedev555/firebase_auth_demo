import 'dart:convert';

import 'package:auth_client/OTPVerification.dart';
import 'package:auth_client/network_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    _phoneNumberController.text = '+8562058888059';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This callback will be called after the widget is built
      // You can safely set the state here
      if (_auth.currentUser != null) {
        _auth.currentUser!.getIdToken().then((value) {
          /**
         * Call set claims API here
         */
          http
              .post(
                  Uri.parse(
                      NetworkConfig.BASE_URL + NetworkConfig.SET_CLAIMS_PATH),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'token': value,
                  }))
              .then((response) {
            print('Response status: ${response.statusCode}');
            print('Response body: ${response.body}');

            // Get token from firebase
            _auth.idTokenChanges().listen((User? user) {
              if (user != null) {
                user.getIdToken().then((value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          HomeScreen(token: value),
                    ),
                  );
                });
              } else {
                print('User is currently signed out!');
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }).catchError((error) => print('Error: $error'
                  ''));
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
              ),
            ),
            SizedBox(height: 16.0),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }

  void _login() {
    String phoneNumber = _phoneNumberController.text.trim();

    // Perform login validation here (e.g., making API calls, checking credentials)

    // Simulate an asynchronous operation using Future.delayed
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      // Once login validation is successful, navigate to the next screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => OTPVerificationPage(
            phoneNumber: phoneNumber,
          ),
        ),
      );
    });
  }
}

class HomeScreen extends StatelessWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}
