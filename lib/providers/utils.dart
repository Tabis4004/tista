import 'package:auto_size_text/auto_size_text.dart';
import 'package:tista/models/role.dart';
import 'package:tista/providers/extension.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import '../screens/widgets/responsive_builder.dart';
import 'services.dart';
import 'theme.dart';

Map<String, int> stats = {};

titleCase(String str) {
  if (str.isEmpty) return '';
  return str
      .toLowerCase()
      .split(' ')
      .map((x) => x[0].toUpperCase() + x.substring(1))
      .join(' ');
}

String getUserName(Map user) {
  return '${user['firstName'] ?? ""} ${user['lastName'] ?? ""}';
}

Widget buildConnectionError(void Function() onPressed,
    {Color? titleColor,
    Color? btnColor,
    String? title,
    String? reload,
    String? details}) {
  return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
    if (title == null || title.isNotEmpty)
      Text(title ?? "...\nInternet n'est pas disponible",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: titleColor, fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    if (details == null || details.isNotEmpty)
      Text(details ?? "L'application n'a plus accès à l'internet.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: titleColor ?? Colors.black54)),
    const SizedBox(height: 10),
    OutlinedButton(
        onPressed: onPressed,
        child: Text(reload ?? 'Relancer',
            style: TextStyle(fontSize: 14, color: titleColor)))
  ]));
}

void showToast(BuildContext context, msg, {int seconds = 5}) {
  TextStyle textStyle = const TextStyle(fontSize: 13.0, color: Colors.white);
  showToastWidget(Builder(builder: (BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: const Color(0x99000000)),
        padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 10.0),
        child: msg is String
            ? AutoSizeText(msg,
                textAlign: TextAlign.center,
                style: textStyle,
                maxFontSize: 17,
                minFontSize: 9,
                maxLines: 1)
            : msg);
  }),
      context: context,
      animation: StyledToastAnimation.slideFromBottom,
      reverseAnimation: StyledToastAnimation.fade,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInOut,
      dismissOtherToast: true,
      duration: Duration(seconds: seconds),
      endOffset: const Offset(0, -2.5),
      animDuration: const Duration(milliseconds: 1500));
}

Widget buildLabel(String msg,
    {EdgeInsets? padding, bool mandatory = false, Color? textColor}) {
  List<TextSpan> children = [TextSpan(text: msg)];
  if (mandatory) {
    children.add(const TextSpan(
        text: ' *', style: TextStyle(color: Colors.redAccent, fontSize: 12)));
  }
  return Padding(
      padding: padding ?? const EdgeInsets.only(left: 3.0, top: 20, bottom: 4),
      child: SelectableText.rich(TextSpan(children: children),
          style: TextStyle(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w600)));
}

showLoading(context, [String? msg]) {
  FocusScope.of(context).requestFocus(FocusNode());
  return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 20.0),
            content: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(msg ?? "Veuillez patienter",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.0),
                      textAlign: TextAlign.center))
            ]));
      });
}

Future<T?> navigateToBoard<T>(BuildContext context,
    {bool canBack = false,
    required String routeName,
    required Widget page,
    Map<String, String> params = const <String, String>{},
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    dynamic extra}) {
  FocusScope.of(context).requestFocus(FocusNode());
  if (!Responsive.isMobile(context)) {
    double padding = MediaQuery.of(context).size.width * .15;
    if (Responsive.isTablet(context)) {
      padding = MediaQuery.of(context).size.width * .1;
    }
    return showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (cxt) {
          return Dialog(
              insetPadding:
                  EdgeInsets.symmetric(horizontal: padding, vertical: 35.0),
              child: page);
        });
  }
  return context.pushNamed(routeName,
      pathParameters: params, queryParameters: queryParams, extra: extra);
}

Widget buildField(String? label,
    {TextEditingController? controller,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    AutovalidateMode? autovalidateMode,
    String? Function(String?)? validator,
    FloatingLabelBehavior? floatingLabelBehavior,
    bool? filled,
    Color? fillColor,
    double? radius,
    FocusNode? focusNode,
    int? maxLines = 1,
    int? minLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
    String? hint,
    Widget? icon,
    Widget? suffixIcon,
    Widget? prefixIcon,
    Widget? prefix,
    int? maxLength,
    String? counterText,
    bool? obscureText,
    String? help,
    Widget? suffix,
    bool? enabled,
    EdgeInsets? contentPadding,
    bool autofocus = false,
    bool noBorder = false,
    TextStyle? helperStyle,
    TextStyle? hintStyle,
    double? borderSide,
    Color? borderColor,
    String? errorText,
    TextAlign? textAlign,
    Function()? onEditingComplete,
    Function(String)? onFieldSubmitted}) {
  return Padding(
      padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 5.0),
      child: TextFormField(
          autovalidateMode: autovalidateMode,
          validator: validator,
          enabled: enabled ?? true,
          maxLines: (minLines ?? 1) > 1 ? null : (maxLines),
          minLines: minLines ?? 1,
          maxLength: maxLength,
          autofocus: autofocus,
          controller: controller,
          focusNode: focusNode,
          textAlign: textAlign ?? TextAlign.start,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onFieldSubmitted,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText ?? false,
          onChanged: onChanged,
          //onSubmitted: onSubmitted,
          decoration: InputDecoration(
              fillColor: fillColor,
              filled: filled,
              floatingLabelBehavior:
                  floatingLabelBehavior ?? FloatingLabelBehavior.always,
              contentPadding: contentPadding,
              hintText: hint,
              hintMaxLines: 5,
              hintStyle: hintStyle ??
                  const TextStyle(fontSize: 14.5, color: Colors.black26),
              icon: icon,
              enabledBorder: noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius ?? 4),
                      borderSide: BorderSide(
                          color: fillColor != null
                              ? borderColor ?? appPrimaryColor
                              : Colors.black,
                          width: borderSide ?? 1)),
              disabledBorder: noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius ?? 4),
                      borderSide: BorderSide(
                          color: fillColor != null
                              ? borderColor ?? appPrimaryColor
                              : Colors.black,
                          width: borderSide ?? 1)),
              focusedBorder: noBorder
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius ?? 6),
                      borderSide: BorderSide(
                          color: fillColor != null
                              ? borderColor ?? appPrimaryColor
                              : Colors.black,
                          width: borderSide ?? 1)),
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              prefix: prefix,
              suffix: suffix,
              labelText: label != null ? label + (required ? ' *' : '') : null,
              counterText: counterText,
              isDense: true,
              helperText: help,
              helperMaxLines: 5,
              helperStyle: helperStyle,
              errorText: errorText)));
}

