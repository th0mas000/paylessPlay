import 'package:flutter/material.dart';
import '../models/store.dart';

class FilterSheet extends StatefulWidget {
  final List<Store> stores;
  final List<String> availableTags;
  final Set<String> initialStoreIds;
  final double? initialUpperPrice;
  final int? initialMetacritic;
  final bool initialAAA;
  final bool initialOnSale;
  final Set<String> initialSelectedTags;
  final String currencySymbol;
  final double exchangeRate;
  final Function({
    Set<String>? storeIds,
    double? upperPrice,
    int? metacritic,
    bool? aaa,
    bool? onSale,
    Set<String>? selectedTags,
  }) onApply;

  const FilterSheet({
    super.key,
    required this.stores,
    required this.onApply,
    this.availableTags = const [],
    this.initialStoreIds = const {},
    this.initialUpperPrice,
    this.initialMetacritic,
    this.initialAAA = false,
    this.initialOnSale = true,
    this.initialSelectedTags = const {},
    this.currencySymbol = '\$',
    this.exchangeRate = 1.0,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _selectedStoreIds;
  late double _upperPrice;
  late double _metacritic;
  late bool _aaa;
  late bool _onSale;
  late Set<String> _selectedTags;
  final TextEditingController _tagSearchController = TextEditingController();
  String _tagSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStoreIds = Set.from(widget.initialStoreIds);
    _upperPrice = widget.initialUpperPrice ?? 50.0;
    _metacritic = widget.initialMetacritic?.toDouble() ?? 0.0;
    _aaa = widget.initialAAA;
    _onSale = widget.initialOnSale;
    _selectedTags = Set.from(widget.initialSelectedTags);
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedStoreIds.clear();
      _upperPrice = 50.0;
      _metacritic = 0.0;
      _aaa = false;
      _onSale = true;
      _selectedTags.clear();
    });
  }

  @override
  Widget build(BuildContext context) {

    final activeStores = widget.stores.where((s) => s.active).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [

              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [

                    Row(
                      children: [
                        Text(
                          'Stores',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        if (_selectedStoreIds.isNotEmpty)
                          Text(
                            '(${_selectedStoreIds.length} selected)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All Stores'),
                          selected: _selectedStoreIds.isEmpty,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedStoreIds.clear();
                              }
                            });
                          },
                        ),
                        ...activeStores.map((store) {
                          return FilterChip(
                            label: Text(store.storeName),
                            selected: _selectedStoreIds.contains(store.storeID),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStoreIds.add(store.storeID);
                                } else {
                                  _selectedStoreIds.remove(store.storeID);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),


                    Text(
                      'Max Price: ${widget.currencySymbol}${(_upperPrice * widget.exchangeRate).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _upperPrice,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: '${widget.currencySymbol}${(_upperPrice * widget.exchangeRate).toStringAsFixed(2)}',
                      onChanged: (value) {
                        setState(() {
                          _upperPrice = value;
                        });
                      },
                    ),
                    

                    if (widget.availableTags.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Tags',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          if (_selectedTags.isNotEmpty)
                            Text(
                              '(${_selectedTags.length} selected)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _tagSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search tags...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _tagSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _tagSearchController.clear();
                                      _tagSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _tagSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final filteredTags = widget.availableTags
                              .where((tag) => tag.toLowerCase().contains(_tagSearchQuery))
                              .toList();
                          
                          if (filteredTags.isEmpty && _tagSearchQuery.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No tags found',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filteredTags.map((tag) {
                              return FilterChip(
                                label: Text(tag),
                                selected: _selectedTags.contains(tag),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                 
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        storeIds: _selectedStoreIds.isEmpty ? null : _selectedStoreIds,
                        upperPrice: _upperPrice == 50.0 ? null : _upperPrice,
                        metacritic: _metacritic == 0 ? null : _metacritic.toInt(),
                        aaa: _aaa,
                        onSale: _onSale,
                        selectedTags: _selectedTags.isEmpty ? null : _selectedTags,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
