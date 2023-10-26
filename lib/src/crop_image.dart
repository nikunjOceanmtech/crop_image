import 'dart:ui' as ui;

import 'crop_controller.dart';
import 'crop_grid.dart';
import 'crop_rect.dart';
import 'crop_rotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CropImage extends StatefulWidget {
  final CropController? controller;
  final Image? image;
  final Color gridColor;
  final Color gridInnerColor;
  final Color gridCornerColor;
  final double paddingSize;
  final double touchSize;
  final double gridCornerSize;
  final double gridThinWidth;
  final double gridThickWidth;
  final Color scrimColor;
  final bool alwaysShowThirdLines;
  final ValueChanged<Rect>? onCrop;
  final double minimumImageSize;
  final double maximumImageSize;
  final bool alwaysMove;

  const CropImage({
    Key? key,
    this.controller,
    this.image,
    this.gridColor = Colors.white70,
    Color? gridInnerColor,
    Color? gridCornerColor,
    this.paddingSize = 0,
    this.touchSize = 50,
    this.gridCornerSize = 25,
    this.gridThinWidth = 2,
    this.gridThickWidth = 5,
    this.scrimColor = Colors.black54,
    this.alwaysShowThirdLines = false,
    this.onCrop,
    this.minimumImageSize = 100,
    this.maximumImageSize = double.infinity,
    this.alwaysMove = false,
  })  : gridInnerColor = gridInnerColor ?? gridColor,
        gridCornerColor = gridCornerColor ?? gridColor,
        assert(gridCornerSize > 0, 'gridCornerSize cannot be zero'),
        assert(touchSize > 0, 'touchSize cannot be zero'),
        assert(gridThinWidth > 0, 'gridThinWidth cannot be zero'),
        assert(gridThickWidth > 0, 'gridThickWidth cannot be zero'),
        assert(minimumImageSize > 0, 'minimumImageSize cannot be zero'),
        assert(maximumImageSize >= minimumImageSize, 'maximumImageSize cannot be less than minimumImageSize'),
        super(key: key);

  @override
  State<CropImage> createState() => _CropImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<CropController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<Image>('image', image));
    properties.add(DiagnosticsProperty<Color>('gridColor', gridColor));
    properties.add(DiagnosticsProperty<Color>('gridInnerColor', gridInnerColor));
    properties.add(DiagnosticsProperty<Color>('gridCornerColor', gridCornerColor));
    properties.add(DiagnosticsProperty<double>('paddingSize', paddingSize));
    properties.add(DiagnosticsProperty<double>('touchSize', touchSize));
    properties.add(DiagnosticsProperty<double>('gridCornerSize', gridCornerSize));
    properties.add(DiagnosticsProperty<double>('gridThinWidth', gridThinWidth));
    properties.add(DiagnosticsProperty<double>('gridThickWidth', gridThickWidth));
    properties.add(DiagnosticsProperty<Color>('scrimColor', scrimColor));
    properties.add(DiagnosticsProperty<bool>('alwaysShowThirdLines', alwaysShowThirdLines));
    properties.add(DiagnosticsProperty<ValueChanged<Rect>>('onCrop', onCrop, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('minimumImageSize', minimumImageSize));
    properties.add(DiagnosticsProperty<double>('maximumImageSize', maximumImageSize));
    properties.add(DiagnosticsProperty<bool>('alwaysMove', alwaysMove));
  }
}

enum _CornerTypes { UpperLeft, UpperRight, LowerRight, LowerLeft, None, Move }

class _CropImageState extends State<CropImage> {
  late CropController controller;
  late ImageStream _stream;
  late ImageStreamListener _streamListener;
  var currentCrop = Rect.zero;
  var size = Size.zero;
  _TouchPoint? panStart;

  Map<_CornerTypes, Offset> get gridCorners => <_CornerTypes, Offset>{
        _CornerTypes.UpperLeft:
            controller.crop.topLeft.scale(size.width, size.height).translate(widget.paddingSize, widget.paddingSize),
        _CornerTypes.UpperRight:
            controller.crop.topRight.scale(size.width, size.height).translate(widget.paddingSize, widget.paddingSize),
        _CornerTypes.LowerRight: controller.crop.bottomRight
            .scale(size.width, size.height)
            .translate(widget.paddingSize, widget.paddingSize),
        _CornerTypes.LowerLeft:
            controller.crop.bottomLeft.scale(size.width, size.height).translate(widget.paddingSize, widget.paddingSize),
      };

