import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/film_roll.dart';
import '../services/film_service.dart';
import '../services/media_service.dart';
import '../services/scoring_service.dart';

class ViewfinderScreen extends StatefulWidget {
  final FilmRoll filmRoll;

  const ViewfinderScreen({super.key, required this.filmRoll});

  @override
  State<ViewfinderScreen> createState() => _ViewfinderScreenState();
}

class _ViewfinderScreenState extends State<ViewfinderScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  bool _isShooting = false;

  /// When true the viewfinder shows a full blackout (shutter closed / film advancing).
  bool _shutterClosed = false;
  bool _needsWinding = true;

  int _frameCount = 0;
  String? _pointsOverlayText;
  int _chipGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    _frameCount = widget.filmRoll.exposureCount;
    // Unlock all orientations for the viewfinder
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initCamera();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    // Re-lock to portrait when leaving the viewfinder
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
            event.logicalKey == LogicalKeyboardKey.audioVolumeDown)) {
      _shoot();
      return true; // consume — prevents system volume change
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _permissionDenied = false);
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _shoot() async {
    if (_controller == null || !_cameraReady || _isShooting || _needsWinding) return;
    if (widget.filmRoll.isFull) return;

    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // 1. Go black instantly — user can no longer see anything.
    setState(() {
      _isShooting = true;
      _shutterClosed = true;
    });

    // 2. Wait for the black frame to actually be rendered before shooting,
    //    so the captured image is never visible on screen.
    await Future.delayed(const Duration(milliseconds: 80));

    // 3. Capture while the screen is completely dark.
    try {
      final image = await _controller!.takePicture();
      final savedPath = await MediaService.copyToAppDirectory(image.path);
      await FilmService.addExposure(widget.filmRoll, savedPath);
      setState(() => _frameCount = widget.filmRoll.exposureCount);
      int earned = ScoringService.ptsPerPhoto;
      await ScoringService.addPoints(earned);
      if (widget.filmRoll.isFull) {
        earned += ScoringService.ptsFullRoll;
        await ScoringService.addPoints(ScoringService.ptsFullRoll);
      }
      _showPointsChip('+$earned pts');
    } catch (_) {}

    // 4. Hold the black for a beat (film advancing feel).
    await Future.delayed(const Duration(milliseconds: 500));

    // 5. Fade the viewfinder back in slowly.
    if (mounted) {
      setState(() {
        _shutterClosed = false;
        _isShooting = false;
        _needsWinding = true; // must wind before next shot
      });
    }

    if (widget.filmRoll.isFull && mounted) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) _showRollFullDialog();
    }
  }

  void _showPointsChip(String text) {
    _chipGeneration++;
    final gen = _chipGeneration;
    setState(() => _pointsOverlayText = text);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _chipGeneration == gen) {
        setState(() => _pointsOverlayText = null);
      }
    });
  }

  Future<void> _onWindingComplete(double seconds) async {
    setState(() => _needsWinding = false);
    final bonus = ScoringService.windBonus(seconds);
    if (bonus > 0) {
      await ScoringService.addPoints(bonus);
      final label = ScoringService.windBonusLabel(bonus);
      if (mounted) _showPointsChip('$label  +$bonus pts');
    } else {
      // Still show feedback so the user knows the mechanic
      final d = (seconds - ScoringService.windTarget).abs();
      final hint = d < ScoringService.windTarget
          ? 'Wind slower — target 0.8s'
          : 'Wind faster — target 0.8s';
      if (mounted) _showPointsChip(hint);
    }
  }

  void _showRollFullDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Roll is full!'),
        content: Text(
          'You\'ve used all ${widget.filmRoll.capacity} frames on '
          '"${widget.filmRoll.name}". Ready to send it for development?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FilmService.startDevelopment(widget.filmRoll);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Develop Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _permissionDenied
          ? _buildPermissionDenied()
          : !_cameraReady
              ? _buildLoading()
              : _buildViewfinder(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white54),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              'Camera access required',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enable camera access in Settings to use the viewfinder.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinderWindow({bool landscape = false}) {
    final double innerW = landscape ? 150.0 : 88.0;
    final double innerH = landscape ? 112.0 : 117.0;

    return Container(
      // Outer eyepiece housing — the camera body rim
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(landscape ? 18 : 14),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 2),
        boxShadow: [
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            spreadRadius: 6,
          ),
          // Top highlight — simulates the curved glass catching light
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: innerW,
        height: innerH,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(landscape ? 8 : 5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Live camera feed
              CameraPreview(_controller!),

              // Warm amber glass tint — real viewfinder glass has a slight cast
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.amber.withValues(alpha: 0.06),
                ),
              ),

              // Strong circular vignette — the "looking through an eyepiece" feel
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Glass reflection — subtle streak across the top third
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.3,
                    widthFactor: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.09),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Blackout during shot
              AnimatedOpacity(
                opacity: _shutterClosed ? 1.0 : 0.0,
                duration: _shutterClosed
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                child: const ColoredBox(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    final total = widget.filmRoll.capacity;
    final remaining = total - _frameCount;

    final windLever = _WindLever(onComplete: _onWindingComplete);

    final shutterButton = _ShutterButton(
      onPressed: remaining > 0 && !_isShooting && !_needsWinding ? _shoot : null,
      isShooting: _isShooting,
    );

    final lowFramesLabel = remaining <= 3 && remaining > 0
        ? Text(
            '$remaining frame${remaining == 1 ? '' : 's'} left',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          )
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: SafeArea(
            child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              // ── Landscape: LayoutBuilder + Stack for % positioning ──
              return LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    // Content: HUD full-width, viewfinder + name left-aligned
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                _HudButton(
                                  icon: Icons.arrow_back,
                                  onTap: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                _FrameCounter(current: _frameCount, total: total),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: constraints.maxWidth * 0.20),
                          child: _buildViewfinderWindow(landscape: true),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.only(left: constraints.maxWidth * 0.20),
                          child: Text(
                            widget.filmRoll.name,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Lever — 60% from left, 40% from bottom
                    if (_needsWinding)
                      Positioned(
                        left: constraints.maxWidth * 0.55,
                        bottom: constraints.maxHeight * 0.20,
                        child: SizedBox(
                          width: 170,
                          child: windLever,
                        ),
                      ),

                    // Shutter — same position as lever start
                    if (!_needsWinding)
                      Positioned(
                        left: constraints.maxWidth * 0.55,
                        bottom: constraints.maxHeight * 0.20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (lowFramesLabel != null) ...[
                              lowFramesLabel,
                              const SizedBox(height: 12),
                            ],
                            shutterButton,
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }

            // ── Portrait: shutter pinned to the bottom ─────────────
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      _HudButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _FrameCounter(current: _frameCount, total: total),
                    ],
                  ),
                ),

                // Viewfinder top-centre
                Center(child: _buildViewfinderWindow()),

                // Roll name
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.filmRoll.name,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                // Push shutter to the bottom
                const Spacer(),

                // Wind lever or shutter bar
                if (_needsWinding)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 72, right: 40),
                    child: Align(
                      alignment: const Alignment(-0.3, 0),
                      child: SizedBox(
                        width: 170,
                        child: windLever,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36, left: 32, right: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (lowFramesLabel != null) ...[
                          lowFramesLabel,
                          const SizedBox(height: 14),
                        ],
                        shutterButton,
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
        // Points overlay — floats above everything
        if (_pointsOverlayText != null)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _pointsOverlayText!.startsWith('+')
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _pointsOverlayText!.startsWith('+')
                        ? Colors.amber.withValues(alpha: 0.5)
                        : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Text(
                  _pointsOverlayText!,
                  style: TextStyle(
                    color: _pointsOverlayText!.startsWith('+')
                        ? Colors.amber
                        : Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _FrameCounter extends StatelessWidget {
  final int current;
  final int total;

  const _FrameCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$current',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            ' / $total',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wind lever
// ─────────────────────────────────────────────────────────────────────────────

class _WindLever extends StatefulWidget {
  final void Function(double seconds) onComplete;
  const _WindLever({required this.onComplete});

  @override
  State<_WindLever> createState() => _WindLeverState();
}

class _WindLeverState extends State<_WindLever> {
  double _progress = 0.0;
  bool _completed = false;
  int _lastTick = 0;
  DateTime? _windStartTime;

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_completed) return;
    _windStartTime ??= DateTime.now();
    setState(() {
      _progress = (_progress + details.delta.dx / trackWidth).clamp(0.0, 1.0);
    });

    // Only vibrate when dragging right AND at a position never reached before
    if (details.delta.dx > 0) {
      final tick = (_progress * 8).floor();
      if (tick > _lastTick) {
        _lastTick = tick;
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      }
    }

    if (_progress >= 1.0 && !_completed) {
      _completed = true;
      _onWindComplete();
    }
  }

  Future<void> _onWindComplete() async {
    final seconds = _windStartTime == null
        ? 999.0
        : DateTime.now().difference(_windStartTime!).inMilliseconds / 1000.0;
    // Three rapid clicks — the final ratchet locking sound
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: i * 55));
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
    widget.onComplete(seconds);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_completed) return;
    // Snap back if not fully wound
    setState(() {
      _progress = 0.0;
      _lastTick = 0;
      _windStartTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 220.0;

        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
          onHorizontalDragEnd: _onDragEnd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Text(
                _completed ? 'READY' : 'WIND FILM',
                style: TextStyle(
                  color: _completed ? Colors.amber : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 10),
              // Track
              SizedBox(
                width: trackWidth,
                height: 44,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Track background
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: (_progress * (trackWidth - 44)).clamp(0.0, trackWidth - 44),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _completed ? Colors.amber : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: _completed ? Colors.black : Colors.black54,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shutter button
// ─────────────────────────────────────────────────────────────────────────────

class _ShutterButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isShooting;

  const _ShutterButton({required this.onPressed, required this.isShooting});

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (widget.onPressed == null) return;
    await _anim.forward();
    await _anim.reverse();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isShooting ? null : _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.onPressed == null ? Colors.white24 : Colors.white,
            border: Border.all(color: Colors.white38, width: 3),
          ),
        ),
      ),
    );
  }
}
