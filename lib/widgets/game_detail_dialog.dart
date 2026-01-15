import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/deal.dart';
import '../models/store.dart';
import '../models/steam_game_detail.dart';
import '../services/steam_service.dart';
import '../services/cheapshark_service.dart';
import '../services/currency_service.dart';
import '../services/location_service.dart';

class GameDetailDialog extends StatefulWidget {
  final Deal deal;
  final Store? store;
  final List<Store> allStores;

  const GameDetailDialog({
    super.key,
    required this.deal,
    this.store,
    required this.allStores,
  });

  @override
  State<GameDetailDialog> createState() => _GameDetailDialogState();
}

class _GameDetailDialogState extends State<GameDetailDialog> with SingleTickerProviderStateMixin {
  late Future<SteamGameDetail?> _detailFuture;
  late TabController _tabController;
  Future<List<Deal>>? _comparisonFuture;
  String? _userRegion;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetails();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<SteamGameDetail?> _loadDetails() async {
    String appId = widget.deal.steamAppID;
    // Search for AppID if missing
    if (appId.isEmpty || appId == '0') {
      final searchId = await SteamService().getAppId(widget.deal.title);
      if (searchId == null) return null;
      appId = searchId;
    }
    
    // Get user region
    try {
      _userRegion = await LocationService().getRegion();
    } catch (e) {
      print('Error getting region: $e');
    }
    
    return SteamService().getGameDetails(appId, countryCode: _userRegion);
  }
  
  Future<List<Deal>> _loadComparisons() async {
    // Get deals from CheapShark
    final gameData = await CheapSharkService().getGameById(widget.deal.gameID);
    if (gameData != null && gameData['deals'] != null) {
      final List<dynamic> dealsJson = gameData['deals'];
      // Map to Deal objects
      return dealsJson.map((d) {
          return Deal(
            internalName: '',
            title: widget.deal.title, // Assume same title
            metacriticLink: '',
            dealID: d['dealID'] ?? '',
            storeID: d['storeID']?.toString() ?? '',
            gameID: widget.deal.gameID,
            salePrice: d['price']?.toString() ?? '0',
            normalPrice: d['retailPrice']?.toString() ?? '0',
            isOnSale: '1', // Assumed likely on sale if listed, or check savings
            savings: d['savings']?.toString() ?? '0',
            metacriticScore: '',
            steamRatingText: '',
            steamRatingPercent: '',
            steamRatingCount: '',
            steamAppID: widget.deal.steamAppID,
            releaseDate: '',
            lastChange: '',
            dealRating: '',
            thumb: widget.deal.thumb,
          );
      }).toList();
    }
    return [];
  }

