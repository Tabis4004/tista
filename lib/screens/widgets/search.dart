import 'package:flutter/material.dart';

import '../../providers/services.dart';
import '../../providers/theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: Services.instance.searchCtrl,
        decoration: const InputDecoration(
            hintText: "Rechercher ...",
            fillColor: bgColor,
            filled: true,
            contentPadding: EdgeInsets.only(right: 16),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            prefixIcon: Icon(Icons.search, size: 16)));
  }
}
