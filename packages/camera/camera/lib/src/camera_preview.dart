// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../camera.dart';

/// A widget showing a live camera preview.
class CameraPreview extends StatelessWidget {
  /// Creates a preview widget for the given camera controller.
  const CameraPreview(this.controller, {super.key, this.child});

  /// The controller for the camera that the preview is shown for.
  final CameraController controller;

  /// A widget to overlay on top of the camera preview
  final Widget? child;

  @override
  Widget build(BuildContext context) => controller.value.isInitialized
      ? ValueListenableBuilder<CameraValue>(
          valueListenable: controller,
          builder: (BuildContext context, CameraValue value, Widget? child) =>
              _wrapInAspectRatio(
            value,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _wrapInRotatedBox(value, child: controller.buildPreview()),
                child ?? Container(),
              ],
            ),
          ),
          child: child,
        )
      : Container();

  static Widget _wrapInAspectRatio(CameraValue value, {required Widget child}) {
    if (kIsWeb) {
      return child;
    }
    return AspectRatio(
      aspectRatio:
          _isLandscape(value) ? value.aspectRatio : (1 / value.aspectRatio),
      child: child,
    );
  }

  static Widget _wrapInRotatedBox(CameraValue value, {required Widget child}) {
    if (kIsWeb) {
      return child;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return RotatedBox(
        quarterTurns: _getQuarterTurns(value),
        child: child,
      );
    }
    return child;
  }

  static bool _isLandscape(CameraValue value) {
    switch (_getApplicableOrientation(value)) {
      case DeviceOrientation.landscapeLeft:
      case DeviceOrientation.landscapeRight:
        return true;
      case DeviceOrientation.portraitUp:
      case DeviceOrientation.portraitDown:
        return false;
    }
  }

  static int _getQuarterTurns(CameraValue value) {
    switch (_getApplicableOrientation(value)) {
      case DeviceOrientation.portraitUp:
        return 1;
      case DeviceOrientation.landscapeRight:
        return 2;
      case DeviceOrientation.portraitDown:
        return 3;
      case DeviceOrientation.landscapeLeft:
        return 0;
    }
  }

  static DeviceOrientation _getApplicableOrientation(CameraValue value) =>
      value.recordingOrientation ??
      value.previewPauseOrientation ??
      value.lockedCaptureOrientation ??
      value.deviceOrientation;
}
