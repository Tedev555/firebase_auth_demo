import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;

  OTPVerificationPage({required this.phoneNumber});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<FocusNode> _pinFocusNodes =
      List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _pinControllers =
      List.generate(6, (index) => TextEditingController());
  final int _pinLength = 6;

  FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _pinFocusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _sendOTP() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      timeout: Duration(seconds: 60),
    );
  }

  void _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      print('Phone number verified!');
      // Perform necessary actions after phone number verification (e.g., navigate to the next screen)
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter the OTP code sent to your phone',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPinFields(),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPinFields() {
    List<Widget> pinFields = [];

    for (int i = 0; i < _pinLength; i++) {
      pinFields.add(
        Container(
          width: 48.0,
          height: 48.0,
          margin: EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _pinControllers[i],
            focusNode: _pinFocusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (i < _pinLength - 1) {
                  _pinFocusNodes[i].unfocus();
                  _pinFocusNodes[i + 1].requestFocus();
                } else {
                  _pinFocusNodes[i].unfocus();
                }
              } else {
                if (i > 0) {
                  _pinFocusNodes[i].unfocus();
                  _pinFocusNodes[i - 1].requestFocus();
                }
              }
            },
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }

    return pinFields;
  }

  void _verifyOTP() async {
    String otpCode = '';

    for (var controller in _pinControllers) {
      otpCode += controller.text;
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: otpCode);
    _signInWithCredential(credential);
  }
}
