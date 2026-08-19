import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  final bool appBar;
  const StatsPage({super.key, this.appBar = true});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Text("Stats"),
    );
  }
}
