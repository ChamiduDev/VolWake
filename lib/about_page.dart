import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _channel = MethodChannel('com.example.volumewake/settings');

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final success = await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
      if (!success && context.mounted) {
        _showToast(context, 'Could not open link: $url', isError: true);
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        _showToast(context, 'Failed to launch link: ${e.message}', isError: true);
      }
    }
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
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
                  child: Column(
                    children: [
                      // ── Top Navigation Bar ──
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Back to Home',
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'About VolWake',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Scrollable Body ──
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. App Header Section
                              _buildAppHeader(),
                              const SizedBox(height: 20),

                              // 2. About the App Section
                              _buildAboutSection(),
                              const SizedBox(height: 18),

                              // 3. Key Features Section
                              _buildKeyFeaturesSection(),
                              const SizedBox(height: 18),

                              // 4. Developer Info Section
                              _buildDeveloperSection(),
                              const SizedBox(height: 18),

                              // 5. Action Links Section
                              _buildActionLinksSection(context),
                              const SizedBox(height: 28),

                              // ── Back to Home Action ──
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                  label: const Text(
                                    'Back to Home Screen',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF00D2FF),
                                    side: const BorderSide(color: Color(0xFF00D2FF), width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Footer
                              Center(
                                child: Text(
                                  '© 2026 Chamindu Kavishka • Released under MIT License',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withAlpha(120),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────── 1. App Header ───────────────
  Widget _buildAppHeader() {
    return _GlassCard(
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
              ).createShader(bounds),
              child: const Text(
                'VolWake',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Volume Key Display Wake Utility',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF00D2FF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF).withAlpha(60)),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── 2. About the App ───────────────
  Widget _buildAboutSection() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'About the App',
          ),
          const SizedBox(height: 12),
          Text(
            'VolWake is a lightweight, dedicated Android utility designed to help users bypass a broken, stuck, or unresponsive hardware Power button by using the physical Volume Up and Volume Down keys to wake the display.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(210),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'By coordinating Android\'s Accessibility Service, background media routing, and temporary WakeLocks, VolWake lights up the screen immediately when a volume key is pressed with the screen off—eliminating the need for expensive hardware repairs.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(210),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Android Device Compatibility: Because hardware button dispatching and battery-saving policies vary across different Android versions and device configurations, compatibility depends on enabling the required background and battery permissions for your Android phone.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withAlpha(190),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── 3. Key Features ───────────────
  Widget _buildKeyFeaturesSection() {
    final features = [
      {
        'icon': Icons.power_settings_new_rounded,
        'title': 'Wake screen using volume keys',
        'desc': 'Press Volume Up or Down while the screen is off to instantly wake up your display.',
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'Lightweight and simple UI',
        'desc': 'Clean, responsive glassmorphic dark design tailored for all screen sizes.',
      },
      {
        'icon': Icons.speed_rounded,
        'title': 'Easy setup and configuration',
        'desc': 'One-tap direct access to Android Accessibility and system settings.',
      },
      {
        'icon': Icons.devices_rounded,
        'title': 'Device compatibility guidance',
        'desc': 'Clear setup and permission instructions for supported Android phones.',
      },
      {
        'icon': Icons.verified_outlined,
        'title': 'Broad Android device support',
        'desc': 'Supports different Android devices where the required APIs and device settings allow it.',
      },
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.star_outline_rounded,
            title: 'Key Features',
          ),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f['icon'] as IconData, color: const Color(0xFF00D2FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['desc'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withAlpha(150),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─────────────── 4. Developer Info ───────────────
  Widget _buildDeveloperSection() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.code_rounded,
            title: 'Developer Information',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chamindu Kavishka',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Software Developer & Creator of VolWake',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF00D2FF), size: 18),
              const SizedBox(width: 10),
              const Text(
                'License:',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E676).withAlpha(60)),
                ),
                child: const Text(
                  'MIT License',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00E676),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────── 5. Action Links ───────────────
  Widget _buildActionLinksSection(BuildContext context) {
    final links = [
      {
        'title': 'GitHub Repository',
        'subtitle': 'Explore the source code on GitHub',
        'url': 'https://github.com/ChamiduDev/VolWake',
        'icon': Icons.folder_special_rounded,
      },
      {
        'title': 'Report an Issue',
        'subtitle': 'Submit bug reports or feature requests',
        'url': 'https://github.com/ChamiduDev/VolWake/issues',
        'icon': Icons.bug_report_rounded,
      },
      {
        'title': 'GitHub Profile',
        'subtitle': 'Follow @ChamiduDev on GitHub',
        'url': 'https://github.com/ChamiduDev',
        'icon': Icons.code_rounded,
      },
      {
        'title': 'LinkedIn Profile',
        'subtitle': 'Connect with Chamindu Kavishka on LinkedIn',
        'url': 'https://www.linkedin.com/in/chamindu-kavishka-0ba512326',
        'icon': Icons.link_rounded,
      },
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.open_in_new_rounded,
            title: 'Action Links & Resources',
          ),
          const SizedBox(height: 14),
          ...links.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _launchUrl(context, item['url'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item['icon'] as IconData, color: const Color(0xFF00D2FF), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  item['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Helper title widget
  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
          ).createShader(bounds),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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
