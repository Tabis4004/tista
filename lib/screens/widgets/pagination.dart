import 'package:flutter/material.dart';

class PaginationLine extends StatelessWidget {
  final int page, size, total;
  final Function(int) onTap;
  const PaginationLine(
      {super.key,
      required this.page,
      required this.size,
      required this.total,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    int pages = (total / size).ceil();
    if (pages == 1) return const SizedBox();
    return Center(
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(pages, (i) => i + 1).map((int e) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: InkWell(
                          onTap: () {
                            onTap(e);
                          },
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.shade400),
                              child: Text('$e',
                                  style: TextStyle(
                                      fontWeight:
                                          page == e ? FontWeight.w900 : null,
                                      color: page == e
                                          ? Colors.black
                                          : Colors.black54)))));
                }).toList())));
  }
}
