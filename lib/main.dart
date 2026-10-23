import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const VolumeWakeApp());
}

class VolumeWakeApp extends StatelessWidget {
  const VolumeWakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Wake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D2FF),
          surface: Color(0xFF1A1F36),
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.volumewake/settings');

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isServiceEnabled = false;
  bool _isTestingWake = false;
  int _testCountdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showToast('Could not open settings: ${e.message}', isError: true);
    }
  }

  Future<void> _openVivoAutostart() async {
    try {
      final success = await _channel.invokeMethod<bool>('openVivoAutostart') ?? false;
      if (!success && mounted) {
        _showToast('Opened app settings. Please enable Autostart manually.');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showToast('Failed to open autostart: ${e.message}', isError: true);
    }
  }

  Future<void> _openBatteryOptimization() async {
    try {
      await _channel.invokeMethod('openBatteryOptimization');
    } on PlatformException catch (e) {
      if (!mounted) return;
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
          _showToast('Screen wake triggered! ☀️');
        }
      });
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6C63FF),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleServiceState() {
    setState(() {
      _isServiceEnabled = !_isServiceEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF141A33),
              Color(0xFF1B1145),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 30),

                // ── Hero Wake Button ──
                _buildHeroButton(),
                const SizedBox(height: 32),

                // ── Status Card ──
                _buildStatusCard(),
                const SizedBox(height: 20),

                // ── Vivo Y93 / Funtouch OS Fix Card ──
                _buildVivoOptimizationCard(),
                const SizedBox(height: 20),

                // ── Test Screen Wake Card ──
                _buildTestWakeCard(),
                const SizedBox(height: 20),

                // ── Instructions Card ──
                _buildInstructionsCard(),
                const SizedBox(height: 20),

                // ── How It Works Card ──
                _buildHowItWorksCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── Header ───────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
              ).createShader(bounds),
              child: const Text(
                'Volume Wake',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Vivo Y93 / Funtouch OS Enhanced',
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFF00D2FF).withAlpha(200),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────── Hero Button ───────────────
  Widget _buildHeroButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _openAccessibilitySettings,
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF7B73FF), Color(0xFF6C63FF), Color(0xFF4B42D4)],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withAlpha(100),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF00D2FF).withAlpha(40),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings_accessibility_rounded, color: Colors.white, size: 50),
              const SizedBox(height: 8),
              const Text(
                'ENABLE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Tap for Accessibility',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── Status Card ───────────────
  Widget _buildStatusCard() {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isServiceEnabled
                  ? const Color(0xFF00E676).withAlpha(30)
                  : const Color(0xFFFF5252).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isServiceEnabled ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _isServiceEnabled ? const Color(0xFF00E676) : const Color(0xFFFF5252),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isServiceEnabled ? 'Active & Foreground' : 'Not Enabled Yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _isServiceEnabled ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleServiceState,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: _isServiceEnabled
                    ? const Color(0xFF00E676).withAlpha(60)
                    : Colors.white.withAlpha(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment:
                    _isServiceEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _isServiceEnabled ? const Color(0xFF00E676) : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Vivo Y93 / Funtouch OS Optimization Card ───────────────
  Widget _buildVivoOptimizationCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vivo Y93 (Funtouch OS) Fix',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Required to stop Vivo killing screen-off wake',
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
          const SizedBox(height: 16),
          const Text(
            'Vivo Funtouch OS automatically stops background keys unless Autostart and High Background Power are allowed.',
            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openVivoAutostart,
                  icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: const Text('Vivo Autostart', style: TextStyle(fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openBatteryOptimization,
                  icon: const Icon(Icons.battery_charging_full_rounded, size: 16),
                  label: const Text('Allow Battery', style: TextStyle(fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2640),
                    foregroundColor: const Color(0xFF00D2FF),
                    side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amberAccent.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Also lock Volume Wake in Recent Apps (swipe down card & tap Padlock) so Vivo never purges it.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
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
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFF00D2FF), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Test Screen Wake Now',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isTestingWake)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D2FF).withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Waking in $_testCountdown s...',
                    style: const TextStyle(
                      color: Color(0xFF00D2FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the button, then immediately press your phone screen off (or let it go dark). In 3 seconds, Volume Wake will forcefully light up your display!',
            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTestingWake ? null : _testScreenWake,
              icon: Icon(_isTestingWake ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
              label: Text(
                _isTestingWake ? 'Waking screen in $_testCountdown seconds...' : 'Test Wake Mechanism (3s delay)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                foregroundColor: const Color(0xFF0A0E21),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Instructions Card ───────────────
  Widget _buildInstructionsCard() {
    final steps = [
      _StepData(
        icon: Icons.touch_app_rounded,
        title: 'Enable Accessibility',
        subtitle: 'Tap the purple ENABLE button above, find "Volume Wake", and toggle it ON.',
      ),
      _StepData(
        icon: Icons.rocket_launch_rounded,
        title: 'Allow Vivo Autostart',
        subtitle: 'Tap "Vivo Autostart" and toggle ON permissions for Volume Wake.',
      ),
      _StepData(
        icon: Icons.battery_saver_rounded,
        title: 'High Background Power',
        subtitle: 'Set Battery to "Don\'t restrict / High background consumption".',
      ),
      _StepData(
        icon: Icons.lock_outline_rounded,
        title: 'Lock in Recent Apps',
        subtitle: 'Open Recent Apps, swipe down on Volume Wake card and tap the padlock.',
      ),
      _StepData(
        icon: Icons.celebration_rounded,
        title: 'Ready to Wake!',
        subtitle: 'Whenever your screen is black, press Volume Up or Down to turn it on!',
      ),
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
                child: const Icon(Icons.format_list_numbered_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Vivo Y93 Complete Setup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
                            Icon(step.icon, size: 17, color: const Color(0xFF00D2FF)),
                            const SizedBox(width: 6),
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          step.subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
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

  // ─────────────── How It Works Card ───────────────
  Widget _buildHowItWorksCard() {
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
                child: const Icon(Icons.auto_awesome_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'How It Works on Vivo Y93',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _InfoTile(
            icon: Icons.volume_up_rounded,
            text: 'Press Volume Up or Down while the screen is off',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.graphic_eq_rounded,
            text: 'MediaSession & silent AudioTrack route volume clicks when locked',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.vibration_rounded,
            text: 'Phone vibrates briefly (50ms) confirming key press',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.wb_sunny_rounded,
            text: 'WakeActivity + WakeLock forces display & lockscreen ON',
          ),
          const SizedBox(height: 12),
          const _InfoTile(
            icon: Icons.battery_saver,
            text: 'Auto-pauses when screen turns ON — zero battery waste',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ──────────── Reusable Widgets ─────────────────────
// ═══════════════════════════════════════════════════

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepData({required this.icon, required this.title, required this.subtitle});
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF00D2FF).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00D2FF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(200),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
