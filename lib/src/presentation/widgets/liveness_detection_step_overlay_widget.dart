import 'package:flutter/cupertino.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/presentation/widgets/circular_progress_widget/circular_progress_widget.dart';
import 'package:lottie/lottie.dart';

const List<String> _defaultTips = [
  'Position your face in the oval',
  'Look directly at the camera',
  'Ensure good lighting on your face',
  'Remove your glasses or mask',
];

const String _defaultTipsTitle = 'Tips for the best result';

class LivenessDetectionStepOverlayWidget extends StatefulWidget {
  final List<LivenessDetectionStepItem> steps;
  final VoidCallback onCompleted;
  final Widget camera;
  final CameraController? cameraController;
  final bool isFaceDetected;
  final bool showCurrentStep;
  final bool isDarkMode;
  final bool showDurationUiText;
  final int? duration;
  final bool showTips;
  final List<String>? tips;
  final String? tipsTitle;
  final String? title;

  const LivenessDetectionStepOverlayWidget({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.camera,
    required this.cameraController,
    required this.isFaceDetected,
    this.showCurrentStep = false,
    this.isDarkMode = true,
    this.showDurationUiText = false,
    this.duration,
    this.showTips = true,
    this.tips,
    this.tipsTitle,
    this.title,
  });

  @override
  State<LivenessDetectionStepOverlayWidget> createState() =>
      LivenessDetectionStepOverlayWidgetState();
}

class LivenessDetectionStepOverlayWidgetState
    extends State<LivenessDetectionStepOverlayWidget> {
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  int _currentIndex = 0;
  double _currentStepIndicator = 0;
  late final PageController _pageController;
  late CircularProgressWidget _circularProgressWidget;

  bool _pageViewVisible = false;
  Timer? _countdownTimer;
  int _remainingDuration = 0;

  static const double _indicatorMaxStep = 100;
  static const double _heightLine = 25;

  double _getStepIncrement(int stepLength) {
    return 100 / stepLength;
  }

  String get stepCounter => "$_currentIndex/${widget.steps.length}";

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _pageViewVisible = true;
      });
    });
    debugPrint('showCurrentStep ${widget.showCurrentStep}');
  }

  void _initializeControllers() {
    _pageController = PageController(initialPage: 0);
    _circularProgressWidget = _buildCircularIndicator();
  }

  void _initializeTimer() {
    if (widget.duration != null && widget.showDurationUiText) {
      _remainingDuration = widget.duration!;
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration > 0) {
        setState(() {
          _remainingDuration--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  CircularProgressWidget _buildCircularIndicator() {
    double scale = 1.0;
    if (widget.cameraController != null &&
        widget.cameraController!.value.isInitialized) {
      final cameraAspectRatio = widget.cameraController!.value.aspectRatio;
      const containerAspectRatio = 1.0;
      scale = cameraAspectRatio / containerAspectRatio;
      if (scale < 1.0) {
        scale = 1.0 / scale;
      }
    }

    return CircularProgressWidget(
      unselectedColor: Colors.grey,
      selectedColor: Colors.green,
      heightLine: _heightLine,
      current: _currentStepIndicator,
      maxStep: _indicatorMaxStep,
      child: Transform.scale(
        scale: scale,
        child: Center(child: widget.camera),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> nextPage() async {
    if (_isLoading) return;

    if (_currentIndex + 1 <= widget.steps.length - 1) {
      await _handleNextStep();
    } else {
      await _handleCompletion();
    }
  }

  Future<void> _handleNextStep() async {
    _showLoader();
    await Future.delayed(const Duration(milliseconds: 100));
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 1),
      curve: Curves.easeIn,
    );
    await Future.delayed(const Duration(seconds: 1));
    _hideLoader();
    _updateState();
  }

  Future<void> _handleCompletion() async {
    _updateState();
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onCompleted();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _currentIndex++;
        _currentStepIndicator += _getStepIncrement(widget.steps.length);
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void reset() {
    _pageController.jumpToPage(0);
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _currentStepIndicator = 0;
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void _showLoader() {
    if (mounted) setState(() => _isLoading = true);
  }

  void _hideLoader() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        height: double.infinity,
        width: double.infinity,
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    final title = widget.title ?? 'Face Verification';
    final textColor =
        widget.isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(CupertinoIcons.back, color: textColor, size: 28),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          widget.showCurrentStep
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showDurationUiText) ...[
                      Text(
                        _getRemainingTimeText(_remainingDuration),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      stepCounter,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                )
              : SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildCircularCamera(),
        _buildFaceDetectionStatus(),
        Visibility(
          visible: _pageViewVisible,
          replacement: const CircularProgressIndicator.adaptive(),
          child: _buildStepPageView(),
        ),
        if (widget.showTips) _buildTipsSection(),
        widget.isDarkMode ? _buildLoaderDarkMode() : _buildLoaderLightMode(),
      ],
    );
  }

  Widget _buildCircularCamera() {
    return SizedBox(
      height: 300,
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1000),
        child: _circularProgressWidget,
      ),
    );
  }

  String _getRemainingTimeText(int duration) {
    int minutes = duration ~/ 60;
    int seconds = duration % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildFaceDetectionStatus() {
    if (widget.isFaceDetected) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          child: widget.isDarkMode
              ? LottieBuilder.asset(
                  'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-id-anim.json',
                  height: 22,
                  width: 22,
                )
              : ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black,
                    BlendMode.modulate,
                  ),
                  child: LottieBuilder.asset(
                    'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-id-anim.json',
                    height: 22,
                    width: 22,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Text(
          'User Face Not Found...',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStepPageView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 10,
      width: MediaQuery.of(context).size.width,
      child: AbsorbPointer(
        absorbing: true,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.steps.length,
          itemBuilder: _buildStepItem,
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    final tipsList = widget.tips ?? _defaultTips;
    final title = widget.tipsTitle ?? _defaultTipsTitle;
    if (tipsList.isEmpty) return const SizedBox.shrink();

    final tipColor = Colors.black;
    final accentColor = Colors.deepOrange.shade700;

    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFDDAF59),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...tipsList.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: tipColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, int index) {
    final step = widget.steps[index];
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step.icon != null) ...[
              SizedBox(
                height: 28,
                width: 28,
                child: step.icon,
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Text(
                step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaderDarkMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: !_isLoading ? Colors.transparent : Colors.white,
      ),
    );
  }

  Widget _buildLoaderLightMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: _isLoading ? Colors.transparent : Colors.white,
      ),
    );
  }
}
