// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/camerax_library.g.dart',
    dartTestOut: 'test/test_camerax_library.g.dart',
    dartOptions: DartOptions(copyrightHeader: <String>[
      'Copyright 2013 The Flutter Authors. All rights reserved.',
      'Use of this source code is governed by a BSD-style license that can be',
      'found in the LICENSE file.',
    ]),
    javaOut:
        'android/src/main/java/io/flutter/plugins/camerax/GeneratedCameraXLibrary.java',
    javaOptions: JavaOptions(
      package: 'io.flutter.plugins.camerax',
      className: 'GeneratedCameraXLibrary',
      copyrightHeader: <String>[
        'Copyright 2013 The Flutter Authors. All rights reserved.',
        'Use of this source code is governed by a BSD-style license that can be',
        'found in the LICENSE file.',
      ],
    ),
  ),
)
class ResolutionInfo {
  ResolutionInfo({
    required this.width,
    required this.height,
  });

  int width;
  int height;
}

class CameraPermissionsErrorData {
  CameraPermissionsErrorData({
    required this.errorCode,
    required this.description,
  });

  String errorCode;
  String description;
}

/// The states the camera can be in.
///
/// See https://developer.android.com/reference/androidx/camera/core/CameraState.Type.
enum CameraStateType {
  closed,
  closing,
  open,
  opening,
  pendingOpen,
}

class CameraStateTypeData {
  late CameraStateType value;
}

/// The types (T) properly wrapped to be used as a LiveData<T>.
///
/// If you need to add another type to support a type S to use a LiveData<S> in
/// this plugin, ensure the following is done on the Dart side:
///
///  * In `../lib/src/live_data.dart`, add new cases for S in
///    `_LiveDataHostApiImpl#getValueFromInstances` to get the current value of
///    type S from a LiveData<S> instance and in `LiveDataFlutterApiImpl#create`
///    to create the expected type of LiveData<S> when requested.
///
/// On the native side, ensure the following is done:
///
///  * Update `LiveDataHostApiImpl#getValue` is updated to properly return
///    identifiers for instances of type S.
///  * Update `ObserverFlutterApiWrapper#onChanged` to properly handle receiving
///    calls with instances of type S if a LiveData<S> instance is observed.
enum LiveDataSupportedType {
  cameraState,
  zoomState,
}

class LiveDataSupportedTypeData {
  late LiveDataSupportedType value;
}

class ExposureCompensationRange {
  ExposureCompensationRange({
    required this.minCompensation,
    required this.maxCompensation,
  });

  int minCompensation;
  int maxCompensation;
}

/// Video quality constraints that will be used by a QualitySelector to choose
/// an appropriate video resolution.
///
/// These are pre-defined quality constants that are universally used for video.
///
/// See https://developer.android.com/reference/androidx/camera/video/Quality.
enum VideoQuality {
  SD, // 480p
  HD, // 720p
  FHD, // 1080p
  UHD, // 2160p
  lowest,
  highest,
}

/// Convenience class for sending lists of [Quality]s.
class VideoQualityData {
  late VideoQuality quality;
}

/// Fallback rules for selecting video resolution.
///
/// See https://developer.android.com/reference/androidx/camera/video/FallbackStrategy.
enum VideoResolutionFallbackRule {
  higherQualityOrLowerThan,
  higherQualityThan,
  lowerQualityOrHigherThan,
  lowerQualityThan,
}

@HostApi(dartHostTestHandler: 'TestInstanceManagerHostApi')
abstract class InstanceManagerHostApi {
  /// Clear the native `InstanceManager`.
  ///
  /// This is typically only used after a hot restart.
  void clear();
}

@HostApi(dartHostTestHandler: 'TestJavaObjectHostApi')
abstract class JavaObjectHostApi {
  void dispose(int identifier);
}

@FlutterApi()
abstract class JavaObjectFlutterApi {
  void dispose(int identifier);
}

@HostApi(dartHostTestHandler: 'TestCameraInfoHostApi')
abstract class CameraInfoHostApi {
  int getSensorRotationDegrees(int identifier);

