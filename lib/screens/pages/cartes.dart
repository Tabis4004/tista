import 'package:flutter/material.dart';

import '../widgets/header_page.dart';

class CartesPage extends StatefulWidget {
  const CartesPage({super.key});
  @override
  State<CartesPage> createState() => _CartesPageState();
}

class _CartesPageState extends State<CartesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Gestion des cartes")),
        body: const Text("Cartes"));
  }
}
