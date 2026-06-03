import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBg       = Color(0xFF080C10);
const kSurface  = Color(0xFF0E1318);
const kSurface2 = Color(0xFF131A22);
const kBorder   = Color(0xFF1E2830);
const kAccent   = Color(0xFFE63946);
const kAccent2  = Color(0xFF3B82F6);
const kText     = Color(0xFFE2E8F0);
const kMuted    = Color(0xFF64748B);
const kSubtle   = Color(0xFF1E2D3D);

const kSevRed    = Color(0xFFF87171);
const kSevOrange = Color(0xFFFB923C);
const kSevGreen  = Color(0xFF4ADE80);

ThemeData buildTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    primary: kAccent2,
    secondary: kAccent,
    surface: kSurface,
    error: kAccent,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: kText,
    displayColor: kText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBg.withOpacity(0.95),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.bebasNeue(
      fontSize: 22,
      color: Colors.white,
      letterSpacing: 4,
    ),
    iconTheme: const IconThemeData(color: kText),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kAccent2, width: 1.5),
    ),
    hintStyle: const TextStyle(color: kMuted, fontSize: 13),
    labelStyle: const TextStyle(color: kMuted, fontSize: 11),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAccent2,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
  dividerColor: kBorder,
);
