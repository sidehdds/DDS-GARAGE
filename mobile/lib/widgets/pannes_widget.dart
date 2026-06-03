import 'package:flutter/material.dart';
import '../theme.dart';

class PannesWidget extends StatelessWidget {
  final String pannes;
  const PannesWidget({super.key, required this.pannes});

  @override
  Widget build(BuildContext context) {
    final items = _parse(pannes);
    return Container(
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 15, color: kSevRed),
              const SizedBox(width: 6),
              const Text(
                'POINTS DE VIGILANCE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: kSevRed),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0x26E63946)),
          ...items.map((item) => _PanneRow(item: item)),
        ],
      ),
    );
  }

  List<_PanneItem> _parse(String text) {
    final items = <_PanneItem>[];
    final lines = text.split('\n');
    _PanneItem? current;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      Color? color;
      String? icon;
      String cleaned = trimmed;

      if (trimmed.startsWith('🔴')) { color = kSevRed;    icon = '🔴'; cleaned = trimmed.substring(2).trim(); }
      else if (trimmed.startsWith('🟠')) { color = kSevOrange; icon = '🟠'; cleaned = trimmed.substring(2).trim(); }
      else if (trimmed.startsWith('🟢')) { color = kSevGreen;  icon = '🟢'; cleaned = trimmed.substring(2).trim(); }

      if (icon != null) {
        if (current != null) items.add(current);
        final boldMatch = RegExp(r'^\*\*(.+?)\*\*(.*)$').firstMatch(cleaned);
        current = _PanneItem(
          icon: icon,
          color: color!,
          title: boldMatch != null ? boldMatch.group(1)! : cleaned,
          desc:  boldMatch != null ? boldMatch.group(2)!.trim() : '',
        );
      } else if (current != null && trimmed.isNotEmpty) {
        current = _PanneItem(
          icon: current.icon, color: current.color, title: current.title,
          desc: '${current.desc} $trimmed'.trim(),
        );
      }
    }
    if (current != null) items.add(current);
    return items;
  }
}

class _PanneItem {
  final String icon, title, desc;
  final Color color;
  const _PanneItem({required this.icon, required this.title, required this.desc, required this.color});
}

class _PanneRow extends StatelessWidget {
  final _PanneItem item;
  const _PanneRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: item.color)),
              if (item.desc.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.desc, style: const TextStyle(fontSize: 11, color: kMuted, height: 1.4)),
              ],
            ],
          )),
        ],
      ),
    );
  }
}