  String _stripHtml(String htmlString) {
    // Strip HTML tags
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header image
            FutureBuilder<SteamGameDetail?>(
              future: _detailFuture,
              builder: (context, snapshot) {
                final String? imageUrl = snapshot.data?.headerImage;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackHeader(),
                  );
                }
                // Fallback image
                if (widget.deal.thumb.isNotEmpty) {
                  return Image.network(
                    widget.deal.thumb,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackHeader(),
                  );
                }
                return _buildFallbackHeader();
              },
            ),


            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 0,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Compare Prices'),
                  Tab(text: 'Game Info'),
                  
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                   _buildCompareTab(),
                   _buildGameInfoTab()
                ],
              ),
            ),
            

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.deal.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
                  FutureBuilder<SteamGameDetail?>(
                    future: _detailFuture,
                    builder: (context, snapshot) {

                      
                      return FutureBuilder<Map<String, String?>>(
                        future: _resolveMainPrice(snapshot.data),
                        builder: (context, priceSnapshot) {
                           if (!priceSnapshot.hasData) {
                             return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                           }
                           
                           final displayPrice = priceSnapshot.data!['sale']!;
                           final normalPrice = priceSnapshot.data!['normal'];
                           
                           return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                displayPrice,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6C37),
                                ),
                              ),
                              if (normalPrice != null)
                                Text(
                                  normalPrice,
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          );
                        }
                      );
                    },
                  ),
            ],
          ),
          const SizedBox(height: 16),


          FutureBuilder<SteamGameDetail?>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Text('Could not load detailed information from Steam.');
              }

              final detail = snapshot.data!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.priceOverview != null) ...[
                    const SizedBox(height: 16),
                  ],


                  if (detail.tags.isNotEmpty || detail.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (detail.tags.isNotEmpty ? detail.tags : detail.genres).map((g) => Chip(
                        label: Text(g),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],


                  Text(
                    'About the Game',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stripHtml(detail.shortDescription),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),


                  _buildInfoRow('Developer', detail.developers.join(', ')),
                  _buildInfoRow('Publisher', detail.publishers.join(', ')),
                  _buildInfoRow('Release Date', detail.releaseDate),
                  const SizedBox(height: 16),


                  if (detail.pcRequirements != null) ...[
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text('System Requirements'),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          if (detail.pcRequirements!['minimum'] != null)
                             _buildRequirementSection('Minimum', detail.pcRequirements!['minimum']!),
                          if (detail.pcRequirements!['recommended'] != null && 
                              detail.pcRequirements!['recommended']!.isNotEmpty)
                             _buildRequirementSection('Recommended', detail.pcRequirements!['recommended']!),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, String?>> _resolveMainPrice(SteamGameDetail? detail) async {
      // Steam regional price
      if (widget.deal.storeID == '1' && detail?.priceOverview != null) {
        final priceOverview = detail!.priceOverview!;
        return {
          'sale': priceOverview.finalFormatted,
          'normal': priceOverview.discountPercent > 0 ? priceOverview.initialFormatted : null
        };
      }
      
      // Convert USD
      final sale = await CurrencyService().formatPrice(widget.deal.salePriceValue, _userRegion);
      String? normal;
      if (widget.deal.normalPriceValue > widget.deal.salePriceValue) {
        normal = await CurrencyService().formatPrice(widget.deal.normalPriceValue, _userRegion);
      }
      return {'sale': sale, 'normal': normal};
  }

  Widget _buildCompareTab() {
    return FutureBuilder<List<Deal>>(
      future: _comparisonFuture ??= _loadComparisons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final deals = snapshot.data;
        if (deals == null || deals.isEmpty) {
          return const Center(child: Text('No other prices found.'));
        }
        
        // Sort by price
        deals.sort((a,b) => a.salePriceValue.compareTo(b.salePriceValue));

        return FutureBuilder<SteamGameDetail?>(
          future: _detailFuture, // Listen to detail future as well to update Steam price
          builder: (context, detailSnapshot) {
            final steamDetail = detailSnapshot.data;
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deals.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final deal = deals[index];
                final store = widget.allStores.firstWhere(
                    (s) => s.storeID == deal.storeID,
                    orElse: () => Store(
                      storeID: deal.storeID,
                      storeName: 'Store ${deal.storeID}',
                      isActive: 1,
                      images: StoreImages(banner: '', logo: '', icon: ''),
                    )
                );


                return FutureBuilder<Map<String, String?>>(
                  future: _resolveDealPrice(deal, steamDetail),
                  builder: (context, priceSnapshot) {
                     String displayPrice = '';
                     String? normalPrice;
                     if (priceSnapshot.hasData) {
                       displayPrice = priceSnapshot.data!['sale']!;
                       normalPrice = priceSnapshot.data!['normal'];
                     } else {

                        displayPrice = '\$${deal.salePrice}';
                     }

                    return ListTile(
                      leading: store.images.icon.isNotEmpty 
                        ? Image.network(store.images.fullIcon, width: 32, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.store))
                        : const Icon(Icons.store),
                      title: Text(store.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: SizedBox(
                        width: 140, // Fixed width for alignment
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                        Text(displayPrice, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6C37), fontSize: 16)),
                                        if (normalPrice != null)
                                            Text(normalPrice, style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey[600], fontSize: 12)),
                                    ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () => _launchDealUrl(deal.dealID),
                                    tooltip: 'Go to Store',
                                )
                            ],
                        ),
                      ),
                    );
                  }
                );
              },
            );
          }
        );
      },
    );
  }

  Future<Map<String, String?>> _resolveDealPrice(Deal deal, SteamGameDetail? steamDetail) async {

    if (deal.storeID == '1' && steamDetail?.priceOverview != null) {
       final priceOverview = steamDetail!.priceOverview!;
       return {
         'sale': priceOverview.finalFormatted,
         'normal': priceOverview.discountPercent > 0 ? priceOverview.initialFormatted : null
       };
    }


    final sale = await CurrencyService().formatPrice(deal.salePriceValue, _userRegion);
    String? normal;
    if (deal.normalPriceValue > deal.salePriceValue) {
      normal = await CurrencyService().formatPrice(deal.normalPriceValue, _userRegion);
    }
    return {'sale': sale, 'normal': normal};
  }
  
  Future<void> _launchDealUrl(String dealID) async {
      final url = Uri.parse('https://www.cheapshark.com/redirect?dealID=$dealID');
       try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open store link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  Future<void> _launchStoreUrl() async {
    final url = Uri.parse('https://www.cheapshark.com/redirect?dealID=${widget.deal.dealID}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open store link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  Widget _buildFallbackHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[800],
      child: const Icon(Icons.videogame_asset, size: 64, color: Colors.white54),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRequirementSection(String title, String htmlContent) {
    final reqs = _parseReqs(htmlContent);
    if (reqs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: reqs.map((entry) {
              final key = entry.key;
              final value = entry.value;
              
              if (key.isEmpty) {
                return TableRow(
                  children: [
                    const SizedBox(), 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(value, style: const TextStyle(fontStyle: FontStyle.italic)),
                    )
                  ]
                ); 
              }

              return TableRow(
                children: [
                   Padding(
                     padding: const EdgeInsets.only(right: 12.0, bottom: 4.0),
                     child: Text(
                       '$key:', 
                       style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                       textAlign: TextAlign.end,
                       ),
                   ),
                   Padding(
                     padding: const EdgeInsets.only(bottom: 4.0),
                     child: Text(value),
                   ),
                ],
              );
            }).toList(),
          ),
          const Divider(),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _parseReqs(String html) {
    String clean = html
        .replaceAll('<ul class="bb_ul">', '')
        .replaceAll('<ul>', '')
        .replaceAll('</ul>', '')
        .replaceAll('<li>', '\n')
        .replaceAll('</li>', '')
        .replaceAll('<br>', '\n');

    final List<MapEntry<String, String>> result = [];
    final lines = clean.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;


      final RegExp keyValRegex = RegExp(r'<strong>(.*?)</strong>(.*)');
      final match = keyValRegex.firstMatch(line);

      if (match != null) {
        String key = _stripHtml(match.group(1) ?? '').trim();
        String value = _stripHtml(match.group(2) ?? '').trim();
        if (key.endsWith(':')) key = key.substring(0, key.length - 1);
        result.add(MapEntry(key, value));
      } else {
        result.add(MapEntry('', _stripHtml(line)));
      }
    }
    return result;
  }
}
