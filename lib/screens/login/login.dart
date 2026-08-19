import 'package:flutter/material.dart';
import '../../providers/theme.dart';
import '../widgets/responsive_builder.dart';
import 'login_form.dart';
import 'login_image.dart';

class LoginScreen extends StatelessWidget {
  final AuthType type;
  const LoginScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    Widget tablet = Scaffold(
        backgroundColor: appPrimaryColor, //bgColor,
        body: Row(children: [
          const Expanded(flex: 6, child: LoginImageScreen()),
          Expanded(flex: 4, child: LoginForm(type: type))
        ]));
    return Responsive(
        desktopBuilder: (cxt, constraints) => tablet,
        tabletBuilder: (cxt, constraints) => tablet,
        mobileBuilder: (cxt, constraints) => Scaffold(
            backgroundColor: appPrimaryColor, //bgColor,
            body: LoginForm(type: type)));
  }
}

enum AuthType { login, signUp }
