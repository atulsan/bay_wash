import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../data/dummy_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/car_wash.dart';
import '../services/route_eta_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import '../widgets/wash_detail_sheet.dart';
import '../widgets/wash_list_card.dart';
import '../widgets/wash_marker.dart';
import '../widgets/app_settings_sheet.dart';
import '../widgets/smooth_press.dart';

enum SortBy { distance, waitTime, routeEta, rating }

enum HomeSheetMode { list, filter }

const _allServices = [
  'Express Wash',
  'Automatic Wash',
  'Exterior Wash',
  'Interior Clean',
  'Vacuum Bay',
  'Tyre Shine',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _searchCtrl = TextEditingController();
  final _routeEtaService = RouteEtaService();

  static const _defaultCenter = LatLng(24.78, 54.96);
  static const _dubaiTestOrigin = LatLng(25.2048, 55.2708);
  static const _abuDhabiTestOrigin = LatLng(24.4539, 54.3773);
  LatLng _origin = _dubaiTestOrigin;
  String _originLabel = 'Test location · Dubai Mall';

  CarWash? _selectedWash;
  final Map<String, RouteEta> _routeEtas = {};
  final Set<String> _loadingRouteEtaIds = {};
  HomeSheetMode _sheetMode = HomeSheetMode.list;
  WashStatus? _statusFilter;
  SortBy _sortBy = SortBy.distance;
  final Set<String> _serviceFilter = {};
  bool _loadingLocation = false;

  List<CarWash> get _sortedWashes {
    final list = [...dummyCarWashes];
    list.sort(
      (a, b) => switch (_sortBy) {
        SortBy.distance => haversineKm(
            _origin.latitude,
            _origin.longitude,
            a.lat,
            a.lng,
          ).compareTo(
            haversineKm(_origin.latitude, _origin.longitude, b.lat, b.lng),
          ),
        SortBy.waitTime => a.waitTimeMinutes.compareTo(b.waitTimeMinutes),
        SortBy.routeEta => (_routeEtas[a.id]?.totalMinutes ?? 9999)
            .compareTo(_routeEtas[b.id]?.totalMinutes ?? 9999),
        SortBy.rating => b.rating.compareTo(a.rating),
      },
    );
    return list;
  }

  List<CarWash> get _filteredWashes => _sortedWashes.where((w) {
        final query = _searchCtrl.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          final searchable = [
            w.name,
            w.nameAr,
            w.address,
            w.addressAr,
            ...w.services,
          ].join(' ').toLowerCase();
          if (!searchable.contains(query)) {
            return false;
          }
        }
        if (_statusFilter != null && w.status != _statusFilter) {
          return false;
        }
        if (_serviceFilter.isNotEmpty &&
            !_serviceFilter.every((s) => w.services.contains(s))) {
          return false;
        }
        return true;
      }).toList();

  int get _activeFilterCount =>
      (_statusFilter != null ? 1 : 0) +
      _serviceFilter.length +
      (_searchCtrl.text.trim().isNotEmpty ? 1 : 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshRouteEtas());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _origin = loc;
        _originLabel = 'GPS location';
        _routeEtas.clear();
      });
      _mapController.move(loc, 13);
      unawaited(_refreshRouteEtas(force: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not get location')));
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
          routeEta: _routeEtas[wash.id],
          isRouteEtaLoading: _loadingRouteEtaIds.contains(wash.id),
          routeEtaLoader: () => _estimateRouteEtaForSheet(wash),
          scrollController: sc,
        ),
      ),
    ).then((_) => setState(() => _selectedWash = null));
  }

  Future<RouteEta> _estimateRouteEtaForSheet(CarWash wash) async {
    if (mounted) {
      setState(() => _loadingRouteEtaIds.add(wash.id));
    }
    final eta = await _routeEtaService.estimate(
      origin: _origin,
      destination: wash.latLng,
      queueWaitMinutes: wash.waitTimeMinutes,
    );
    if (mounted) {
      setState(() {
        _routeEtas[wash.id] = eta;
        _loadingRouteEtaIds.remove(wash.id);
      });
    }
    return eta;
  }

  Future<void> _refreshRouteEtas({bool force = false}) async {
    final washes = _filteredWashes;
    for (final wash in washes) {
      unawaited(_loadRouteEta(wash, force: force));
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  Future<void> _loadRouteEta(CarWash wash, {bool force = false}) async {
    if (!force && _routeEtas.containsKey(wash.id)) return;
    if (_loadingRouteEtaIds.contains(wash.id)) return;
    setState(() => _loadingRouteEtaIds.add(wash.id));

    final eta = await _routeEtaService.estimate(
      origin: _origin,
      destination: wash.latLng,
      queueWaitMinutes: wash.waitTimeMinutes,
    );

    if (!mounted) return;
    setState(() {
      _routeEtas[wash.id] = eta;
      _loadingRouteEtaIds.remove(wash.id);
    });
  }

  void _showAppSettings() => showBayWashAppSettings(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filteredWashes;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(l10n, filtered),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
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
          _buildOriginPill(),
          _buildRouteStatusPill(l10n),
          _buildMapStatusFilter(l10n),
          _buildLocateFab(),
          _buildBottomSheet(context, l10n, filtered),
        ],
      ),
    );
  }

  Widget _buildMap(AppLocalizations l10n, List<CarWash> washes) {
    final tileUrl =
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    final selected = _selectedWash;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 8.4,
        onTap: (_, __) => setState(() => _selectedWash = null),
      ),
      children: [
        TileLayer(
          key: ValueKey(tileUrl),
          urlTemplate: tileUrl,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.baywash.app',
        ),
        if (selected != null) ...[
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  ..._routePoints(selected),
                ],
                color: AppTheme.bayTeal.withValues(alpha: 0.90),
                strokeWidth: 5,
                borderColor: Colors.white,
                borderStrokeWidth: 3,
              ),
            ],
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: selected.latLng,
                radius: 44,
                color: AppTheme.bayTeal.withValues(alpha: 0.10),
                borderColor: AppTheme.bayTeal.withValues(alpha: 0.24),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        ],
        MarkerLayer(
          markers: washes
              .map(
                (wash) => Marker(
                  point: wash.latLng,
                  width: 72,
                  height: 52,
                  alignment: Alignment.bottomCenter,
                  child: WashMarker(
                    wash: wash,
                    isSelected: _selectedWash?.id == wash.id,
                    routeEtaMinutes: _routeEtas[wash.id]?.totalMinutes,
                    onTap: () => _onMarkerTap(wash),
                  ),
                ),
              )
              .toList(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _origin,
              width: 150,
              height: 58,
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Present location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.bayTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.bayTeal.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<LatLng> _routePoints(CarWash selected) {
    final geometry = _routeEtas[selected.id]?.routeGeometry;
    if (geometry != null && geometry.length >= 2) {
      return geometry;
    }
    return [
      _origin,
      LatLng(
        (_origin.latitude + selected.lat) / 2 + 0.015,
        (_origin.longitude + selected.lng) / 2,
      ),
      selected.latLng,
    ];
  }

  void _setTestOrigin(LatLng origin, String label) {
    setState(() {
      _origin = origin;
      _originLabel = label;
      _routeEtas.clear();
    });
    _mapController.move(origin, 11);
    unawaited(_refreshRouteEtas(force: true));
  }

  void _setStatusFilter(WashStatus? status) {
    setState(() {
      _statusFilter = status;
      if (_selectedWash != null &&
          status != null &&
          _selectedWash!.status != status) {
        _selectedWash = null;
      }
    });
    unawaited(_refreshRouteEtas());
  }

  Widget _buildOriginPill() {
    return Positioned(
      left: 14,
      right: 14,
      top: MediaQuery.of(context).padding.top + 74,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 16,
                    color: AppTheme.bayTeal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _originLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _OriginQuickButton(
            label: 'DXB',
            selected: _origin == _dubaiTestOrigin,
            onTap: () => _setTestOrigin(
              _dubaiTestOrigin,
              'Test location · Dubai Mall',
            ),
          ),
          const SizedBox(width: 6),
          _OriginQuickButton(
            label: 'AUH',
            selected: _origin == _abuDhabiTestOrigin,
            onTap: () => _setTestOrigin(
              _abuDhabiTestOrigin,
              'Test location · Abu Dhabi Corniche',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatusPill(AppLocalizations l10n) {
    final hasOrsEta = _routeEtas.values.any((eta) => eta.isOpenRouteService);
    final isLoading = _loadingRouteEtaIds.isNotEmpty;
    final routeApiEnabled = _routeEtaService.hasApiKey;

    return Positioned(
      left: 14,
      top: MediaQuery.of(context).padding.top + 126,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasOrsEta ? Icons.route_rounded : Icons.near_me_rounded,
              size: 16,
              color: hasOrsEta ? AppTheme.statusFree : AppTheme.bayTeal,
            ),
            const SizedBox(width: 6),
            Text(
              hasOrsEta
                  ? l10n.t('ors_route')
                  : routeApiEnabled && isLoading
                      ? '${l10n.t('route_eta')}...'
                      : l10n.t('route_estimate'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStatusFilter(AppLocalizations l10n) {
    return Positioned(
      left: 14,
      top: MediaQuery.of(context).padding.top + 172,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapFilterSegment(
              label: l10n.t('filter_all'),
              selected: _statusFilter == null,
              color: AppTheme.bayTeal,
              onTap: () => _setStatusFilter(null),
            ),
            _MapFilterSegment(
              label: l10n.t('status_free'),
              selected: _statusFilter == WashStatus.free,
              color: AppTheme.statusFree,
              onTap: () => _setStatusFilter(WashStatus.free),
            ),
            _MapFilterSegment(
              label: l10n.t('status_busy'),
              selected: _statusFilter == WashStatus.busy,
              color: AppTheme.statusBusy,
              onTap: () => _setStatusFilter(WashStatus.busy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.bayInk,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'App settings',
                  onPressed: _showAppSettings,
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.t('app_title'),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0,
                          fontFamilyFallback: AppTheme.brandFontFallback,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.local_car_wash_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
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
      top: MediaQuery.of(context).padding.top + 222,
      child: Column(
        children: [
          _RoundMapButton(
            icon: Icons.my_location_rounded,
            onTap: _loadingLocation ? null : _locateMe,
            child: _loadingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          _RoundMapButton(
            icon: Icons.tune_rounded,
            onTap: () => setState(() => _sheetMode = HomeSheetMode.filter),
          ),
          const SizedBox(height: 12),
          _RoundMapButton(
            icon: Icons.info_outline_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pin number shows estimated available bays'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<CarWash> washes,
  ) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.34,
      minChildSize: 0.10,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.10, 0.34, 0.74, 0.92],
      builder: (_, scrollController) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, -5),
              ),
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
                    (_sheetController.size - d.primaryDelta! / sh).clamp(
                      0.10,
                      0.92,
                    ),
                  );
                },
                onVerticalDragEnd: (_) {
                  const snaps = [0.10, 0.34, 0.74, 0.92];
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
                      width: 44,
                      height: 4,
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
                        mode: _sheetMode,
                        searchController: _searchCtrl,
                        activeFilterCount: _activeFilterCount,
                        sortBy: _sortBy,
                        selectedServices: _serviceFilter,
                        onModeChanged: (mode) =>
                            setState(() => _sheetMode = mode),
                        onSearchChanged: (_) {
                          setState(() {});
                          unawaited(_refreshRouteEtas());
                        },
                        onSortChanged: (sort) {
                          setState(() => _sortBy = sort);
                          unawaited(_refreshRouteEtas());
                        },
                        onServiceToggled: (service) => setState(() {
                          if (_serviceFilter.contains(service)) {
                            _serviceFilter.remove(service);
                          } else {
                            _serviceFilter.add(service);
                          }
                          unawaited(_refreshRouteEtas());
                        }),
                        onClearAll: () => setState(() {
                          _searchCtrl.clear();
                          _statusFilter = null;
                          _sortBy = SortBy.distance;
                          _serviceFilter.clear();
                          unawaited(_refreshRouteEtas());
                        }),
                      );
                    }
                    if (washes.isEmpty) return _EmptyState(l10n: l10n);
                    final wash = washes[i - 1];
                    final dist = haversineKm(
                      _origin.latitude,
                      _origin.longitude,
                      wash.lat,
                      wash.lng,
                    );
                    return _AnimatedListTileIn(
                      key: ValueKey('${wash.id}-${_sheetMode.name}'),
                      index: i,
                      child: WashListCard(
                        wash: wash,
                        distanceKm: dist,
                        routeEta: _routeEtas[wash.id],
                        isRouteEtaLoading:
                            _loadingRouteEtaIds.contains(wash.id),
                        isSelected: _selectedWash?.id == wash.id,
                        onTap: () => _onMarkerTap(wash),
                      ),
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
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppTheme.divider,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('no_results'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
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
  final HomeSheetMode mode;
  final TextEditingController searchController;
  final int activeFilterCount;
  final SortBy sortBy;
  final Set<String> selectedServices;
  final ValueChanged<HomeSheetMode> onModeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SortBy> onSortChanged;
  final ValueChanged<String> onServiceToggled;
  final VoidCallback onClearAll;

  const _SheetHeader({
    required this.l10n,
    required this.filteredCount,
    required this.mode,
    required this.searchController,
    required this.activeFilterCount,
    required this.sortBy,
    required this.selectedServices,
    required this.onModeChanged,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onServiceToggled,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Container(
                    key: ValueKey(filteredCount),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bayTeal,
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
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: activeFilterCount > 0
                      ? SmoothPress(
                          key: const ValueKey('clear-all'),
                          onTap: onClearAll,
                          child: Text(
                            l10n.t('clear_all'),
                            style: const TextStyle(
                              color: AppTheme.bayTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-clear')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ModeToggle(
              mode: mode,
              onChanged: onModeChanged,
              listLabel: l10n.t('list_view'),
              filterLabel: l10n.t('filter_view'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SearchField(
              controller: searchController,
              hint: l10n.t('search_washes'),
              onChanged: onSearchChanged,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: mode == HomeSheetMode.filter
                ? _FilterPanel(
                    key: const ValueKey('filter-panel'),
                    l10n: l10n,
                    sortBy: sortBy,
                    selectedServices: selectedServices,
                    onSortChanged: onSortChanged,
                    onServiceToggled: onServiceToggled,
                  )
                : const SizedBox(
                    key: ValueKey('list-panel'),
                    height: 12,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedListTileIn extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedListTileIn(
      {super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = index > 6 ? 6 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + delay * 24),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final HomeSheetMode mode;
  final ValueChanged<HomeSheetMode> onChanged;
  final String listLabel;
  final String filterLabel;

  const _ModeToggle({
    required this.mode,
    required this.onChanged,
    required this.listLabel,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: listLabel,
            icon: Icons.view_list_rounded,
            selected: mode == HomeSheetMode.list,
            onTap: () => onChanged(HomeSheetMode.list),
          ),
          _ModeButton(
            label: filterLabel,
            icon: Icons.tune_rounded,
            selected: mode == HomeSheetMode.filter,
            onTap: () => onChanged(HomeSheetMode.filter),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SmoothPress(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.bayTeal : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.bayTeal : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final SortBy sortBy;
  final Set<String> selectedServices;
  final ValueChanged<SortBy> onSortChanged;
  final ValueChanged<String> onServiceToggled;

  const _FilterPanel({
    super.key,
    required this.l10n,
    required this.sortBy,
    required this.selectedServices,
    required this.onSortChanged,
    required this.onServiceToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: l10n.t('sort_by')),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SortChip(
                  label: l10n.t('sort_distance'),
                  selected: sortBy == SortBy.distance,
                  icon: Icons.near_me_rounded,
                  onTap: () => onSortChanged(SortBy.distance),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: l10n.t('sort_wait'),
                  selected: sortBy == SortBy.waitTime,
                  icon: Icons.schedule_rounded,
                  onTap: () => onSortChanged(SortBy.waitTime),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: l10n.t('sort_eta'),
                  selected: sortBy == SortBy.routeEta,
                  icon: Icons.route_rounded,
                  onTap: () => onSortChanged(SortBy.routeEta),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: l10n.t('sort_rating'),
                  selected: sortBy == SortBy.rating,
                  icon: Icons.star_rounded,
                  onTap: () => onSortChanged(SortBy.rating),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel(label: l10n.t('filter_services')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allServices.map((service) {
              final selected = selectedServices.contains(service);
              return SmoothPress(
                onTap: () => onServiceToggled(service),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppTheme.bayTeal : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.serviceLabel(service),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _MapFilterSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MapFilterSegment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints.tightFor(width: 82),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
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
    return SmoothPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.bayTeal : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginQuickButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OriginQuickButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.bayTeal : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.bayTeal : AppTheme.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? child;

  const _RoundMapButton({
    required this.icon,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: child ??
                Icon(
                  icon,
                  color: AppTheme.textPrimary,
                  size: 25,
                ),
          ),
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
    return SmoothPress(
      onTap: () =>
          BayWashApp.of(context).setLocale(Locale(isArabic ? 'en' : 'ar')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.36),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            key: ValueKey(isArabic),
            isArabic ? 'EN' : 'عربي',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
