import 'package:flutter/widgets.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

/// Central icon aliases for consistent usage.
class AppIcons {
  AppIcons._();

  static Widget volleyball({double fontSize = 24, Color? color, FontWeight? fontWeight}) =>
    SFIcon(
      SFIcons.sf_sportscourt,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

  static Widget team({double fontSize = 24, Color? color, FontWeight? fontWeight}) =>
    SFIcon(
      SFIcons.sf_person_3,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

  static Widget league({double fontSize = 24, Color? color, FontWeight? fontWeight}) =>
    SFIcon(
      SFIcons.sf_rosette,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

  static Widget match({double fontSize = 24, Color? color, FontWeight? fontWeight}) =>
    SFIcon(
      SFIcons.sf_calendar,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

  static Widget profile({double fontSize = 24, Color? color, FontWeight? fontWeight}) =>
    SFIcon(
      SFIcons.sf_person_crop_circle,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
}
