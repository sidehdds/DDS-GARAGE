import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vehicule.dart';
import '../services/api_service.dart';
import '../widgets/vehicle_card.dart';
import '../theme.dart';
import 'diagnostic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _plateCtrl = TextEditingController();
  Vehicule? _vehicule;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _vehicule = null; });
    try {
      final json = await ApiService.rechercherPlaque(plate);
      setState(() { _vehicule = Vehicule.fromJson(json['data'], json['plaque']); });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.bebasNeue(fontSize: 22, letterSpacing: 4, color: Colors.white),
            children: const [
              TextSpan(text: 'DDS'),
              TextSpan(text: 'GARAGE', style: TextStyle(color: kAccent)),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Identifiez votre véhicule',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Entrez une plaque d\'immatriculation française',
                style: const TextStyle(fontSize: 13, color: kMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('🇫🇷', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white, letterSpacing: 6),
                      decoration: const InputDecoration(
                        hintText: 'AA-123-BB',
                        hintStyle: TextStyle(color: Color(0xFF2D3748), letterSpacing: 4, fontSize: 22),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        filled: false,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: const BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Rechercher', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 32),
              const Center(child: Column(children: [
                CircularProgressIndicator(color: kAccent2),
                SizedBox(height: 12),
                Text('Identification en cours…', style: TextStyle(color: kMuted, fontSize: 12)),
              ])),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAccent.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: kSevRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('❌ $_error', style: const TextStyle(color: kSevRed, fontSize: 13))),
                ]),
              ),
            ],

            if (_vehicule != null) ...[
              const SizedBox(height: 24),
              VehicleCardWrapper(vehicule: _vehicule!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DiagnosticScreen(vehicule: _vehicule!)),
                  ),
                  icon: const Icon(Icons.medical_services_outlined, size: 18),
                  label: const Text('Lancer le diagnostic IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) =>
      val.copyWith(text: val.text.toUpperCase());
}
