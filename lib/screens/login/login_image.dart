import 'package:flutter/material.dart';

class LoginImageScreen extends StatelessWidget {
  const LoginImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/station.jpg',
        height: double.infinity, fit: BoxFit.cover);
  }
}
