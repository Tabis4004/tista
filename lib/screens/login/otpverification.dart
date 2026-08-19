import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../providers/services.dart';
import '../../providers/theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final Map model;
  const OtpVerificationScreen({super.key, required this.model});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  late final CustomTimerController _controller;
  final TextEditingController pinController = TextEditingController();
  final Color focusedBorderColor =
      appPrimaryColor; //const Color.fromRGBO(23, 171, 144, 1);
  final fillColor = Colors.white; //const Color.fromRGBO(243, 246, 249, 0);
  final borderColor = Colors.white; //const Color.fromRGBO(23, 171, 144, 0.4);
  late final PinTheme defaultPinTheme;

  @override
  void initState() {
    super.initState();

    defaultPinTheme = PinTheme(
        width: 56,
        height: 56,
        textStyle: GoogleFonts.poppins(
            fontSize: 22, color: const Color.fromRGBO(30, 60, 87, 1)),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: borderColor)));
    _controller = CustomTimerController(
        vsync: this, begin: const Duration(minutes: 2), end: const Duration());
    _controller.start();
  }

  @override
  void dispose() {
    pinController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              appPrimaryColor, //(200, 255, 221, 1),
              Color.fromRGBO(232, 228, 228, 1)
            ])),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                elevation: 0,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                title: const Text(appName)),
            body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                child: Center(
                    child: Column(children: [
                  OtpHeader(
                    phone:
                        "${widget.model['indicatif']} ${widget.model['phone']}",
                  ),
                  Pinput(
                      length: 6,
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: defaultPinTheme,
                      cursor: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                                margin: const EdgeInsets.only(bottom: 9),
                                width: 22,
                                height: 1,
                                color: focusedBorderColor)
                          ]),
                      focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: focusedBorderColor))),
                      submittedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                              color: fillColor,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: focusedBorderColor))),
                      errorPinTheme: defaultPinTheme.copyBorderWith(
                          border: Border.all(color: Colors.redAccent)),
                      pinAnimationType: PinAnimationType.scale,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      //senderPhoneNumber:"${widget.model['indicatif']} ${widget.model['phone']}",
                      //androidSmsAutofillMethod:AndroidSmsAutofillMethod.smsUserConsentApi,
                      controller: pinController,
                      onChanged: (String pin) {
                        if (pin == widget.model['code']) {
                          context.pop(pin);
                        }
                      },
                      onSubmitted: (String pin) {
                        if (pin == widget.model['code']) {
                          context.pop(pin);
                        }
                      },
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      validator: (pin) {
                        if (pin == widget.model['code']) return null;
                        return "Code de vérification erroné";
                      }),
                  const SizedBox(height: 44),
                  CustomTimer(
                      controller: _controller,
                      builder: (CustomTimerState state,
                          CustomTimerRemainingTime time) {
                        if (state == CustomTimerState.finished) {
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Vous n'avez pas reçu le code ?",
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors
                                            .white //const Color.fromRGBO(62, 116, 165, 1),
                                        )),
                                TextButton(
                                    onPressed: () async {
                                      try {
                                        await Services.instance.sendSMS(
                                            phone: widget.model['phone'],
                                            message: widget.model['msg']);
                                        _controller.reset();
                                        _controller.start();
                                      } catch (_) {}
                                    },
                                    child: Text("Renvoyer",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            decoration:
                                                TextDecoration.underline,
                                            color: Colors
                                                .white //const Color.fromRGBO(62, 116, 165, 1),
                                            )))
                              ]);
                        }
                        return Padding(
                            padding: const EdgeInsets.only(top: 6, right: 20.0),
                            child: Text("${time.minutes}:${time.seconds}",
                                style: const TextStyle(
                                    color: appSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.0)));
                      })
                ])))));
  }
}

class OtpHeader extends StatelessWidget {
  final String phone;
  const OtpHeader({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Vérification",
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white //const Color.fromRGBO(30, 60, 87, 1),
                )),
        const SizedBox(height: 24),
        Text(
          "Saisissez le code envoyé au numéro",
          style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white //const Color.fromRGBO(133, 153, 170, 1),
              ),
        ),
        const SizedBox(height: 16),
        Text(
          phone,
          style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white //const Color.fromRGBO(30, 60, 87, 1),
              ),
        ),
        const SizedBox(height: 64)
      ],
    );
  }
}
