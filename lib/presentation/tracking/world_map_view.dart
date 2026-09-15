import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/basemap/land_basemap_repository.dart';
import '../../domain/map_projection.dart';
import 'world_map_painter.dart';

/// A basic, fully offline world map: a bundled land/ocean silhouette (no
/// tiles, no network, ever) with the planned route, flown track, and the
/// aircraft's own position drawn on top. Pan and zoom come from
/// [InteractiveViewer], which is simple enough to not get stuck the way a
/// tile-layer map can when tiles fail to load.
class WorldMapView extends StatefulWidget {
  final List<List<double>> routeLatLon;
  final List<List<double>> traveledLatLon;
  final double? currentLat;
  final double? currentLon;
  final double? headingDegrees;

  const WorldMapView({
    super.key,
    required this.routeLatLon,
    required this.traveledLatLon,
    this.currentLat,
    this.currentLon,
    this.headingDegrees,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  final _controller = TransformationController();
  final _repository = LandBasemapRepository();
  Path? _land;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _repository.load().then((path) {
      if (mounted) setState(() => _land = path);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitToRoute(Size viewportSize) {
    if (widget.routeLatLon.isEmpty ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return;
    }
    final points =
        widget.routeLatLon.map((p) => MapProjection.project(p[0], p[1])).toList();
    var minX = points.first.dx, maxX = points.first.dx;
    var minY = points.first.dy, maxY = points.first.dy;
    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    const padding = 80.0;
    final boxWidth = (maxX - minX) + padding * 2;
    final boxHeight = (maxY - minY) + padding * 2;
    final boxCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    final scale = math
        .min(viewportSize.width / boxWidth, viewportSize.height / boxHeight)
        .clamp(0.5, 30.0);
    final viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);

    final matrix = Matrix4.identity()
      ..translateByDouble(
        viewportCenter.dx - boxCenter.dx * scale,
        viewportCenter.dy - boxCenter.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    _controller.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final land = _land;
    if (land == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final routeSegments = MapProjection.projectPolyline(widget.routeLatLon);
    final traveledSegments = MapProjection.projectPolyline(widget.traveledLatLon);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_fitted && viewportSize.width > 0 && viewportSize.height > 0) {
          _fitted = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _fitToRoute(viewportSize));
        }

        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 0.5,
                  maxScale: 30,
                  boundaryMargin: const EdgeInsets.all(400),
                  child: SizedBox(
                    width: MapProjection.mapWidth,
                    height: MapProjection.mapHeight,
                    child: CustomPaint(
                      size: const Size(MapProjection.mapWidth, MapProjection.mapHeight),
                      painter: WorldMapPainter(
                        land: land,
                        routeSegments: routeSegments,
                        traveledSegments: traveledSegments,
                        oceanColor: isDark
                            ? const Color(0xFF16324A)
                            : const Color(0xFFBFE0F0),
                        landColor: isDark
                            ? const Color(0xFF3A4A3A)
                            : const Color(0xFFE9E3CC),
                        landBorderColor: isDark
                            ? const Color(0xFF56705A)
                            : const Color(0xFFB9AF8E),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.currentLat != null && widget.currentLon != null)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final childPoint =
                        MapProjection.project(widget.currentLat!, widget.currentLon!);
                    final screenPoint =
                        MatrixUtils.transformPoint(_controller.value, childPoint);
                    return Positioned(
                      left: screenPoint.dx - 14,
                      top: screenPoint.dy - 14,
                      child: IgnorePointer(
                        child: Transform.rotate(
                          angle: (widget.headingDegrees ?? 0) * math.pi / 180,
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.redAccent,
                            size: 28,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
