import 'package:flutter/material.dart';

import '../../data/airports/airport_repository.dart';
import '../../domain/airport.dart';
import '../theme/app_theme.dart';
import 'airport_search_page.dart';

/// A row that looks like a filled-in field but just opens the full-screen
/// [AirportSearchPage] on tap — see that file for why.
class AirportSearchField extends StatelessWidget {
  final String label;
  final IconData icon;
  final AirportRepository repository;
  final Airport? value;
  final ValueChanged<Airport> onSelected;

  const AirportSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.repository,
    required this.onSelected,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await Navigator.of(context).push<Airport>(
          MaterialPageRoute(
            builder: (_) => AirportSearchPage(title: label, repository: repository),
          ),
        );
        if (selected != null) onSelected(selected);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? '${value!.displayCode} — ${value!.name}' : 'Tap to choose',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: value != null ? AppColors.textPrimary : AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
