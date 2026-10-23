import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'about_page.dart';

void main() {
  runApp(const VolWakeApp());
}

class VolWakeApp extends StatelessWidget {
  const VolWakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolWake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D2FF),
          surface: Color(0xFF161B30),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _channel = MethodChannel('com.example.volumewake/settings');

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real-time device state
  Map<String, dynamic> _deviceInfo = {
    'manufacturer': 'Android',
    'brand': '',
    'model': '',
    'androidRelease': '',
    'sdkInt': 0,
    'oemCategory': 'stock',
    'romDescription': 'Android Device',
    'isAccessibilityEnabled': false,
    'isBatteryOptimizationIgnored': false,
    'canDrawOverlays': true,
  };

  bool _isTestingWake = false;
  int _testCountdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchDeviceInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Refresh status when returning from Android Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchDeviceInfo();
    }
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      if (info != null && mounted) {
        setState(() {
          _deviceInfo = info;
        });
      }
    } catch (_) {}
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } on PlatformException catch (e) {
      _showToast('Could not open accessibility settings: ${e.message}', isError: true);
    }
  }

  Future<void> _openOemAutostart() async {
    try {
      final success = await _channel.invokeMethod<bool>('openOemAutostart') ?? false;
      if (!success) {
        _showToast('Opened app settings. Please check background/autostart permissions.');
      }
    } on PlatformException catch (e) {
      _showToast('Failed to open autostart settings: ${e.message}', isError: true);
    }
  }

  Future<void> _openBatteryOptimization() async {
    try {
      await _channel.invokeMethod('openBatteryOptimization');
    } on PlatformException catch (e) {
      _showToast('Failed to open battery settings: ${e.message}', isError: true);
    }
  }

  void _testScreenWake() {
    if (_isTestingWake) return;

    setState(() {
      _isTestingWake = true;
      _testCountdown = 3;
    });

    _channel.invokeMethod('testWakeScreen');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_testCountdown > 1) {
          _testCountdown--;
        } else {
          _isTestingWake = false;
          timer.cancel();
          _showToast('Screen wake command sent! ☀️');
        }
      });
    });
  }

  void _navigateToAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutPage()),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6C63FF),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isServiceActive = _deviceInfo['isAccessibilityEnabled'] as bool? ?? false;
    final bool isBatteryIgnored = _deviceInfo['isBatteryOptimizationIgnored'] as bool? ?? false;
    final String androidRelease = _deviceInfo['androidRelease'] as String? ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF13172E),
              Color(0xFF1B1140),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = constraints.maxWidth > 600 ? 32 : 20;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header with About Navigation ──
                        _buildHeader(androidRelease),
                        const SizedBox(height: 24),

                        // ── Hero Wake Button ──
                        _buildHeroButton(isServiceActive),
                        const SizedBox(height: 28),

                        // ── Live Status Dashboard Card ──
                        _buildStatusDashboardCard(isServiceActive, isBatteryIgnored),
                        const SizedBox(height: 18),

                        // ── Android Device Compatibility Settings Card ──
                        _buildDeviceCompatibilityCard(),
                        const SizedBox(height: 18),

                        // ── Test Screen Wake Card ──
                        _buildTestWakeCard(),
                        const SizedBox(height: 18),

                        // ── Universal Android Setup & Permission Guide ──
                        _buildAndroidGuideCard(),
                        const SizedBox(height: 18),

                        // ── Dedicated About VolWake Access Card ──
                        _buildAboutAccessCard(),
                        const SizedBox(height: 18),

                        // ── Android Architecture & Compatibility Info ──
                        _buildArchitectureInfoCard(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────── Header with About Action ───────────────
  Widget _buildHeader(String androidRelease) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D2FF).withAlpha(70),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/logo.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'VolWake',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00D2FF).withAlpha(60)),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00D2FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                androidRelease.isNotEmpty
                    ? 'Android Phones (Android $androidRelease) • Volume Key Wake'
                    : 'Android Phones • Volume Key Screen Wake',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(160),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Prominent About Button
        Tooltip(
          message: 'About VolWake',
          child: TextButton.icon(
            onPressed: _navigateToAboutPage,
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00D2FF), size: 18),
            label: const Text(
              'About',
              style: TextStyle(
                color: Color(0xFF00D2FF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(12),
              side: BorderSide(color: const Color(0xFF00D2FF).withAlpha(60)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── Hero Button ───────────────
  Widget _buildHeroButton(bool isServiceActive) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isServiceActive ? 1.0 : _pulseAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: _openAccessibilitySettings,
          child: Container(
            width: 185,
            height: 185,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isServiceActive
                    ? [const Color(0xFF00E676), const Color(0xFF00B0FF), const Color(0xFF1B5E20)]
                    : [const Color(0xFF7B73FF), const Color(0xFF6C63FF), const Color(0xFF4B42D4)],
                stops: const [0.0, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isServiceActive ? const Color(0xFF00E676) : const Color(0xFF6C63FF)).withAlpha(90),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF00D2FF).withAlpha(35),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isServiceActive)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.black),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  isServiceActive ? 'ACTIVE' : 'ENABLE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  isServiceActive ? 'Accessibility is ON' : 'Tap for Accessibility',
                  style: TextStyle(
                    color: Colors.white.withAlpha(190),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── Live Status Dashboard Card ───────────────
  Widget _buildStatusDashboardCard(bool isServiceActive, bool isBatteryIgnored) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Service Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: _fetchDeviceInfo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF00D2FF)),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(fontSize: 11, color: Color(0xFF00D2FF), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Indicator 1: Accessibility Service
          _StatusRow(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility Service',
            subtitle: isServiceActive
                ? 'Connected & listening for volume keys'
                : 'Disabled — tap ENABLE button to turn on in settings',
            isActive: isServiceActive,
            actionLabel: isServiceActive ? null : 'Enable',
            onAction: _openAccessibilitySettings,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // Indicator 2: Battery Optimization
          _StatusRow(
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery Optimization',
            subtitle: isBatteryIgnored
                ? 'Unrestricted (exempt from background sleep)'
                : 'Optimized (Android may sleep service during long standby)',
            isActive: isBatteryIgnored,
            actionLabel: isBatteryIgnored ? null : 'Unrestrict',
            onAction: _openBatteryOptimization,
          ),
        ],
      ),
    );
  }

  // ─────────────── Android Device Compatibility Card ───────────────
  Widget _buildDeviceCompatibilityCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D2FF).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF00D2FF), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Android Device Compatibility',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Background & Battery Settings for Android Phones',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'To allow physical volume keys to wake your screen while it is locked or turned off, Android requires background autostart and battery optimization exemptions. This prevents the operating system from suspending the background service.',
            style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(190), height: 1.4),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _openOemAutostart,
                icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                label: const Text('Background Autostart', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openBatteryOptimization,
                icon: const Icon(Icons.battery_alert_rounded, size: 15),
                label: const Text('Battery Settings', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00D2FF),
                  side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amberAccent.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Lock VolWake in your phone\'s Recent Apps screen (swipe down or tap the menu on the app card and select the padlock icon) so the Android memory manager keeps it running.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(190), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Test Screen Wake Card ───────────────
  Widget _buildTestWakeCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFF00D2FF), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Test Screen Wake',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isTestingWake)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D2FF).withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'In $_testCountdown s...',
                    style: const TextStyle(
                      color: Color(0xFF00D2FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below, then immediately turn your phone screen off. After 3 seconds, VolWake will trigger the wake pipeline to turn on your display.',
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180), height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTestingWake ? null : _testScreenWake,
              icon: Icon(_isTestingWake ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded, size: 18),
              label: Text(
                _isTestingWake ? 'Waking screen in $_testCountdown seconds...' : 'Test Wake Pipeline (3s delay)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                foregroundColor: const Color(0xFF0A0E21),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Universal Android Setup Guide ───────────────
  Widget _buildAndroidGuideCard() {
    final steps = [
      {
        'title': 'Enable Accessibility Service',
        'subtitle': 'Tap the ENABLE button above, locate "VolWake" in your Android Accessibility settings, and toggle it ON.',
      },
      {
        'title': 'Exempt from Battery Optimization',
        'subtitle': 'Tap "Battery Settings" and select "Don\'t optimize" or "Unrestricted" so Android Doze does not sleep the service.',
      },
      {
        'title': 'Allow Background Autostart',
        'subtitle': 'Tap "Background Autostart" and ensure VolWake is permitted to launch and remain active in the background.',
      },
      {
        'title': 'Lock in Recent Apps (Recommended)',
        'subtitle': 'Open Recent Apps on your phone, swipe down or tap the menu on VolWake, and select the Lock / Padlock icon.',
      },
      {
        'title': 'Ready to Wake',
        'subtitle': 'Turn your phone screen off and press Volume Up or Down to illuminate your display!',
      },
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                ).createShader(bounds),
                child: const Icon(Icons.format_list_numbered_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Android Setup & Permission Instructions',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Steps List
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['subtitle']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(150),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────── Dedicated About VolWake Access Card ───────────────
  Widget _buildAboutAccessCard() {
    return _GlassCard(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _navigateToAboutPage,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D2FF).withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About VolWake',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Version 1.0.0 • Developer info, features & open-source links',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF00D2FF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── Android Architecture & Compatibility Info ───────────────
  Widget _buildArchitectureInfoCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00D2FF), Color(0xFF6C63FF)],
                ).createShader(bounds),
                child: const Icon(Icons.verified_user_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Android Architecture & Compatibility',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InfoBullet(
            icon: Icons.graphic_eq_rounded,
            title: 'MediaSession Routing',
            desc: 'When the screen turns off, a background audio session keeps hardware volume key clicks routed to VolWake on supported Android devices.',
          ),
          const SizedBox(height: 10),
          const _InfoBullet(
            icon: Icons.light_mode_rounded,
            title: 'Display Wake Pipeline',
            desc: 'Coordinates Android WakeLock and transparent wake flags to illuminate your display and lock screen immediately.',
          ),
          const SizedBox(height: 10),
          const _InfoBullet(
            icon: Icons.battery_charging_full_rounded,
            title: 'Zero Playback Battery Drain',
            desc: 'The background session automatically pauses the moment your screen turns back on, leaving standard volume adjustments 100% untouched.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF00D2FF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Android Compatibility Note: If another media player (such as music or podcast streaming) is actively playing audio with the screen off, Android prioritizes hardware volume buttons for that player.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withAlpha(170),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: _navigateToAboutPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'VolWake v1.0.0 • About & Developer Info',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF00D2FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF00D2FF)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ──────────── Helper Components ────────────────────
// ═══════════════════════════════════════════════════

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (isActive ? const Color(0xFF00E676) : const Color(0xFFFF5252)).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isActive ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isActive ? const Color(0xFF00E676) : const Color(0xFFFF5252),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), height: 1.2),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00D2FF),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoBullet({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00D2FF).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00D2FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(160), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
