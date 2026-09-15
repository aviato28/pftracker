import 'package:flutter/material.dart';

import '../../data/airports/airport_repository.dart';
import '../../domain/airport.dart';

class AirportSearchField extends StatelessWidget {
  final String label;
  final AirportRepository repository;
  final ValueChanged<Airport> onSelected;

  const AirportSearchField({
    super.key,
    required this.label,
    required this.repository,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fieldWidth = MediaQuery.sizeOf(context).width - 32;
    return RawAutocomplete<Airport>(
      displayStringForOption: (a) => '${a.displayCode} — ${a.name}',
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.trim().length < 2) {
          return const Iterable<Airport>.empty();
        }
        return repository.search(textEditingValue.text);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Airport name, city, or IATA/ICAO code',
            border: const OutlineInputBorder(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: fieldWidth,
              height: list.length > 5 ? 280 : list.length * 56.0,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final option = list[index];
                  return ListTile(
                    dense: true,
                    title: Text('${option.displayCode} — ${option.name}'),
                    subtitle: Text('${option.city}, ${option.country}'),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