Widget buildSelect(BuildContext context,
    {hint,
    List? selectedMenus,
    value,
    String? fieldValue,
    String? fieldLibelle,
    EdgeInsets? padding,
    Function? item,
    bool mandatory = false,
    int? maxLines,
    bool? isExpanded,
    TextStyle? style,
    Widget? icon,
    Color? borderColor,
    Color? dropdownColor,
    Color? bgColor,
    void Function(dynamic)? onChanged}) {
  if (selectedMenus == null) {
    return const SizedBox();
  }
  return DropdownButtonHideUnderline(
      child: Container(
          padding: padding ??
              const EdgeInsets.only(
                  left: 3.0, right: 3.0, top: 1.0, bottom: 1.0),
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                  color: borderColor ??
                      Colors.black)), //Theme.of(context).primaryColor
          child: DropdownButton(
              dropdownColor: dropdownColor,
              style: style ??
                  const TextStyle(fontSize: 14.0, color: Colors.black87),
              isExpanded: isExpanded ?? true,
              iconEnabledColor: style?.color,
              icon: icon,
              hint: hint is Widget
                  ? hint
                  : Text(hint ?? '',
                      maxLines: 1,
                      style: style ?? const TextStyle(fontSize: 12.0)),
              items: selectedMenus.map((value) {
                return DropdownMenuItem(
                    value: fieldValue != null ? value[fieldValue] : value,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: item != null
                            ? item(value)
                            : AutoSizeText(
                                '${fieldLibelle != null ? value[fieldLibelle] : value}',
                                maxLines: maxLines ?? 2,
                                overflow: TextOverflow.ellipsis)));
              }).toList(),
              value: value,
              onChanged: onChanged)));
}

Future<String?> showAlert(context, msg,
    {ShapeBorder? shape,
    bool barrier = true,
    bool cancel = false,
    String? cancelMsg,
    String? okMsg,
    EdgeInsets? contentPadding,
    EdgeInsets? titlePadding,
    Color? bgColor,
    Color? okTextColor,
    List<Widget> btns = const []}) {
  FocusScope.of(context).requestFocus(FocusNode());
  return showDialog<String>(
      context: context,
      barrierDismissible: barrier,
      builder: (cxt) {
        return AlertDialog(
            backgroundColor: bgColor,
            shape: shape ??
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            contentPadding: contentPadding ??
                const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
            titlePadding: titlePadding,
            content:
                msg is String ? SingleChildScrollView(child: Text(msg)) : msg,
            actions: <Widget>[
              ...btns,
              Visibility(
                  visible: cancel,
                  child: TextButton(
                      child: Text(cancelMsg ?? 'Annuler',
                          style: const TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(cxt).pop();
                      })),
              TextButton(
                  child:
                      Text(okMsg ?? 'Ok', style: TextStyle(color: okTextColor)),
                  onPressed: () {
                    Navigator.of(cxt).pop('Ok');
                  })
            ]);
      });
}

bool hasDroits({required List<String> droits, String? company}) {
  if (Services.user?.isAdmin == true) return true;

  // Un compte sans rôle n'a aucun droit. Sans ce test, la requête partait avec
  // `uuidEqualTo('')` — une chaîne vide qui, si un rôle mal formé traînait en
  // cache avec un uuid vide, aurait accordé ses droits à n'importe qui.
  final role = Services.user?.role;
  if (role == null || role.trim().isEmpty) return false;

  QueryBuilder<RoleModel, RoleModel, QAfterFilterCondition> anyOf;
  anyOf = Services.isar.roleModels
      .filter()
      .uuidEqualTo(role)
      .and()
      .anyOf(droits, (q, d) => q.droitsElementEqualTo(d));
  //print("${Services.user?.uuid} $droits ${anyOf.countSync()}");
  return anyOf.countSync() > 0;
}

Widget buildDate(BuildContext context,
    {required String hint,
    required DateTime? date,
    required void Function(DateTime val) onPressed}) {
  return GestureDetector(
      onTap: () {
        getDate(context, date).then((value) {
          if (value != null) {
            onPressed(value);
          }
        });
      },
      child: Chip(
          avatar: const Icon(Icons.calendar_today, size: 12),
          label: Text(
              date == null
                  ? hint
                  : date.millisecondsSinceEpoch
                      .formatTime(withDay: false, withHour: false),
              style: const TextStyle(fontSize: 13))));
}

Future<DateTime?> getDate(context, DateTime? date,
    {DateTime? start,
    DateTime? end,
    DatePickerEntryMode entryMode = DatePickerEntryMode.calendar}) {
  return showDatePicker(
          context: context,
          initialEntryMode: entryMode,
          initialDate:
              date ?? DateTime.now().subtract(const Duration(minutes: 1)),
          firstDate: start ?? DateTime(2024, 1),
          lastDate: end ?? DateTime.now().add(const Duration(days: 1)))
      .then((value) {
    return value;
  });
}
