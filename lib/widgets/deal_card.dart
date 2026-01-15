import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../models/deal.dart';
import '../models/store.dart';
import '../models/steam_game_detail.dart';
import '../services/steam_service.dart';
import '../theme/app_theme.dart';
import 'game_detail_dialog.dart';

class PriceDisplay {
  final String sale;
  final String? normal;
  PriceDisplay({required this.sale, this.normal});
}

class DealCard extends StatefulWidget {
  final Deal deal;
  final Store? store;
  final List<Store> allStores;
  final String? userRegion;

  const DealCard({
    super.key,
    required this.deal,
    this.store,
    required this.allStores,
    this.userRegion,
  });

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> with SingleTickerProviderStateMixin {
  Future<PriceDisplay>? _priceDisplayFuture;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _priceDisplayFuture = _loadPrices();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deal.dealID != oldWidget.deal.dealID || widget.userRegion != oldWidget.userRegion) {
        _priceDisplayFuture = _loadPrices();
    }
  }

  Future<PriceDisplay> _loadPrices() async {
    // Try Steam regional price
    if (widget.userRegion != null && 
        widget.deal.steamAppID.isNotEmpty && 
        widget.deal.steamAppID != '0' &&
        widget.deal.storeID == '1') {
      try {
        final detail = await SteamService().getGameDetails(
          widget.deal.steamAppID, 
          countryCode: widget.userRegion
        );
        if (detail?.priceOverview != null) {
          return PriceDisplay(
            sale: detail!.priceOverview!.finalFormatted,
            normal: detail.priceOverview!.discountPercent > 0 
                ? detail.priceOverview!.initialFormatted 
                : null,
          );
        }
      } catch (e) {

      }
    }

    // Convert USD to user region
    final sale = await CurrencyService().formatPrice(widget.deal.salePriceValue, widget.userRegion);
    String? normal;
    if (widget.deal.normalPriceValue > widget.deal.salePriceValue) {
      normal = await CurrencyService().formatPrice(widget.deal.normalPriceValue, widget.userRegion);
    }
    
    return PriceDisplay(sale: sale, normal: normal);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(_isHovered ? 0.3 : 0.15),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () async {

                    print('========== GAME INFO ==========');
                    print('Title: ${widget.deal.title}');
                    

                    String appId = widget.deal.steamAppID;
                    if (appId.isEmpty || appId == '0') {
                      final searchId = await SteamService().getAppId(widget.deal.title);
                      if (searchId != null) {
                        appId = searchId;
                      }
                    }
                    
                    if (appId.isNotEmpty && appId != '0') {
                      try {
                        final detail = await SteamService().getGameDetails(appId);
                        if (detail != null) {
                          if (detail.tags.isNotEmpty) {
                            print('Tags: ${detail.tags.join(", ")}');
                          } else if (detail.genres.isNotEmpty) {
                            print('Genres: ${detail.genres.join(", ")}');
                          } else {
                            print('No tags or genres available');
                          }
                        } else {
                          print('Could not fetch game details');
                        }
                      } catch (e) {
                        print('Error fetching tags: $e');
                      }
                    } else {
                      print('No Steam App ID available');
                    }
                    
                    print('===============================');
                    

                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => GameDetailDialog(
                          deal: widget.deal,
                          store: widget.store,
                          allStores: widget.allStores,
                        ),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.cardColor,
                                AppTheme.surfaceLightColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                // Image
                                Container(
                                  width: double.infinity,
                                  child: FutureBuilder<String>(
                                    future: widget.deal.betterThumb,
                                    initialData: widget.deal.thumb,
                                    builder: (context, snapshot) {
                                      final url = snapshot.data ?? widget.deal.thumb;
                                      return _buildImage(url);
                                    },
                                  ),
                                ),
                                // Depth gradient
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                // Discount
                                if (widget.deal.savingsPercentage > 0)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppTheme.successColor,
                                            Color(0xFF00D98C),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.successColor.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '-${widget.deal.savingsPercentage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Info section
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Game title
                                SizedBox(
                                  height: 44, // Height for 2 lines of text
                                  child: Text(
                                    widget.deal.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Prices
                                FutureBuilder<PriceDisplay>(
                                  future: _priceDisplayFuture,
                                  builder: (context, snapshot) {
                                    String displayPrice;
                                    String? normalPrice;

                                    if (snapshot.hasData) {
                                      displayPrice = snapshot.data!.sale;
                                      normalPrice = snapshot.data!.normal;
                                    } else {
                                      displayPrice = '\$${widget.deal.salePriceValue.toStringAsFixed(2)}';
                                      normalPrice = widget.deal.normalPriceValue > widget.deal.salePriceValue 
                                        ? '\$${widget.deal.normalPriceValue.toStringAsFixed(2)}' 
                                        : null;
                                    }

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
 
                                        if (normalPrice != null) ...[
                                          Text(
                                            normalPrice,
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration: TextDecoration.lineThrough,
                                              decorationColor: Colors.grey[500],
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        // Sale price
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.secondaryColor,
                                                AppTheme.secondaryLight,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            displayPrice,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: AppTheme.surfaceColor,
        child: const Center(
          child: Icon(Icons.videogame_asset, size: 56, color: Colors.white24),
        ),
      );
    }
    
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.surfaceColor,
          child: const Center(
            child: Icon(Icons.videogame_asset, size: 56, color: Colors.white24),
          ),
        );
      },
    );
  }
}