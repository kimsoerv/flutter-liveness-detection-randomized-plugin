import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/localization/liveness_localizations.dart';

enum LivenessBottomSheetInfoType { manyAttempts, blocked, locked}

class _RetryCountdownText extends StatefulWidget {
  const _RetryCountdownText({
    required this.initialRemaining,
    required this.languageCode,
    this.onResult,
  });

  final Duration initialRemaining;
  final String languageCode;
  final Function(bool isCountZero)? onResult;

  @override
  State<_RetryCountdownText> createState() => _RetryCountdownTextState();
}

class _RetryCountdownTextState extends State<_RetryCountdownText> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialRemaining;
    if (_remaining.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.onResult == null) return;
        widget.onResult!(true);
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        final next = _remaining - const Duration(seconds: 1);
        _remaining = next.isNegative ? Duration.zero : next;
        if (_remaining.inSeconds <= 0) {
          widget.onResult!(true);
        } else {
          widget.onResult!(false);
        }
      });
      if (_remaining.inSeconds <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final strings = LivenessLocalizations.of(widget.languageCode);
    return Text(
      strings.retryIn(_format(_remaining)),
      style: const TextStyle(
        color: Color(0xFFE60013),
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}

class LivenessBottomSheetInfoWidget extends StatefulWidget {
  const LivenessBottomSheetInfoWidget({
    super.key,
    required this.title,
    required this.message,
    required this.languageCode,
    this.icon,
    this.badgeText,
    this.countdownDuration,
    this.primaryActionText,
    this.onPrimaryAction,
    this.colorByType,
    this.isEnableActionTryAgain,
    this.primaryColor = Colors.black,
  });

  final Widget? icon;
  final String title;
  final String message;
  final String languageCode;
  final String? badgeText;
  final Duration? countdownDuration;
  final Color? colorByType;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final bool? isEnableActionTryAgain;
  final Color primaryColor;

  factory LivenessBottomSheetInfoWidget.forType({
    Key? key,
    required LivenessBottomSheetInfoType type,
    required bool isDarkMode,
    String? languageCode,
    String? formattedWaitTime,
    String? attemptsLeftText,
    Duration? countdownDuration,
    VoidCallback? onTryAgain,
    Widget? icon,
    Color primaryColor = Colors.black,
  }) {
    final strings = LivenessLocalizations.of(languageCode);
    switch (type) {
      case LivenessBottomSheetInfoType.manyAttempts:
        return LivenessBottomSheetInfoWidget(
          key: key,
          title: strings.scanTimedOutTitle(),
          message: strings.scanTimedOutMessage(),
          languageCode: strings.languageCode,
          badgeText: attemptsLeftText,
          colorByType: const Color(0xFFDDAF59),
          icon: icon,
          primaryActionText: strings.tryAgain(),
          onPrimaryAction: onTryAgain,
          isEnableActionTryAgain: true,
          primaryColor: primaryColor,
        );
      case LivenessBottomSheetInfoType.locked:
        final wait = formattedWaitTime ?? "5:00";
        final waitWithSuffix = wait.endsWith('s') ? wait : '${wait}s';
        return LivenessBottomSheetInfoWidget(
          key: key,
          title: strings.temporarilyBlockedTitle(),
          message: strings.temporarilyLockedMessage(waitWithSuffix),
          languageCode: strings.languageCode,
          countdownDuration: countdownDuration ?? Duration.zero,
          colorByType: const Color(0xFFE60013).withOpacity(0.10),
          icon: icon,
          primaryActionText: strings.tryAgain(),
          onPrimaryAction: onTryAgain,
          isEnableActionTryAgain: false,
          primaryColor: primaryColor,
        );
      case LivenessBottomSheetInfoType.blocked:
        return LivenessBottomSheetInfoWidget(
          key: key,
          title: strings.temporarilyBlockedTitle(),
          message: strings.temporarilyBlockedMessage(),
          languageCode: strings.languageCode,
          countdownDuration: countdownDuration ?? Duration.zero,
          colorByType: const Color(0xFFE60013).withOpacity(0.10),
          icon: icon,
          primaryActionText: strings.tryAgain(),
          onPrimaryAction: onTryAgain,
          isEnableActionTryAgain: false,
          primaryColor: primaryColor,
        );
    }
  }

  @override
  State<LivenessBottomSheetInfoWidget> createState() => _LivenessBottomSheetInfoWidgetState();
}

class _LivenessBottomSheetInfoWidgetState extends State<LivenessBottomSheetInfoWidget> {
  bool isEnableAction = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      isEnableAction = widget.isEnableActionTryAgain ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: widget.icon,
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.badgeText != null && widget.badgeText!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.colorByType?.withOpacity(0.1) ??
                        const Color(0xFFDDAF59),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badgeText!,
                    style: TextStyle(
                      color: widget.colorByType,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              if (widget.countdownDuration != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.colorByType?.withOpacity(0.1) ??
                        const Color(0xFF00131A).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _RetryCountdownText(
                    initialRemaining: widget.countdownDuration!,
                    languageCode: widget.languageCode,
                    onResult: (isCountZero) {
                     setState(() {
                       isEnableAction = isCountZero;
                     });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: Opacity(
                  opacity: isEnableAction ? 1 : 0.2,
                  child: OutlinedButton(
                    onPressed: !isEnableAction
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                            widget.onPrimaryAction?.call();
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: widget.primaryColor,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.primaryActionText ??
                          LivenessLocalizations.of(widget.languageCode).ok(),
                      style: TextStyle(color: widget.primaryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
