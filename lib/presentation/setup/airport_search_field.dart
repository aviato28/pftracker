import 'package:flutter/material.dart';

import '../../data/airports/airport_repository.dart';
import '../../domain/airport.dart';
import 'airport_search_page.dart';

/// A field that looks like a text input but just opens the full-screen
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
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final selected = await Navigator.of(context).push<Airport>(
          MaterialPageRoute(
            builder: (_) => AirportSearchPage(title: label, repository: repository),
          ),
        );
        if (selected != null) onSelected(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value != null ? '${value!.displayCode} — ${value!.name}' : 'Tap to choose',
          style: value == null
              ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
              : theme.textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
