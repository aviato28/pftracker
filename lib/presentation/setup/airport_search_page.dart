import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/airports/airport_repository.dart';
import '../../domain/airport.dart';
import '../theme/app_theme.dart';

/// Full-screen airport search. A plain Navigator push + ListView is far
/// more robust than an inline overlay-based autocomplete (which is prone
/// to swallowing gestures and leaving the page feeling stuck) and it's a
/// pattern every user already knows from every other search-heavy app.
class AirportSearchPage extends StatefulWidget {
  final String title;
  final AirportRepository repository;

  const AirportSearchPage({super.key, required this.title, required this.repository});

  @override
  State<AirportSearchPage> createState() => _AirportSearchPageState();
}

class _AirportSearchPageState extends State<AirportSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Airport> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final trimmed = query.trim();
      if (trimmed.length < 2) {
        setState(() {
          _results = const [];
          _searched = false;
        });
        return;
      }
      final results = await widget.repository.search(trimmed);
      if (mounted) {
        setState(() {
          _results = results;
          _searched = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 17),
          decoration: const InputDecoration(
            hintText: 'City, airport, or IATA/ICAO code',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _searched && _results.isEmpty
          ? const Center(
              child: Text('No airports found', style: TextStyle(color: AppColors.textMuted)),
            )
          : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final airport = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentDim,
                    child: Text(
                      airport.displayCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  title: Text(airport.name),
                  subtitle: Text(
                    '${airport.city}, ${airport.country}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  onTap: () => Navigator.of(context).pop(airport),
                );
              },
            ),
    );
  }
}
