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

enum SortBy { distance, waitTime, rating }

const _allServices = [
  'Exterior Wash',
  'Interior Clean',
  'Full Detail',
  'Polish',
  'Tyre Shine',
  'Engine Clean',
  'Ceramic Coating',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();

  static const _defaultCenter = LatLng(25.2048, 55.2708);
  LatLng _origin = _defaultCenter;

  CarWash? _selectedWash;
  WashStatus? _statusFilter;
  SortBy _sortBy = SortBy.distance;
  final Set<String> _serviceFilter = {};
  bool _loadingLocation = false;

  List<CarWash> get _sortedWashes {
    final list = [...dummyCarWashes];
    list.sort((a, b) => switch (_sortBy) {
      SortBy.distance =>
        haversineKm(_origin.latitude, _origin.longitude, a.lat, a.lng)
            .compareTo(haversineKm(_origin.latitude, _origin.longitude, b.lat, b.lng)),
      SortBy.waitTime => a.waitTimeMinutes.compareTo(b.waitTimeMinutes),
      SortBy.rating   => b.rating.compareTo(a.rating),
    });
    return list;
  }

  List<CarWash> get _filteredWashes => _sortedWashes.where((w) {
    if (_statusFilter != null && w.status != _statusFilter) return false;
    if (_serviceFilter.isNotEmpty && !_serviceFilter.every((s) => w.services.contains(s))) return false;
    return true;
  }).toList();

  int get _activeFilterCount =>
      (_statusFilter != null ? 1 : 0) + _serviceFilter.length;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
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
        initialChildSize: 0.72,
        minChildSize: 0.45,
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

  void _openSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SortFilterSheet(
        currentSort: _sortBy,
        currentServices: Set.from(_serviceFilter),
        onApply: (sort, services) => setState(() {
          _sortBy = sort;
          _serviceFilter..clear()..addAll(services);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filteredWashes;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(l10n, filtered),
          Positioned(
            left: 0, right: 0, bottom: 0, height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Colors.transparent],
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
    // Esri = English labels globally; CartoDB Voyager = Arabic/local labels in MENA
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
          markers: washes.map((wash) => Marker(
            point: wash.latLng,
            width: 72,
            height: 52,
            alignment: Alignment.bottomCenter,
            child: WashMarker(
              wash: wash,
              isSelected: _selectedWash?.id == wash.id,
              onTap: () => _onMarkerTap(wash),
            ),
          )).toList(),
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
      top: 0, left: 0, right: 0,
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
                const Icon(Icons.local_car_wash_rounded, color: AppTheme.googleBlue, size: 22),
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
      bottom: 320,
      child: FloatingActionButton.small(
        heroTag: 'locate',
        onPressed: _loadingLocation ? null : _locateMe,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.googleBlue,
        elevation: 4,
        child: _loadingLocation
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, AppLocalizations l10n, List<CarWash> washes) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.30,
      minChildSize: 0.08,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.08, 0.30, 0.74, 0.92],
      builder: (_, scrollController) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, -3)),
            ],
          ),
          child: Column(
            children: [
              // Handle lives OUTSIDE the ListView so drag is never swallowed by scroll.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) {
                  final sh = MediaQuery.of(context).size.height;
                  _sheetController.jumpTo(
                    (_sheetController.size - d.primaryDelta! / sh).clamp(0.10, 0.92),
                  );
                },
                onVerticalDragEnd: (_) {
                  const snaps = [0.10, 0.30, 0.74, 0.92];
                  final s = _sheetController.size;
                  final nearest = snaps.reduce(
                    (a, b) => (a - s).abs() < (b - s).abs() ? a : b,
                  );
                  _sheetController.animateTo(
                    nearest,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Container(
                      width: 44, height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Header + list together in the scroll view.
              // Only the handle above is fixed; everything else can scroll,
              // so the Column never overflows at minimum sheet size.
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  itemCount: washes.isEmpty ? 2 : washes.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return _SheetHeader(
                        l10n: l10n,
                        filteredCount: washes.length,
                        currentFilter: _statusFilter,
                        activeFilterCount: _activeFilterCount,
                        onFilterChanged: (f) => setState(() => _statusFilter = f),
                        onSortFilter: _openSortFilter,
                      );
                    }
                    if (washes.isEmpty) return _EmptyState(l10n: l10n);
                    final wash = washes[i - 1];
                    final dist = haversineKm(
                      _origin.latitude, _origin.longitude, wash.lat, wash.lng,
                    );
                    return WashListCard(
                      wash: wash,
                      distanceKm: dist,
                      isSelected: _selectedWash?.id == wash.id,
                      onTap: () => _onMarkerTap(wash),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: AppTheme.divider),
          const SizedBox(height: 12),
          Text(
            l10n.t('no_results'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('no_results_sub'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet header ──────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final int filteredCount;
  final WashStatus? currentFilter;
  final int activeFilterCount;
  final ValueChanged<WashStatus?> onFilterChanged;
  final VoidCallback onSortFilter;

  const _SheetHeader({
    required this.l10n,
    required this.filteredCount,
    required this.currentFilter,
    required this.activeFilterCount,
    required this.onFilterChanged,
    required this.onSortFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Text(
                l10n.t('nearby_washes'),
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey(filteredCount),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.googleBlue, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$filteredCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              // Sort & Filter button
              GestureDetector(
                onTap: onSortFilter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeFilterCount > 0 ? AppTheme.googleBlue : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 14,
                          color: activeFilterCount > 0 ? Colors.white : AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        l10n.t('sort_filter'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: activeFilterCount > 0 ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      if (activeFilterCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$activeFilterCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
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
                onTap: () => onFilterChanged(currentFilter == WashStatus.free ? null : WashStatus.free),
              ),
              _FilterChip(
                label: l10n.t('status_busy'),
                selected: currentFilter == WashStatus.busy,
                color: AppTheme.statusBusy,
                onTap: () => onFilterChanged(currentFilter == WashStatus.busy ? null : WashStatus.busy),
              ),
              _FilterChip(
                label: l10n.t('status_full'),
                selected: currentFilter == WashStatus.full,
                color: AppTheme.statusFull,
                onTap: () => onFilterChanged(currentFilter == WashStatus.full ? null : WashStatus.full),
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
          border: Border.all(color: selected ? color : AppTheme.divider, width: selected ? 0 : 1.5),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
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

// ── Sort & Filter sheet ──────────────────────────────────────────────────────

class _SortFilterSheet extends StatefulWidget {
  final SortBy currentSort;
  final Set<String> currentServices;
  final void Function(SortBy sort, Set<String> services) onApply;

  const _SortFilterSheet({
    required this.currentSort,
    required this.currentServices,
    required this.onApply,
  });

  @override
  State<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<_SortFilterSheet> {
  late SortBy _sort;
  late Set<String> _services;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _services = Set.from(widget.currentServices);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(l10n.t('sort_filter'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() { _sort = SortBy.distance; _services.clear(); }),
                child: Text(l10n.t('clear_all'),
                    style: const TextStyle(fontSize: 13, color: AppTheme.googleBlue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.t('sort_by'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary, letterSpacing: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _SortChip(
                label: l10n.t('sort_distance'),
                selected: _sort == SortBy.distance,
                icon: Icons.near_me_rounded,
                onTap: () => setState(() => _sort = SortBy.distance),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: l10n.t('sort_wait'),
                selected: _sort == SortBy.waitTime,
                icon: Icons.schedule_rounded,
                onTap: () => setState(() => _sort = SortBy.waitTime),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: l10n.t('sort_rating'),
                selected: _sort == SortBy.rating,
                icon: Icons.star_rounded,
                onTap: () => setState(() => _sort = SortBy.rating),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.t('filter_services'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary, letterSpacing: 0.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allServices.map((service) {
              final selected = _services.contains(service);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) _services.remove(service); else _services.add(service);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.googleBlue : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.serviceLabel(service),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.googleBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                widget.onApply(_sort, _services);
                Navigator.of(context).pop();
              },
              child: Text(l10n.t('apply'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.googleBlue : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Language toggle ──────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final bool isArabic;
  const _LanguageToggle({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => EmiratesWashApp.of(context).setLocale(Locale(isArabic ? 'en' : 'ar')),
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
              color: AppTheme.googleBlue, fontSize: 12, fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
