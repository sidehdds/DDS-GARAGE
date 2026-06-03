import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vehicule.dart';
import '../services/api_service.dart';
import '../widgets/pannes_widget.dart';
import '../theme.dart';

class DiagnosticScreen extends StatefulWidget {
  final Vehicule vehicule;
  const DiagnosticScreen({super.key, required this.vehicule});
  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final _kmCtrl       = TextEditingController();
  final _sympCtrl     = TextEditingController();
  final _picker       = ImagePicker();
  final _speech       = SpeechToText();

  Timer?   _kmTimer;
  String?  _pannes;
  bool     _pannesLoading = false;
  bool     _diagLoading   = false;
  String?  _diagResult;
  String?  _error;

  final List<Map<String, String>> _images = [];
  final Set<String> _selectedChips = {};
  bool   _listening    = false;
  String _transcript   = '';
  bool   _speechReady  = false;

  static const _chips = ['Claquement','Sifflement','Grognement','Cliquetis','Vibration','Frottement','Pétarade','Ronronnement'];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _sympCtrl.dispose();
    _kmTimer?.cancel();
    super.dispose();
  }

  void _onKmChanged(String v) {
    _kmTimer?.cancel();
    if (v.trim().isEmpty) return;
    _kmTimer = Timer(const Duration(milliseconds: 900), () => _loadPannes(v.trim()));
  }

  Future<void> _loadPannes(String km) async {
    setState(() { _pannesLoading = true; _pannes = null; });
    try {
      final result = await ApiService.pannesFrequentes(widget.vehicule, km);
      setState(() { _pannes = result; });
    } catch (_) {
    } finally {
      setState(() { _pannesLoading = false; });
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 75, maxWidth: 1024, maxHeight: 1024);
    for (final f in picked) {
      final bytes = await f.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() => _images.add({'type': 'image/jpeg', 'data': b64}));
    }
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_speechReady) return;
    setState(() { _listening = true; });
    await _speech.listen(
      localeId: 'fr_FR',
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  String get _bruitDescription {
    final chips = _selectedChips.join(', ');
    return [chips, _transcript].where((s) => s.isNotEmpty).join(' — ');
  }

  Future<void> _launchDiagnostic() async {
    final symp = _sympCtrl.text.trim();
    if (symp.isEmpty) { _showSnack('Décrivez les symptômes'); return; }
    FocusScope.of(context).unfocus();
    setState(() { _diagLoading = true; _diagResult = null; _error = null; });
    try {
      final result = await ApiService.diagnostic(
        vehicule: widget.vehicule,
        symptomes: symp,
        kilometrage: _kmCtrl.text.trim(),
        descriptionBruit: _bruitDescription,
        images: _images,
      );
      setState(() { _diagResult = result; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      setState(() { _diagLoading = false; });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: kSurface2,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnostic', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: kBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _vehiculeHeader(),
            const SizedBox(height: 20),
            _section(
              icon: Icons.speed,
              title: 'Kilométrage',
              child: TextField(
                controller: _kmCtrl,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: const InputDecoration(hintText: 'Ex : 87 000 km'),
                onChanged: _onKmChanged,
              ),
            ),
            if (_pannesLoading) ...[
              const SizedBox(height: 12),
              const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kAccent2)),
                SizedBox(width: 10),
                Text('Analyse du modèle…', style: TextStyle(fontSize: 12, color: kMuted)),
              ])),
            ],
            if (_pannes != null) ...[
              const SizedBox(height: 12),
              PannesWidget(pannes: _pannes!),
            ],
            const SizedBox(height: 16),
            _photosSection(),
            const SizedBox(height: 16),
            _bruitsSection(),
            const SizedBox(height: 16),
            _section(
              icon: Icons.description_outlined,
              title: 'Symptômes observés',
              child: TextField(
                controller: _sympCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: const InputDecoration(
                  hintText: 'Bruit au démarrage, voyant allumé, perte de puissance…',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _diagLoading ? null : _launchDiagnostic,
                icon: _diagLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(_diagLoading ? 'Analyse en cours…' : 'Lancer le diagnostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorBox(_error!),
            ],
            if (_diagResult != null) ...[
              const SizedBox(height: 24),
              _diagResultWidget(_diagResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vehiculeHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Row(children: [
        const Icon(Icons.directions_car, color: kAccent2, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.vehicule.displayLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          Text('${widget.vehicule.plaque} · ${widget.vehicule.energie}', style: const TextStyle(fontSize: 11, color: kMuted)),
        ])),
      ]),
    );
  }

  Widget _section({required IconData icon, required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: kMuted),
          const SizedBox(width: 5),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 1)),
        ]),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.photo_camera_outlined, size: 13, color: kMuted),
          const SizedBox(width: 5),
          const Text('PHOTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 1)),
          const Spacer(),
          TextButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: kAccent2),
            label: const Text('Ajouter', style: TextStyle(fontSize: 12, color: kAccent2)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ]),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_images[i]['data']!),
                      width: 80, height: 80, fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close, size: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity, height: 64,
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder, style: BorderStyle.solid),
              ),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, color: kMuted, size: 22),
                SizedBox(height: 4),
                Text('Moteur, pièce, voyant, fuite…', style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bruitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.mic_none, size: 13, color: kMuted),
          SizedBox(width: 5),
          Text('BRUITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 1)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _chips.map((chip) {
            final active = _selectedChips.contains(chip);
            return GestureDetector(
              onTap: () => setState(() => active ? _selectedChips.remove(chip) : _selectedChips.add(chip)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? kAccent2.withOpacity(0.12) : kSurface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? kAccent2 : kBorder),
                ),
                child: Text(chip, style: TextStyle(fontSize: 12, color: active ? kAccent2 : kMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _speechReady ? _toggleListen : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _listening ? kAccent.withOpacity(0.08) : kSurface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _listening ? kAccent : kBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_listening ? Icons.stop_circle_outlined : Icons.mic, size: 16, color: _listening ? kAccent : kMuted),
              const SizedBox(width: 8),
              Text(
                _listening ? '🔴  Écoute en cours…' : 'Décrire le bruit à voix haute',
                style: TextStyle(fontSize: 12, color: _listening ? kAccent : kMuted, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
        if (_transcript.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAccent2.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kAccent2.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DESCRIPTION CAPTÉE', style: TextStyle(fontSize: 9, color: kAccent2, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_transcript, style: const TextStyle(fontSize: 13, color: kText)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _transcript = ''),
                  child: const Text('✕ Effacer', style: TextStyle(fontSize: 11, color: kMuted)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.25))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: kSevRed, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text('❌ $msg', style: const TextStyle(color: kSevRed, fontSize: 13))),
    ]),
  );

  Widget _diagResultWidget(String text) {
    final searchIdx = text.toLowerCase().lastIndexOf('### recherches');
    final displayText = searchIdx != -1 ? text.substring(0, searchIdx).trim() : text;
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: kAccent2, borderRadius: BorderRadius.circular(6)),
                child: const Text('IA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
              ),
              const SizedBox(width: 10),
              const Text('Rapport de diagnostic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: displayText,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.7),
                strong: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                h3: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                h4: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 1.5),
                listBullet: const TextStyle(color: kAccent),
                horizontalRuleDecoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
