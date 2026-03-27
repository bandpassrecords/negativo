import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/film_roll.dart';
import '../services/film_service.dart';
import '../services/media_service.dart';

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

  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _frameCount = widget.filmRoll.exposureCount;
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
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
    if (_controller == null || !_cameraReady || _isShooting) return;
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
    } catch (_) {}

    // 4. Hold the black for a beat (film advancing feel).
    await Future.delayed(const Duration(milliseconds: 500));

    // 5. Fade the viewfinder back in slowly.
    if (mounted) {
      setState(() {
        _shutterClosed = false;
        _isShooting = false;
      });
    }

    if (widget.filmRoll.isFull && mounted) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) _showRollFullDialog();
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

  Widget _buildViewfinder() {
    final total = widget.filmRoll.capacity;
    final remaining = total - _frameCount;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Black background — user sees nothing ─────────────────
        const ColoredBox(color: Colors.black),

        // ── Subtle frame lines on black (composition guide) ──────
        const _FrameLines(),

        // ── Top HUD ─────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
        ),

        // Roll label
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 58),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    widget.filmRoll.name,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Bottom shutter bar ───────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (remaining <= 3 && remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        '$remaining frame${remaining == 1 ? '' : 's'} left',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  _ShutterButton(
                    onPressed: remaining > 0 && !_isShooting ? _shoot : null,
                    isShooting: _isShooting,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Shot confirmation flash ───────────────────────────────
        // A very brief white pulse so the user knows the shutter fired.
        if (_shutterClosed)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _shutterClosed ? 1.0 : 0.0,
              duration: Duration.zero,
              child: Container(
                color: Colors.white.withValues(alpha: 0.15),
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
// Overlays
// ─────────────────────────────────────────────────────────────────────────────

class _FrameLines extends StatelessWidget {
  const _FrameLines();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _FrameLinesPainter()),
    );
  }
}

class _FrameLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const margin = 32.0;
    const armLength = 22.0;

    // Corner frame marks
    final corners = [
      Offset(margin, margin),
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
    ];

    for (final c in corners) {
      final dx = c.dx < size.width / 2 ? armLength : -armLength;
      final dy = c.dy < size.height / 2 ? armLength : -armLength;
      canvas.drawLine(c, Offset(c.dx + dx, c.dy), paint);
      canvas.drawLine(c, Offset(c.dx, c.dy + dy), paint);
    }

    // Centre focus circle (rangefinder style)
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      28,
      circlePaint,
    );

    // Tiny centre dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
