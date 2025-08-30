import 'package:flutter/material.dart';

class CategoryChipSelector extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChipSelector({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryChipSelector> createState() => _CategoryChipSelectorState();
}

class _CategoryChipSelectorState extends State<CategoryChipSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            final bool isSelected = widget.selectedCategory == category;
            return ChoiceChip(
              label: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              selected: isSelected,
              onSelected: (_) =>
                  widget.onCategorySelected(isSelected ? null : category),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