  int getCameraState(int identifier);

  int getExposureState(int identifier);

  int getZoomState(int identifier);
}

@FlutterApi()
abstract class CameraInfoFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestCameraSelectorHostApi')
abstract class CameraSelectorHostApi {
  void create(int identifier, int? lensFacing);

  List<int> filter(int identifier, List<int> cameraInfoIds);
}

@FlutterApi()
abstract class CameraSelectorFlutterApi {
  void create(int identifier, int? lensFacing);
}

@HostApi(dartHostTestHandler: 'TestProcessCameraProviderHostApi')
abstract class ProcessCameraProviderHostApi {
  @async
  int getInstance();

  List<int> getAvailableCameraInfos(int identifier);

  int bindToLifecycle(
      int identifier, int cameraSelectorIdentifier, List<int> useCaseIds);

  bool isBound(int identifier, int useCaseIdentifier);

  void unbind(int identifier, List<int> useCaseIds);

  void unbindAll(int identifier);
}

@FlutterApi()
abstract class ProcessCameraProviderFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestCameraHostApi')
abstract class CameraHostApi {
  int getCameraInfo(int identifier);

  int getCameraControl(int identifier);
}

@FlutterApi()
abstract class CameraFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestSystemServicesHostApi')
abstract class SystemServicesHostApi {
  @async
  CameraPermissionsErrorData? requestCameraPermissions(bool enableAudio);

  String getTempFilePath(String prefix, String suffix);
}

@FlutterApi()
abstract class SystemServicesFlutterApi {
  void onCameraError(String errorDescription);
}

@HostApi(dartHostTestHandler: 'TestDeviceOrientationManagerHostApi')
abstract class DeviceOrientationManagerHostApi {
  void startListeningForDeviceOrientationChange(
      bool isFrontFacing, int sensorOrientation);

  void stopListeningForDeviceOrientationChange();

  int getDefaultDisplayRotation();
}

@FlutterApi()
abstract class DeviceOrientationManagerFlutterApi {
  void onDeviceOrientationChanged(String orientation);
}

@HostApi(dartHostTestHandler: 'TestPreviewHostApi')
abstract class PreviewHostApi {
  void create(int identifier, int? rotation, int? resolutionSelectorId);

  int setSurfaceProvider(int identifier);

  void releaseFlutterSurfaceTexture();

  ResolutionInfo getResolutionInfo(int identifier);

  void setTargetRotation(int identifier, int rotation);
}

@HostApi(dartHostTestHandler: 'TestVideoCaptureHostApi')
abstract class VideoCaptureHostApi {
  int withOutput(int videoOutputId);

  int getOutput(int identifier);

  void setTargetRotation(int identifier, int rotation);
}

@FlutterApi()
abstract class VideoCaptureFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestRecorderHostApi')
abstract class RecorderHostApi {
  void create(
      int identifier, int? aspectRatio, int? bitRate, int? qualitySelectorId);

  int getAspectRatio(int identifier);

  int getTargetVideoEncodingBitRate(int identifier);

  int prepareRecording(int identifier, String path);
}

@FlutterApi()
abstract class RecorderFlutterApi {
  void create(int identifier, int? aspectRatio, int? bitRate);
}

@HostApi(dartHostTestHandler: 'TestPendingRecordingHostApi')
abstract class PendingRecordingHostApi {
  int start(int identifier);
}

@FlutterApi()
abstract class PendingRecordingFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestRecordingHostApi')
abstract class RecordingHostApi {
  void close(int identifier);

  void pause(int identifier);

  void resume(int identifier);

  void stop(int identifier);
}

@FlutterApi()
abstract class RecordingFlutterApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestImageCaptureHostApi')
abstract class ImageCaptureHostApi {
  void create(int identifier, int? targetRotation, int? flashMode,
      int? resolutionSelectorId);

  void setFlashMode(int identifier, int flashMode);

  @async
  String takePicture(int identifier);

  void setTargetRotation(int identifier, int rotation);
}

