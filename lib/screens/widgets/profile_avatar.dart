import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tista/providers/theme.dart';
import '../../providers/routing_config.dart';
import '../../providers/services.dart';
import 'responsive_builder.dart';

class ProfileCard extends StatefulWidget {
  final bool showDetails;
  final double? size;
  const ProfileCard({super.key, this.size, this.showDetails = true});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          context.goNamed(AppRouteConstants.profil);
        },
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(width: 2, color: appPrimaryColor),
                      shape: BoxShape.circle),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage("assets/person.png"),
                      ))),
              if (!Responsive.isMobile(context) && widget.showDetails)
                Container(
                    padding: const EdgeInsets.only(left: 8.0),
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: Services.user?.prenoms ??
                                        Services.user?.name ??
                                        Services.user?.mail ??
                                        '***'),
                              ]),
                              maxLines: 1,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          AutoSizeText(Services.user?.mail ?? '***',
                              maxLines: 1,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w300))
                        ]))
            ])));
  }
}
