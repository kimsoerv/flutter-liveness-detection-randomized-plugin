import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/localization/liveness_localizations.dart';

class LivenessDetectionTutorialScreen extends StatefulWidget {
  final VoidCallback onStartTap;
  final bool isDarkMode;
  final int? duration;
  final String languageCode;
  const LivenessDetectionTutorialScreen(
      {super.key,
      required this.onStartTap,
      this.isDarkMode = false,
      required this.duration,
      this.languageCode = 'en'});

  @override
  State<LivenessDetectionTutorialScreen> createState() =>
      _LivenessDetectionTutorialScreenState();
}

class _LivenessDetectionTutorialScreenState
    extends State<LivenessDetectionTutorialScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LivenessLocalizations.of(widget.languageCode);
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const SizedBox(
              height: 16,
            ),
            Text(
              strings.tutorialTitle(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(
              height: 32,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: widget.isDarkMode ? Colors.black87 : Colors.white,
                boxShadow: !widget.isDarkMode
                    ? [
                        BoxShadow(
                          color: Colors.grey.withAlpha(51),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Text(
                      '1',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    subtitle: Text(
                      strings.tutorialSufficientLightingDescription(),
                      style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    title: Text(
                      strings.tutorialSufficientLightingTitle(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  ListTile(
                    leading: Text(
                      '2',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    subtitle: Text(
                      strings.tutorialStraightAheadDescription(),
                      style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    title: Text(
                      strings.tutorialStraightAheadTitle(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  ListTile(
                    leading: Text(
                      '3',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    subtitle: Text(
                      strings.tutorialTimeLimitDescription(
                        widget.duration ?? 45,
                      ),
                      style: TextStyle(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                    title: Text(
                      strings.tutorialTimeLimitTitle(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.isDarkMode ? Colors.black87 : Colors.white,
                foregroundColor:
                    widget.isDarkMode ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () => widget.onStartTap(),
              label: Text(strings.tutorialStartButton()),
            ),
            const SizedBox(
              height: 10,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey,
                  size: 15,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  strings.packageVersionLabel('1.1.0'),
                  style: const TextStyle(color: Colors.grey),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