@HostApi(dartHostTestHandler: 'TestResolutionStrategyHostApi')
abstract class ResolutionStrategyHostApi {
  void create(int identifier, ResolutionInfo? boundSize, int? fallbackRule);
}

@HostApi(dartHostTestHandler: 'TestResolutionSelectorHostApi')
abstract class ResolutionSelectorHostApi {
  void create(
    int identifier,
    int? resolutionStrategyIdentifier,
    int? aspectRatioStrategyIdentifier,
  );
}

@HostApi(dartHostTestHandler: 'TestAspectRatioStrategyHostApi')
abstract class AspectRatioStrategyHostApi {
  void create(int identifier, int preferredAspectRatio, int fallbackRule);
}

@FlutterApi()
abstract class CameraStateFlutterApi {
  void create(int identifier, CameraStateTypeData type, int? errorIdentifier);
}

@FlutterApi()
abstract class ExposureStateFlutterApi {
  void create(
      int identifier,
      ExposureCompensationRange exposureCompensationRange,
      double exposureCompensationStep);
}

@FlutterApi()
abstract class ZoomStateFlutterApi {
  void create(int identifier, double minZoomRatio, double maxZoomRatio);
}

@HostApi(dartHostTestHandler: 'TestImageAnalysisHostApi')
abstract class ImageAnalysisHostApi {
  void create(int identifier, int? targetRotation, int? resolutionSelectorId);

  void setAnalyzer(int identifier, int analyzerIdentifier);

  void clearAnalyzer(int identifier);

  void setTargetRotation(int identifier, int rotation);
}

@HostApi(dartHostTestHandler: 'TestAnalyzerHostApi')
abstract class AnalyzerHostApi {
  void create(int identifier);
}

@HostApi(dartHostTestHandler: 'TestObserverHostApi')
abstract class ObserverHostApi {
  void create(int identifier);
}

@FlutterApi()
abstract class ObserverFlutterApi {
  void onChanged(int identifier, int valueIdentifier);
}

@FlutterApi()
abstract class CameraStateErrorFlutterApi {
  void create(int identifier, int code);
}

@HostApi(dartHostTestHandler: 'TestLiveDataHostApi')
abstract class LiveDataHostApi {
  void observe(int identifier, int observerIdentifier);

  void removeObservers(int identifier);

  int? getValue(int identifier, LiveDataSupportedTypeData type);
}

@FlutterApi()
abstract class LiveDataFlutterApi {
  void create(int identifier, LiveDataSupportedTypeData type);
}

@FlutterApi()
abstract class AnalyzerFlutterApi {
  void create(int identifier);

  void analyze(int identifier, int imageProxyIdentifier);
}

@HostApi(dartHostTestHandler: 'TestImageProxyHostApi')
abstract class ImageProxyHostApi {
  List<int> getPlanes(int identifier);

  void close(int identifier);
}

@FlutterApi()
abstract class ImageProxyFlutterApi {
  void create(int identifier, int format, int height, int width);
}

@FlutterApi()
abstract class PlaneProxyFlutterApi {
  void create(int identifier, Uint8List buffer, int pixelStride, int rowStride);
}

@HostApi(dartHostTestHandler: 'TestQualitySelectorHostApi')
abstract class QualitySelectorHostApi {
  void create(int identifier, List<VideoQualityData> videoQualityDataList,
      int? fallbackStrategyId);

  ResolutionInfo getResolution(int cameraInfoId, VideoQuality quality);
}

@HostApi(dartHostTestHandler: 'TestFallbackStrategyHostApi')
abstract class FallbackStrategyHostApi {
  void create(int identifier, VideoQuality quality,
      VideoResolutionFallbackRule fallbackRule);
}

@HostApi(dartHostTestHandler: 'TestCameraControlHostApi')
abstract class CameraControlHostApi {
  @async
  void enableTorch(int identifier, bool torch);

  @async
  void setZoomRatio(int identifier, double ratio);
}

@FlutterApi()
abstract class CameraControlFlutterApi {
  void create(int identifier);
}
