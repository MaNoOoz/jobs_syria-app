import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const spaceV20 = SizedBox(height: 20);
const spaceV10 = SizedBox(height: 10);
const spaceH20 = SizedBox(width: 20);
const spaceH10 = SizedBox(width: 10);


// const String font = "NotoSansArabic-Regular";
const String APP_FONT_FAMILY = "IBMPlexSansArabic";
// Material color palette
const Color APPBAR_COLOR = Color(0xFF3e1413); // Blue 600
const Color PRIMARY_COLOR = Color(0xFF42A5F5); // Blue 400
const Color SECONDARY_COLOR = Color(0xFF90CAF9); // Blue 200
const Color ACCENT_COLOR = Color(0xFF00E5FF); // Cyan A400
const Color DANGER_COLOR = Color(0xFFE53935); // Red 600
const Color SUCCESS_COLOR = Color(0xFF43A047); // Green 600
const Color WARNING_COLOR = Color(0xFFFFA000); // Amber 700
const Color TEXT_PRIMARY = Color(0xFF212121); // Dark text
const Color TEXT_SECONDARY = Color(0xFF757575); // Secondary text
const Color WHITE = Colors.white;
const Color BACKGROUND_GRADIENT_TOP = Color(0xFFe3f2fd);
const Color BACKGROUND_GRADIENT_BOTTOM = Color(0xFFbbdefb);

const String BASE_GOOGLE_APP_SCRIPT ="https://script.google.com/macros/s/";
const String APP_LOGO ="assets/icon/icon.png";
const String APP_SCRIPT_API_KEY = "AKfycbywrH8kWfYLFjl88bVwXcDGtz9Ox2h0R6_t2LfnQuIaCJgZVcevZtUqL6yq_rQaZqbu";
const String SHEET_NAME_Client_Config ="Client_Config";
const String SHEET_NAME_menu ="menu";
const String SHEET_NAME_category ="category";

// Titles / Headings
final TextStyle mainStyleTB = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 28.sp,
  fontWeight: FontWeight.bold,
  color: WHITE,
);

final TextStyle mainStyleT1 = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 24.sp,
  fontWeight: FontWeight.w600,
  color: TEXT_PRIMARY,
);

final TextStyle mainStyleT2 = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 22.sp,
  fontWeight: FontWeight.w600,
  color: PRIMARY_COLOR,
);

final TextStyle mainStyleT3 = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 20.sp,
  fontWeight: FontWeight.w500,
  color: SECONDARY_COLOR,
);

final TextStyle mainStyleT4 = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 18.sp,
  fontWeight: FontWeight.w500,
  color: PRIMARY_COLOR,
);

// Body / Labels
final TextStyle mainStyleLW = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 13.sp,
  color: WHITE,
);

final TextStyle mainStyleMW = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 18.sp,
  fontWeight: FontWeight.w500,
  color: WHITE,
);

final TextStyle mainStyleLB = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 13.sp,
  color: TEXT_PRIMARY,
);

final TextStyle mainStyleBG = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 12.sp,
  color: TEXT_SECONDARY,
);

final TextStyle mainStyleBB = TextStyle(
  fontFamily: APP_FONT_FAMILY,
  fontSize: 14.sp,
  fontWeight: FontWeight.w600,
  color: WHITE,
);

