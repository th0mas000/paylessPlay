import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../models/store.dart';
import '../services/cheapshark_service.dart';
import '../services/currency_service.dart';
import '../widgets/deal_card.dart';
import '../widgets/filter_sheet.dart';
import '../services/location_service.dart';
import '../services/steam_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final CheapSharkService _apiService = CheapSharkService();
  List<Deal> _deals = [];
  List<Store> _stores = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  bool _isLoadMoreRunning = false;
  bool _hasNextPage = true;
  String? _userRegion;
  String _currencySymbol = '\$';
  double _exchangeRate = 1.0;
  

  Set<String> _selectedStoreIds = {'1'}; // Default to Steam
  String _sortBy = 'Deal Rating'; // Default to Deal Rating
  String _searchQuery = '';
  double? _upperPrice;
  int? _metacritic;
  bool _aaa = false;
  bool _onSale = true;
  Set<String> _selectedTags = {};
  List<String> _availableTags = [];
  Map<String, List<String>> _steamGameTags = {}; // Cache game tags

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_hasNextPage && 
        !_isLoading && 
        !_isLoadMoreRunning && 
        _scrollController.position.extentAfter < 300) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _hasNextPage = true;
      _deals = [];
    });

    try {

      if (_userRegion == null) {
        try {
          _userRegion = await LocationService().getRegion();
          if (_userRegion != null) {
              final currencyCode = CurrencyService().getCurrencyForRegion(_userRegion!);
              _currencySymbol = CurrencyService().getCurrencySymbol(currencyCode);
              _exchangeRate = await CurrencyService().getExchangeRate(currencyCode);
          }
        } catch (e) {
          print('Error detecting region: $e');
        }
      }


      if (_stores.isEmpty) {
        _stores = await _apiService.getStores();
      }
      
      final deals = await _apiService.getDeals(
        pageSize: 30,
        sortBy: _sortBy,
        storeID: _selectedStoreIds.isEmpty ? null : _selectedStoreIds.join(','),
        onSale: _onSale,
        pageNumber: 0,
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
        metacritic: _metacritic,
        AAA: _aaa ? 1 : null,
        upperPrice: _upperPrice,
      );

      final uniqueDeals = _getUniqueDeals(deals);


      await _fetchTagsForDeals(uniqueDeals.values.toList());

      if (mounted) {
        setState(() {
          _deals = uniqueDeals.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;

    setState(() {
      _isLoadMoreRunning = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final deals = await _apiService.getDeals(
        pageSize: 30,
        sortBy: _sortBy,
        storeID: _selectedStoreIds.isEmpty ? null : _selectedStoreIds.join(','),
        onSale: _onSale,
        pageNumber: nextPage,
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
        metacritic: _metacritic,
        AAA: _aaa ? 1 : null,
        upperPrice: _upperPrice,
      );

      if (deals.isEmpty) {
        if (mounted) {
          setState(() {
            _hasNextPage = false;
            _isLoadMoreRunning = false;
          });
        }
        return;
      }


      final newUniqueDealsMap = _getUniqueDeals(deals);
      final List<Deal> dealsToAdd = [];
      

      final existingGameIds = _deals.map((d) => d.gameID).toSet();

      for (final deal in newUniqueDealsMap.values) {
        if (!existingGameIds.contains(deal.gameID)) {
          dealsToAdd.add(deal);
        }
      }


      await _fetchTagsForDeals(dealsToAdd);

      if (mounted) {
        setState(() {
          _deals.addAll(dealsToAdd);
          _currentPage = nextPage;
          _isLoadMoreRunning = false;

          if (deals.length < 30) _hasNextPage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadMoreRunning = false;

        });
      }
    }
  }


  Map<String, Deal> _getUniqueDeals(List<Deal> deals) {
    final Map<String, Deal> bestDeals = {};

    for (final deal in deals) {
      final gameId = deal.gameID;
      
      if (!bestDeals.containsKey(gameId)) {
        bestDeals[gameId] = deal;
      } else {
        final existingDeal = bestDeals[gameId]!;
        if (deal.savingsPercentage > existingDeal.savingsPercentage ||
            (deal.savingsPercentage == existingDeal.savingsPercentage &&
             deal.salePriceValue < existingDeal.salePriceValue)) {
          bestDeals[gameId] = deal;
        }
      }
    }

    return bestDeals;
  }
  

  Future<void> _fetchTagsForDeals(List<Deal> deals) async {
    final steamService = SteamService();
    final Set<String> allTags = {};
    

    final dealsWithSteamId = deals.where((d) => d.steamAppID.isNotEmpty && d.steamAppID != '0').toList();
    

    final limitedDeals = dealsWithSteamId.take(30).toList();
    
    for (final deal in limitedDeals) {

      if (_steamGameTags.containsKey(deal.steamAppID)) {
        allTags.addAll(_steamGameTags[deal.steamAppID]!);
        continue;
      }
      
      try {
        final gameDetail = await steamService.getGameDetails(deal.steamAppID);
        if (gameDetail != null) {
          final gameTags = <String>[];
          

          if (gameDetail.tags.isNotEmpty) {
            gameTags.addAll(gameDetail.tags);
          }
          

          if (gameDetail.genres.isNotEmpty) {
            gameTags.addAll(gameDetail.genres);
          }
          
          if (gameTags.isNotEmpty) {
            _steamGameTags[deal.steamAppID] = gameTags;
            allTags.addAll(gameTags);
          }
        }
      } catch (e) {

        print('Error fetching tags for ${deal.steamAppID}: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _availableTags = allTags.toList()..sort();
      });
    }
  }
  

  List<Deal> _getFilteredDeals() {
    if (_selectedTags.isEmpty) {
      return _deals;
    }
    
    return _deals.where((deal) {

      if (deal.steamAppID.isEmpty || deal.steamAppID == '0') {
        return false;
      }
      

      final dealTags = _steamGameTags[deal.steamAppID];
      if (dealTags == null || dealTags.isEmpty) {
        return false;
      }
      

      return _selectedTags.every((tag) => dealTags.contains(tag));
    }).toList();
  }
  

  
  void _onSearchSubmitted(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
      _loadData();
    }
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        if (_searchQuery.isNotEmpty) {
           _searchQuery = '';
           _loadData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search games...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
              )
            : const Text(
                'PayLess Play',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [

          if (_stores.isNotEmpty && !_isSearching)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FilterSheet(
                    stores: _stores,
                    availableTags: _availableTags,
                    initialStoreIds: _selectedStoreIds,
                    initialUpperPrice: _upperPrice,
                    initialMetacritic: _metacritic,
                    initialAAA: _aaa,
                    initialOnSale: _onSale,
                    initialSelectedTags: _selectedTags,
                    currencySymbol: _currencySymbol,
                    exchangeRate: _exchangeRate,
                    onApply: ({
                      storeIds,
                      upperPrice,
                      metacritic,
                      aaa,
                      onSale,
                      selectedTags,
                    }) {
                      setState(() {
                         _selectedStoreIds = storeIds ?? {};
                         _upperPrice = upperPrice;
                         _metacritic = metacritic;
                         _aaa = aaa ?? false;
                         _onSale = onSale ?? true;
                         _selectedTags = selectedTags ?? {};
                      });
                      _loadData();
                    },
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
                if (_isSearching && _searchQuery.isNotEmpty) {

                     _onSearchSubmitted('');
                     _searchController.clear();
                } else {
                    _toggleSearch();
                }
            },
          ),

          if (!_isSearching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                  if (_sortBy != value) {
                      setState(() {
                          _sortBy = value;
                      });
                      _loadData();
                  }
              },
              itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Deal Rating', child: Text('Best Rating')),
                  const PopupMenuItem(value: 'Metacritic', child: Text('Metacritic')),
                  const PopupMenuItem(value: 'Savings', child: Text('Highest Savings')),
                  const PopupMenuItem(value: 'Price', child: Text('Lowest Price')),
                  const PopupMenuItem(value: 'Title', child: Text('Title')),
              ],
            ),
          if (!_isSearching)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
            ),
        ],
      ),
      body: Column(
        children: [

            

            Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading deals',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_deals.isEmpty) {
      return const Center(
        child: Text('No deals found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {

          int crossAxisCount;
          double childAspectRatio;
          
          if (constraints.maxWidth > 1400) {
            crossAxisCount = 5;
            childAspectRatio = 1.5;
          } else if (constraints.maxWidth > 1100) {
            crossAxisCount = 4;
            childAspectRatio = 1.4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
            childAspectRatio = 1.3;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.2;
          } else {
            crossAxisCount = 1;
            childAspectRatio = 1.5;
          }


          final displayDeals = _getFilteredDeals();

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 30,
              mainAxisSpacing: 30,
            ),

            itemCount: displayDeals.length + (_hasNextPage && _selectedTags.isEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayDeals.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final deal = displayDeals[index];

              final store = _stores.firstWhere(
                (s) => s.storeID == deal.storeID,
                orElse: () => Store(
                  storeID: '',
                  storeName: 'Unknown',
                  isActive: 0,
                  images: StoreImages(banner: '', logo: '', icon: ''),
                ),
              );
                return DealCard(
                  deal: deal,
                  store: store,
                  allStores: _stores,
                  userRegion: _userRegion,
                );
            },
          );
        },
      ),
    );
  }
}