import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../data/dummy_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/car_wash.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import '../widgets/wash_detail_sheet.dart';
import '../widgets/wash_list_card.dart';
import '../widgets/wash_marker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapController = MapController();

  static const _defaultCenter = LatLng(25.2048, 55.2708);
  LatLng _origin = _defaultCenter;

  CarWash? _selectedWash;
  WashStatus? _statusFilter;
  bool _loadingLocation = false;

  List<CarWash> get _sortedWashes {
    final list = [...dummyCarWashes];
    list.sort((a, b) {
      final da = haversineKm(_origin.latitude, _origin.longitude, a.lat, a.lng);
      final db = haversineKm(_origin.latitude, _origin.longitude, b.lat, b.lng);
      return da.compareTo(db);
    });
    return list;
  }

  List<CarWash> get _filteredWashes {
    final sorted = _sortedWashes;
    if (_statusFilter == null) return sorted;
    return sorted.where((w) => w.status == _statusFilter).toList();
  }

  Future<void> _locateMe() async {
    setState(() => _loadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _origin = loc);
      _mapController.move(loc, 13);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onMarkerTap(CarWash wash) {
    setState(() => _selectedWash = wash);
    _mapController.move(LatLng(wash.lat - 0.005, wash.lng), 14);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.42,
        maxChildSize: 0.94,
        expand: false,
        builder: (ctx, sc) => WashDetailSheet(
          wash: wash,
          userLocation: _origin,
          scrollController: sc,
        ),
      ),
    ).then((_) => setState(() => _selectedWash = null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filteredWashes;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(l10n, filtered),
          // Gradient fade where map meets bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          _buildTopBar(context, l10n),
          _buildLocateFab(),
          _buildBottomSheet(context, l10n, filtered),
        ],
      ),
    );
  }

  Widget _buildMap(AppLocalizations l10n, List<CarWash> washes) {
    // Esri World Street Map renders English labels globally (including UAE).
    // CartoDB Voyager renders local-script (Arabic) labels in MENA.
    // OSM standard tiles always use local language, so they show Arabic in UAE.
    final tileUrl = l10n.isArabic
        ? 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'
        : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 11,
        onTap: (_, __) => setState(() => _selectedWash = null),
      ),
      children: [
        TileLayer(
          key: ValueKey(tileUrl),
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.emirateswash.app',
        ),
        MarkerLayer(
          markers: dummyCarWashes.map((wash) {
            return Marker(
              point: wash.latLng,
              width: 72,
              height: 52,
              alignment: Alignment.bottomCenter,
              child: WashMarker(
                wash: wash,
                isSelected: _selectedWash?.id == wash.id,
                onTap: () => _onMarkerTap(wash),
              ),
            );
          }).toList(),
        ),
        if (_origin != _defaultCenter)
          MarkerLayer(markers: [
            Marker(
              point: _origin,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.googleBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.googleBlue.withOpacity(0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ]),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_car_wash_rounded,
                    color: AppTheme.googleBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.t('app_title'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _LanguageToggle(isArabic: l10n.isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocateFab() {
    return Positioned(
      right: 14,
      bottom: 270,
      child: FloatingActionButton.small(
        heroTag: 'locate',
        onPressed: _loadingLocation ? null : _locateMe,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.googleBlue,
        elevation: 4,
        child: _loadingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<CarWash> washes,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.10,
      maxChildSize: 0.74,
      snap: true,
      snapSizes: const [0.10, 0.28, 0.74],
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 18,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _SheetHeader(
                  l10n: l10n,
                  totalCount: dummyCarWashes.length,
                  filteredCount: washes.length,
                  currentFilter: _statusFilter,
                  onFilterChanged: (f) =>
                      setState(() => _statusFilter = f),
                ),
              ),
              SliverAnimatedList(
                initialItemCount: washes.length,
                itemBuilder: (ctx, i, animation) {
                  if (i >= washes.length) return const SizedBox.shrink();
                  final wash = washes[i];
                  final dist = haversineKm(
                    _origin.latitude,
                    _origin.longitude,
                    wash.lat,
                    wash.lng,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: WashListCard(
                      wash: wash,
                      distanceKm: dist,
                      isSelected: _selectedWash?.id == wash.id,
                      onTap: () => _onMarkerTap(wash),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 8),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Bottom sheet header with filter chips ──────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final int totalCount;
  final int filteredCount;
  final WashStatus? currentFilter;
  final ValueChanged<WashStatus?> onFilterChanged;

  const _SheetHeader({
    required this.l10n,
    required this.totalCount,
    required this.filteredCount,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Text(
                l10n.t('nearby_washes'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Container(
                  key: ValueKey(filteredCount),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.googleBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$filteredCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(
                label: l10n.t('filter_all'),
                selected: currentFilter == null,
                color: AppTheme.googleBlue,
                onTap: () => onFilterChanged(null),
              ),
              _FilterChip(
                label: l10n.t('status_free'),
                selected: currentFilter == WashStatus.free,
                color: AppTheme.statusFree,
                onTap: () => onFilterChanged(
                  currentFilter == WashStatus.free ? null : WashStatus.free,
                ),
              ),
              _FilterChip(
                label: l10n.t('status_busy'),
                selected: currentFilter == WashStatus.busy,
                color: AppTheme.statusBusy,
                onTap: () => onFilterChanged(
                  currentFilter == WashStatus.busy ? null : WashStatus.busy,
                ),
              ),
              _FilterChip(
                label: l10n.t('status_full'),
                selected: currentFilter == WashStatus.full,
                color: AppTheme.statusFull,
                onTap: () => onFilterChanged(
                  currentFilter == WashStatus.full ? null : WashStatus.full,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppTheme.divider,
            width: selected ? 0 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Language toggle ─────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final bool isArabic;
  const _LanguageToggle({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          EmiratesWashApp.of(context)
              .setLocale(Locale(isArabic ? 'en' : 'ar')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.googleBlue.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.googleBlue.withOpacity(0.25)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            key: ValueKey(isArabic),
            isArabic ? 'EN' : 'عربي',
            style: const TextStyle(
              color: AppTheme.googleBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
