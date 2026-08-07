import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/vehicle_counter_api.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';

class VendorCameraScreen extends StatefulWidget {
  const VendorCameraScreen({super.key});

  @override
  State<VendorCameraScreen> createState() => _VendorCameraScreenState();
}

class _VendorCameraScreenState extends State<VendorCameraScreen> {
  late VehicleCounterApi _api;
  late final TextEditingController _baseUrlController;
  Timer? _countsTimer;
  Timer? _frameTimer;
  Timer? _previewTimer;
  VehicleCounterCounts? _counts;
  VehicleCounterZoneConfig? _zoneConfig;
  String? _selectedZoneId;
  String? _error;
  List<ZonePoint> _draftPoints = const [];
  int? _dragPointIndex;
  int _frameNonce = 0;
  bool _editing = false;
  bool _fetching = false;
  bool _saving = false;
  bool _previewInFlight = false;
  bool _previewPending = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: VehicleCounterApi.defaultBaseUrl,
    );
    _api = VehicleCounterApi(_baseUrlController.text);
    _refreshAll();
    _countsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshCounts(),
    );
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) {
        if (mounted) setState(() => _frameNonce++);
      },
    );
  }

  @override
  void dispose() {
    _countsTimer?.cancel();
    _frameTimer?.cancel();
    _previewTimer?.cancel();
    _baseUrlController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    try {
      final results = await Future.wait<Object>([
        _api.getCounts(),
        _api.getZones(),
      ]);
      if (!mounted) return;
      final counts = results[0] as VehicleCounterCounts;
      final config = results[1] as VehicleCounterZoneConfig;
      setState(() {
        _counts = counts;
        _zoneConfig = config;
        _selectedZoneId = config.zones.any(
          (zone) => zone.id == _selectedZoneId,
        )
            ? _selectedZoneId
            : config.zones.first.id;
        _error = counts.error;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  Future<void> _refreshCounts() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final counts = await _api.getCounts();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _error = counts.error;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      _fetching = false;
    }
  }

  VehicleCounterZone? get _selectedZone {
    final config = _zoneConfig;
    if (config == null) return null;
    for (final zone in config.zones) {
      if (zone.id == _selectedZoneId) return zone;
    }
    return null;
  }

  void _beginEditing({bool redraw = false}) {
    final zone = _selectedZone;
    if (zone == null) return;
    setState(() {
      _editing = true;
      _draftPoints = redraw ? <ZonePoint>[] : List.of(zone.points);
      _dragPointIndex = null;
    });
  }

  Future<void> _cancelEditing() async {
    _previewTimer?.cancel();
    _previewPending = false;
    await _waitForPreviewIdle();
    final savedConfig = _zoneConfig;
    setState(() {
      _editing = false;
      _draftPoints = const [];
      _dragPointIndex = null;
    });
    if (savedConfig == null) return;
    try {
      await _api.previewZones(savedConfig);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  void _addPoint(Offset localPosition, Size size) {
    if (!_editing || _draftPoints.length >= 16) return;
    if (_nearestPointIndex(localPosition, size) != null) return;
    setState(() {
      _draftPoints = [
        ..._draftPoints,
        ZonePoint(
          (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
          (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
        ),
      ];
    });
    _scheduleLivePreview();
  }

  void _startDragging(Offset localPosition, Size size) {
    if (!_editing) return;
    _dragPointIndex = _nearestPointIndex(localPosition, size);
  }

  void _dragPoint(Offset localPosition, Size size) {
    final index = _dragPointIndex;
    if (!_editing || index == null) return;
    final points = List<ZonePoint>.of(_draftPoints);
    points[index] = ZonePoint(
      (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
    setState(() => _draftPoints = points);
    _scheduleLivePreview();
  }

  void _finishDragging() {
    setState(() => _dragPointIndex = null);
    _scheduleLivePreview(immediate: true);
  }

  void _undoPoint() {
    if (_draftPoints.isEmpty) return;
    setState(() {
      _draftPoints = _draftPoints.sublist(0, _draftPoints.length - 1);
    });
    _scheduleLivePreview();
  }

  VehicleCounterZoneConfig? _draftZoneConfig() {
    final config = _zoneConfig;
    final selected = _selectedZone;
    if (config == null || selected == null || _draftPoints.length < 3) {
      return null;
    }
    return config.copyWith(
      zones: config.zones
          .map(
            (zone) => zone.id == selected.id
                ? zone.copyWith(points: List.of(_draftPoints))
                : zone,
          )
          .toList(growable: false),
    );
  }

  void _scheduleLivePreview({bool immediate = false}) {
    _previewTimer?.cancel();
    if (_draftPoints.length < 3) return;
    _previewTimer = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 180),
      () => unawaited(_applyLivePreview()),
    );
  }

  Future<void> _applyLivePreview() async {
    final config = _draftZoneConfig();
    if (config == null) return;
    if (_previewInFlight) {
      _previewPending = true;
      return;
    }
    _previewInFlight = true;
    try {
      await _api.previewZones(config);
      if (mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      _previewInFlight = false;
      if (_previewPending) {
        _previewPending = false;
        _scheduleLivePreview(immediate: true);
      }
    }
  }

  Future<void> _waitForPreviewIdle() async {
    while (_previewInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  int? _nearestPointIndex(Offset position, Size size) {
    var nearestDistance = 28.0;
    int? nearest;
    for (var index = 0; index < _draftPoints.length; index++) {
      final point = _draftPoints[index];
      final distance =
          (Offset(point.x * size.width, point.y * size.height) - position)
              .distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = index;
      }
    }
    return nearest;
  }

  Future<void> _savePolygon() async {
    _previewTimer?.cancel();
    _previewPending = false;
    await _waitForPreviewIdle();
    final config = _draftZoneConfig();
    if (config == null) return;
    await _persistConfig(config);
  }

  Future<void> _persistConfig(
    VehicleCounterZoneConfig config, {
    String? selectedZoneId,
    bool editAfterSave = false,
  }) async {
    setState(() => _saving = true);
    try {
      final saved = await _api.updateZones(config);
      if (!mounted) return;
      final selectedId = selectedZoneId ?? _selectedZoneId;
      final selected = saved.zones.firstWhere(
        (zone) => zone.id == selectedId,
        orElse: () => saved.zones.first,
      );
      setState(() {
        _zoneConfig = saved;
        _selectedZoneId = selected.id;
        _editing = editAfterSave;
        _draftPoints = editAfterSave ? List.of(selected.points) : const [];
        _error = null;
      });
      _showMessage('Bay zones updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
      _showMessage('Could not update bay zones.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addBay() async {
    final config = _zoneConfig;
    if (config == null) return;
    final controller = TextEditingController(
      text:
          'Bay ${config.zones.where((zone) => zone.id != 'entry_queue').length + 1}',
    );
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add camera zone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Zone name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty || !mounted) return;

    final id = _uniqueZoneId(label, config.zones);
    const defaultPoints = [
      ZonePoint(0.30, 0.30),
      ZonePoint(0.70, 0.30),
      ZonePoint(0.70, 0.72),
      ZonePoint(0.30, 0.72),
    ];
    final zone = VehicleCounterZone(
      id: id,
      label: label,
      points: defaultPoints,
    );
    await _persistConfig(
      config.copyWith(zones: [...config.zones, zone]),
      selectedZoneId: id,
      editAfterSave: true,
    );
  }

  Future<void> _deleteSelectedZone() async {
    final config = _zoneConfig;
    final selected = _selectedZone;
    if (config == null || selected == null || config.zones.length <= 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selected.label}?'),
        content: const Text('Its vehicle count will no longer be tracked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.vDanger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _persistConfig(
      config.copyWith(
        zones: config.zones
            .where((zone) => zone.id != selected.id)
            .toList(growable: false),
      ),
      selectedZoneId:
          config.zones.firstWhere((zone) => zone.id != selected.id).id,
    );
  }

  String _uniqueZoneId(String label, List<VehicleCounterZone> zones) {
    final base = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safeBase = base.isEmpty ? 'bay' : base;
    final existing = zones.map((zone) => zone.id).toSet();
    if (!existing.contains(safeBase)) return safeBase;
    var suffix = 2;
    while (existing.contains('${safeBase}_$suffix')) {
      suffix++;
    }
    return '${safeBase}_$suffix';
  }

  Future<void> _showEndpointDialog() async {
    final nextUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vehicle counter connection'),
        content: TextField(
          controller: _baseUrlController,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            hintText: 'http://192.168.1.20:8090',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _baseUrlController.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (nextUrl == null || nextUrl.isEmpty || !mounted) return;
    _api.close();
    _api = VehicleCounterApi(nextUrl);
    _baseUrlController.text = _api.baseUrl;
    setState(() {
      _counts = null;
      _zoneConfig = null;
      _error = null;
      _editing = false;
      _frameNonce++;
    });
    await _refreshAll();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final connected = counts?.ready == true && _error == null;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: VTopBar(
            title: 'Camera dashboard',
            subtitle: 'ADNOC demo bay live feed',
            rightSlot: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Counter connection',
                  onPressed: _showEndpointDialog,
                  icon: const Icon(Icons.settings_ethernet_rounded),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConnectionStrip(
                  connected: connected,
                  endpoint: _api.baseUrl,
                  error: _error,
                ),
                const SizedBox(height: 12),
                _buildCameraFrame(),
                const SizedBox(height: 12),
                _buildMetrics(counts),
                const SizedBox(height: 20),
                VSectionHeader(
                  title: 'Live zone counts',
                  count: counts?.zones.length,
                  topPadding: 0,
                ),
                _buildZoneCounts(),
                const SizedBox(height: 20),
                VSectionHeader(
                  title: 'Bay polygons',
                  count: _zoneConfig?.zones.length,
                  topPadding: 0,
                ),
                _buildPolygonControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFrame() {
    final counts = _counts;
    final ratio =
        counts != null && counts.frameWidth > 0 && counts.frameHeight > 0
            ? counts.frameWidth / counts.frameHeight
            : 16 / 9;
    final zones = _zoneConfig?.zones ?? const <VehicleCounterZone>[];
    final frameUri = _api.snapshotUri(
      frame: _frameNonce,
      raw: _editing,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: const Color(0xFF101719),
        child: AspectRatio(
          aspectRatio: ratio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _editing
                    ? (details) => _addPoint(details.localPosition, size)
                    : null,
                onPanStart: _editing
                    ? (details) => _startDragging(
                          details.localPosition,
                          size,
                        )
                    : null,
                onPanUpdate: _editing
                    ? (details) => _dragPoint(details.localPosition, size)
                    : null,
                onPanEnd: _editing ? (_) => _finishDragging() : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      frameUri.toString(),
                      key: ValueKey(frameUri),
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white54,
                          size: 36,
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: _ZonePainter(
                        zones: zones,
                        selectedZoneId: _selectedZoneId,
                        draftPoints: _editing ? _draftPoints : null,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _counts?.ready == true
                                    ? AppTheme.vStatusFree
                                    : AppTheme.vStatusBusy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _editing
                                  ? 'LIVE CALIBRATION'
                                  : _counts?.loopVideo == true
                                      ? 'LIVE · LOOP ${(_counts?.loopCount ?? 0) + 1}'
                                      : 'LIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildZoneCounts() {
    final zones = _counts?.zones ?? const <VehicleCounterZoneCount>[];
    if (zones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Waiting for camera zones...',
          style: TextStyle(color: AppTheme.vInk3, fontSize: 13),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: zones
          .map(
            (zone) => Container(
              constraints: const BoxConstraints(minWidth: 126),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.vSurface,
                border: Border.all(color: AppTheme.vLine),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.vStatusFree,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    zone.label,
                    style: const TextStyle(
                      color: AppTheme.vInk2,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${zone.count}',
                    style: const TextStyle(
                      color: AppTheme.vInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildMetrics(VehicleCounterCounts? counts) {
    final metrics = [
      _CameraMetric(
        label: 'Entry queue',
        value: '${counts?.queueCount ?? 0}',
        icon: Icons.directions_car_filled_rounded,
      ),
      _CameraMetric(
        label: 'In wash',
        value: '${counts?.inWashCount ?? 0}',
        icon: Icons.local_car_wash_rounded,
      ),
      _CameraMetric(
        label: 'Detector',
        value: '${counts?.detections ?? 0}',
        icon: Icons.center_focus_strong_rounded,
      ),
      _CameraMetric(
        label: 'FPS',
        value: (counts?.fpsMeasured ?? 0).toStringAsFixed(1),
        icon: Icons.speed_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((metric) => SizedBox(width: width, child: metric))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildPolygonControls() {
    final config = _zoneConfig;
    if (config == null) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    final selected = _selectedZone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedZoneId,
                  decoration: const InputDecoration(
                    labelText: 'Camera zone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: config.zones
                      .map(
                        (zone) => DropdownMenuItem(
                          value: zone.id,
                          child: Text(zone.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving || _editing
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedZoneId = value;
                            _editing = false;
                            _draftPoints = const [];
                          });
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Add bay zone',
                onPressed: _saving || _editing ? null : _addBay,
                icon: const Icon(Icons.add_rounded),
              ),
              IconButton(
                tooltip: 'Delete zone',
                onPressed: _saving || _editing || config.zones.length <= 1
                    ? null
                    : _deleteSelectedZone,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_editing)
            Row(
              children: [
                Text(
                  '${selected?.points.length ?? 0} points',
                  style: const TextStyle(
                    color: AppTheme.vInk3,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: selected == null ? null : _beginEditing,
                  icon: const Icon(Icons.edit_location_alt_rounded, size: 17),
                  label: const Text('Edit polygon'),
                ),
              ],
            )
          else ...[
            Text(
              '${_draftPoints.length} points',
              style: const TextStyle(
                color: AppTheme.vInk3,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Redraw polygon',
                    onPressed: () => _beginEditing(redraw: true),
                    icon: const Icon(Icons.gesture_rounded),
                  ),
                  IconButton(
                    tooltip: 'Undo point',
                    onPressed: _draftPoints.isEmpty ? null : _undoPoint,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: _saving || _draftPoints.length < 3
                        ? null
                        : _savePolygon,
                    icon: _saving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  final bool connected;
  final String endpoint;
  final String? error;

  const _ConnectionStrip({
    required this.connected,
    required this.endpoint,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppTheme.vStatusFree : AppTheme.vStatusBusy;
    final background =
        connected ? AppTheme.vStatusFreeBg : AppTheme.vStatusBusyBg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error == null
                  ? (connected ? 'Counter connected' : 'Counter starting')
                  : error!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              endpoint.replaceFirst(RegExp(r'^https?://'), ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CameraMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 16, color: AppTheme.vPrimary),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.vInk,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.vInk3, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ZonePainter extends CustomPainter {
  final List<VehicleCounterZone> zones;
  final String? selectedZoneId;
  final List<ZonePoint>? draftPoints;

  const _ZonePainter({
    required this.zones,
    required this.selectedZoneId,
    required this.draftPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final zone in zones) {
      final points = zone.id == selectedZoneId && draftPoints != null
          ? draftPoints!
          : zone.points;
      if (points.isEmpty) continue;
      final offsets = points
          .map((point) => Offset(point.x * size.width, point.y * size.height))
          .toList(growable: false);
      final selected = zone.id == selectedZoneId;
      final color = selected ? AppTheme.vGold : AppTheme.bayAqua;
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final point in offsets.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      if (offsets.length >= 3) path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: selected ? 0.16 : 0.08)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = selected ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );
      if (selected && draftPoints != null) {
        for (var index = 0; index < offsets.length; index++) {
          final point = offsets[index];
          canvas.drawCircle(
            point,
            8,
            Paint()..color = Colors.white,
          );
          canvas.drawCircle(
            point,
            6,
            Paint()..color = color,
          );
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${index + 1}',
              style: const TextStyle(
                color: AppTheme.vInk,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            point - Offset(textPainter.width / 2, textPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ZonePainter oldDelegate) {
    return oldDelegate.zones != zones ||
        oldDelegate.selectedZoneId != selectedZoneId ||
        oldDelegate.draftPoints != draftPoints;
  }
}
