import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tista/providers/extension.dart';

class HeaderPage extends StatefulWidget {
  final String title;
  final bool hasSearch;
  const HeaderPage(this.title, {super.key, this.hasSearch = false});
  @override
  State<HeaderPage> createState() => _HeaderPageState();
}

class _HeaderPageState extends State<HeaderPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (cxt, constraints) {
      return Row(children: [
        Expanded(
            child: Text.rich(TextSpan(children: [
          TextSpan(
              text: "${widget.title}\n",
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Colors.black,
                  letterSpacing: 1.5)),
          TextSpan(
              text: DateTime.now().millisecondsSinceEpoch.formatTime(),
              style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 13.5,
                  color: Colors.black45,
                  letterSpacing: 1))
        ]))),
        Visibility(
            visible: widget.hasSearch,
            child: BootstrapVisibility(
              sizes: 'col-lg col-xl col-md',
              child: Padding(
                  padding: const EdgeInsets.only(left: 2.0, right: 8),
                  child: SizedBox(
                      width: 150,
                      child: CupertinoTextField(
                          padding: const EdgeInsets.only(
                              left: 12, right: 6, top: 8, bottom: 8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(8)),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          suffixMode: OverlayVisibilityMode.notEditing,
                          suffix: const Padding(
                              padding: EdgeInsets.only(right: 2.0),
                              child: Icon(CupertinoIcons.search,
                                  size: 17, color: Colors.black26)),
                          placeholder: 'Recherche'))),
            )),
        /*  GestureDetector(
          onTap: () {
            showAlert(context, const ProfilPage(),
                contentPadding: const EdgeInsets.all(0),
                titlePadding: const EdgeInsets.all(0));
          },
          child: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.person_outline_outlined, color: Colors.white)),
        ) */
      ]);
    });
  }
}