  @override
  void initState() {
    super.initState();

    controller = widget.controller ?? CropController();
    controller.addListener(onChange);
    currentCrop = controller.crop;

    _stream = widget.image!.image.resolve(const ImageConfiguration());
    _streamListener = ImageStreamListener((info, _) => controller.image = info.image);
    _stream.addListener(_streamListener);
  }

  @override
  void dispose() {
    controller.removeListener(onChange);

    if (widget.controller == null) {
      controller.dispose();
    }

    _stream.removeListener(_streamListener);

    super.dispose();
  }

  @override
  void didUpdateWidget(CropImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller == null && oldWidget.controller != null) {
      controller = CropController.fromValue(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      controller.dispose();
    }
  }

  double _getImageRatio(final double maxWidth, final double maxHeight) =>
      controller.getImage()!.width / controller.getImage()!.height;

  double _getWidth(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio(maxWidth, maxHeight);
    final screenRatio = maxWidth / maxHeight;
    if (controller.value.rotation.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio > screenRatio) {
      return maxWidth;
    }
    return maxHeight * imageRatio;
  }

  double _getHeight(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio(maxWidth, maxHeight);
    final screenRatio = maxWidth / maxHeight;
    if (controller.value.rotation.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio < screenRatio) {
      return maxHeight;
    }
    return maxWidth / imageRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (controller.getImage() == null) {
            return const CircularProgressIndicator();
          }
          final double maxWidth = constraints.maxWidth - 2 * widget.paddingSize;
          final double maxHeight = constraints.maxHeight - 2 * widget.paddingSize;
          final double width = _getWidth(maxWidth, maxHeight);
          final double height = _getHeight(maxWidth, maxHeight);
          size = Size(width, height);
          final bool showCorners = widget.minimumImageSize != widget.maximumImageSize;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  painter: _RotatedImagePainter(
                    controller.getImage()!,
                    controller.rotation,
                  ),
                ),
              ),
              SizedBox(
                width: width + 2 * widget.paddingSize,
                height: height + 2 * widget.paddingSize,
                child: GestureDetector(
                  onPanStart: onPanStart,
                  onPanUpdate: onPanUpdate,
                  onPanEnd: onPanEnd,
                  child: CropGrid(
                    crop: currentCrop,
                    gridColor: widget.gridColor,
                    gridInnerColor: widget.gridInnerColor,
                    gridCornerColor: widget.gridCornerColor,
                    paddingSize: widget.paddingSize,
                    cornerSize: showCorners ? widget.gridCornerSize : 0,
                    thinWidth: widget.gridThinWidth,
                    thickWidth: widget.gridThickWidth,
                    scrimColor: widget.scrimColor,
                    showCorners: showCorners,
                    alwaysShowThirdLines: widget.alwaysShowThirdLines,
                    isMoving: panStart != null,
                    onSize: (size) {
                      this.size = size;
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onPanStart(DragStartDetails details) {
    if (panStart == null) {
      final type = hitTest(details.localPosition);
      if (type != _CornerTypes.None) {
        var basePoint = gridCorners[(type == _CornerTypes.Move) ? _CornerTypes.UpperLeft : type]!;
        setState(() {
          panStart = _TouchPoint(type, details.localPosition - basePoint);
        });
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (panStart != null) {
      final offset = details.localPosition - panStart!.offset - Offset(widget.paddingSize, widget.paddingSize);
      if (panStart!.type == _CornerTypes.Move) {
        moveArea(offset);
      } else {
        moveCorner(panStart!.type, offset);
      }
      widget.onCrop?.call(controller.crop);
    }
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      panStart = null;
    });
  }

  void onChange() {
    setState(() {
      currentCrop = controller.crop;
    });
  }

  _CornerTypes hitTest(Offset point) {
    for (final gridCorner in gridCorners.entries) {
      final area = Rect.fromCenter(center: gridCorner.value, width: widget.touchSize, height: widget.touchSize);
      if (area.contains(point)) {
        return gridCorner.key;
      }
    }

    if (widget.alwaysMove) {
      return _CornerTypes.Move;
    }

    final area = Rect.fromPoints(gridCorners[_CornerTypes.UpperLeft]!, gridCorners[_CornerTypes.LowerRight]!);
    return area.contains(point) ? _CornerTypes.Move : _CornerTypes.None;
  }

  void moveArea(Offset point) {
    final crop = controller.crop.multiply(size);
    controller.crop = Rect.fromLTWH(
      point.dx.clamp(0, size.width - crop.width),
      point.dy.clamp(0, size.height - crop.height),
      crop.width,
      crop.height,
    ).divide(size);
  }

  void moveCorner(_CornerTypes type, Offset point) {
    final crop = controller.crop.multiply(size);
    var left = crop.left;
    var top = crop.top;
    var right = crop.right;
    var bottom = crop.bottom;

    switch (type) {
      case _CornerTypes.UpperLeft:
        left = point.dx.clamp(right - widget.maximumImageSize, point.dx.clamp(0, right - widget.minimumImageSize));
        top = point.dy.clamp(bottom - widget.maximumImageSize, point.dy.clamp(0, bottom - widget.minimumImageSize));
        break;
      case _CornerTypes.UpperRight:
        right =
            point.dx.clamp(point.dx.clamp(left + widget.minimumImageSize, size.width), left + widget.maximumImageSize);
        top = point.dy.clamp(bottom - widget.maximumImageSize, point.dy.clamp(0, bottom - widget.minimumImageSize));
        break;
      case _CornerTypes.LowerRight:
        right =
            point.dx.clamp(point.dx.clamp(left + widget.minimumImageSize, size.width), left + widget.maximumImageSize);
        bottom =
            point.dy.clamp(point.dy.clamp(top + widget.minimumImageSize, size.height), top + widget.maximumImageSize);
        break;
      case _CornerTypes.LowerLeft:
        left = point.dx.clamp(right - widget.maximumImageSize, point.dx.clamp(0, right - widget.minimumImageSize));
        bottom =
            point.dy.clamp(point.dy.clamp(top + widget.minimumImageSize, size.height), top + widget.maximumImageSize);
        break;
      default:
        assert(false);
    }
    if (controller.aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;
      if (width / height > controller.aspectRatio!) {
        switch (type) {
          case _CornerTypes.UpperLeft:
          case _CornerTypes.LowerLeft:
            left = right - height * controller.aspectRatio!;
            break;
          case _CornerTypes.UpperRight:
          case _CornerTypes.LowerRight:
            right = left + height * controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (type) {
          case _CornerTypes.UpperLeft:
          case _CornerTypes.UpperRight:
            top = bottom - width / controller.aspectRatio!;
            break;
          case _CornerTypes.LowerRight:
          case _CornerTypes.LowerLeft:
            bottom = top + width / controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    controller.crop = Rect.fromLTRB(left, top, right, bottom).divide(size);
  }
}

class _TouchPoint {
  final _CornerTypes type;
  final Offset offset;

  _TouchPoint(this.type, this.offset);
}

class _RotatedImagePainter extends CustomPainter {
  _RotatedImagePainter(this.image, this.rotation);

  final ui.Image image;
  final CropRotation rotation;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    double targetWidth = size.width;
    double targetHeight = size.height;
    double offset = 0;
    if (rotation != CropRotation.up) {
      if (rotation.isSideways) {
        final double tmp = targetHeight;
        targetHeight = targetWidth;
        targetWidth = tmp;
        offset = (targetWidth - targetHeight) / 2;
        if (rotation == CropRotation.left) {
          offset = -offset;
        }
      }
      canvas.save();
      canvas.translate(targetWidth / 2, targetHeight / 2);
      canvas.rotate(rotation.radians);
      canvas.translate(-targetWidth / 2, -targetHeight / 2);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offset, offset, targetWidth, targetHeight),
      _paint,
    );
    if (rotation != CropRotation.up) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
