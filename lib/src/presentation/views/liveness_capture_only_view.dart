// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class LivenessCaptureOnlyView extends StatefulWidget {
  final LivenessDetectionConfig config;

  const LivenessCaptureOnlyView({super.key, required this.config});

  @override
  State<LivenessCaptureOnlyView> createState() => _LivenessCaptureOnlyViewState();
}

class _LivenessCaptureOnlyViewState extends State<LivenessCaptureOnlyView> {
  CameraController? _cameraController;
  int _cameraIndex = 0;
  bool _isTakingPicture = false;
  bool _isInitializing = true;
  XFile? _capturedImage;

  Future<void> setApplicationBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(
        brightness,
      );
    } catch (e) {
      throw 'Failed to set application brightness';
    }
  }

  Future<void> resetApplicationBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      throw 'Failed to reset application brightness';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.config.isEnableMaxBrightness) {
      setApplicationBrightness(1.0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    if (widget.config.isEnableMaxBrightness) {
      resetApplicationBrightness();
    }
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop(null);
        return;
      }

      if (cameras.any(
        (element) =>
            element.lensDirection == CameraLensDirection.front &&
            element.sensorOrientation == 90,
      )) {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) =>
                element.lensDirection == CameraLensDirection.front &&
                element.sensorOrientation == 90,
          ),
        );
      } else {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) => element.lensDirection == CameraLensDirection.front,
          ),
        );
      }

      final camera = cameras[_cameraIndex];
      _cameraController = CameraController(
        camera,
        widget.config.cameraResolution,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController?.initialize();
      if (!mounted) return;
      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      Navigator.of(context).pop(null);
    }
  }

  Future<XFile?> _compressImage(XFile originalFile) async {
    final int quality = widget.config.imageQuality;

    if (quality >= 100) {
      return originalFile;
    }

    try {
      final bytes = await originalFile.readAsBytes();

      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        return originalFile;
      }

      final tempDir = await getTemporaryDirectory();
      final String targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedBytes = img.encodeJpg(originalImage, quality: quality);

      final File compressedFile = await File(
        targetPath,
      ).writeAsBytes(compressedBytes);

      return XFile(compressedFile.path);
    } catch (e) {
      debugPrint("Error compressing image: $e");
      return originalFile;
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_cameraController == null || _isTakingPicture) return;
      setState(() => _isTakingPicture = true);

      final XFile? clickedImage = await _cameraController?.takePicture();
      if (clickedImage == null) {
        if (mounted) setState(() => _isTakingPicture = false);
        return;
      }

      final XFile? finalImage = await _compressImage(clickedImage);
      if (!mounted) return;
      setState(() {
        _capturedImage = finalImage;
        _isTakingPicture = false;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.config.backgroundColor ??
        (widget.config.isDarkMode ? Colors.black : const Color(0xFFF7F7F7));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isInitializing ||
              _cameraController == null ||
              _cameraController?.value.isInitialized == false
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Stack(
              children: [
                if (_capturedImage == null)
                  CameraPreview(_cameraController!)
                else
                  Positioned.fill(
                    child: Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned(
                  left: 16,
                  top: 40,
                  child: IconButton(
                    onPressed: () {
                      if (_capturedImage != null) {
                        setState(() => _capturedImage = null);
                      } else {
                        Navigator.of(context).pop(null);
                      }
                    },
                    icon: Icon(
                      Icons.close,
                      color: widget.config.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: Center(
                    child: _capturedImage == null
                        ? GestureDetector(
                            onTap: _isTakingPicture ? null : _takePicture,
                            child: Container(
                              height: 72,
                              width: 72,
                              decoration: BoxDecoration(
                                color: _isTakingPicture
                                    ? Colors.grey
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12, width: 2),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _capturedImage = null);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Retake'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(_capturedImage?.path);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
