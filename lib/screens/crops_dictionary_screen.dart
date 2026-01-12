import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../services/crop_data_service.dart';
import '../widgets/crop_card.dart';
import 'crop_details_screen.dart';

class CropsDictionaryScreen extends StatefulWidget {
  final bool selectMode;
  final List<Crop>? initialSelection;
  final VoidCallback? onBack;

  const CropsDictionaryScreen({
    super.key,
    this.selectMode = false,
    this.initialSelection,
    this.onBack,
  });

  @override
  State<CropsDictionaryScreen> createState() => _CropsDictionaryScreenState();
}

class _CropsDictionaryScreenState extends State<CropsDictionaryScreen> {
  final CropDataService _cropService = CropDataService();
  final TextEditingController _searchController = TextEditingController();
  List<Crop> _filteredCrops = [];
  List<Crop> _selectedCrops = [];
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _cropService.initializeCrops();
    _selectedCrops = widget.initialSelection ?? [];
    _filteredCrops = _cropService.crops;
    _searchController.addListener(_filterCrops);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCrops() {
    setState(() {
      final String query = _searchController.text.trim();
      if (query.isNotEmpty) {
        // When typing a query, ignore category filter so relevant matches show
        _filteredCrops = _cropService.searchCrops(query);
        return;
      }
      if (_selectedCategory.isNotEmpty) {
        _filteredCrops = _cropService.filterByCategory(_selectedCategory);
      } else {
        _filteredCrops = _cropService.crops;
      }
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category ?? '';
    });
    _filterCrops();
  }

  void _toggleCropSelection(Crop crop) {
    setState(() {
      if (_selectedCrops.contains(crop)) {
        _selectedCrops.remove(crop);
      } else {
        _selectedCrops.add(crop);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedCrops);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _cropService.crops.map((c) => c.category).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crops Dictionary'),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: widget.selectMode
            ? [
                if (_selectedCrops.isNotEmpty)
                  TextButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check),
                    label: Text('Select (${_selectedCrops.length})'),
                  ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search crops...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory.isEmpty,
                        onSelected: (_) => _onCategorySelected(null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (_) => _onCategorySelected(category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredCrops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No crops found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _filteredCrops[index];
                      return widget.selectMode
                          ? CheckboxListTile(
                              title: Text(crop.name),
                              subtitle: Text(crop.scientificName),
                              value: _selectedCrops.contains(crop),
                              onChanged: (_) => _toggleCropSelection(crop),
                              secondary: Icon(
                                Icons.eco,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : CropCard(
                              crop: crop,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CropDetailsScreen(
                                      crop: crop,
                                    ),
                                  ),
                                );
                              },
                            );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
