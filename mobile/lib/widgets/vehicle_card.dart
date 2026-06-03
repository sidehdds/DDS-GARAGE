import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vehicule.dart';
import '../theme.dart';

class VehicleCardWrapper extends StatelessWidget {
  final Vehicule vehicule;
  const VehicleCardWrapper({super.key, required this.vehicule});

  @override
  Widget build(BuildContext context) {
    final v = vehicule;
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.displayLabel,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, children: [
                        _plaqueChip(v.plaque),
                        _energieChip(v.energie),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _stat(v.puissanceCv, 'ch'),
                  const SizedBox(width: 16),
                  _stat(v.dateMec, 'MEC'),
                ]),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          _gridWidget(context, v),
        ],
      ),
    );
  }

  Widget _plaqueChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF0F2040),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF1E3A6E)),
    ),
    child: Text(t, style: GoogleFonts.bebasNeue(fontSize: 13, color: const Color(0xFF93C5FD), letterSpacing: 3)),
  );

  Widget _energieChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: kSubtle, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorder)),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );

  Widget _stat(String v, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(v, style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 9, color: kMuted, letterSpacing: 1)),
    ],
  );

  Widget _gridWidget(BuildContext ctx, Vehicule v) {
    final items = [
      ('Boîte', v.boite),
      ('Carrosserie', v.carrosserie),
      ('Couleur', v.couleur),
      ('Places', v.nbPlaces),
      ('Portes', v.nbPortes),
      ('CO₂', v.co2 != '—' ? '${v.co2} g/km' : '—'),
    ];
    final colW = (MediaQuery.of(ctx).size.width - 72) / 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Wrap(
        children: items.map((e) => SizedBox(
          width: colW,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1, style: const TextStyle(fontSize: 9, color: kMuted, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(e.$2, style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w600)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
