import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/consultation_utils.dart';
import '../utils/friendly_error.dart';
import '../services/trial_service.dart';
import '../widgets/trial_expired_dialog.dart';
import '../config/contact_config.dart';
import 'legal_screen.dart';
import 'auth/widget_tree.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Interactive state
  final bool _isExpanded = false;
  int _selectedFeature = -1;
  int _selectedGuideStep = -1;

  bool _startingTrial = false;

  Future<void> _startFreeTrial() async {
    if (_startingTrial) return;
    setState(() => _startingTrial = true);
    try {
      final status = await TrialService.beginTrial();
      if (!mounted) return;
      if (status == TrialStatus.expired) {
        await TrialExpiredDialog.show(context, signedIn: false);
        return;
      }
      if (status == TrialStatus.invalid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'We could not verify your trial. Please contact Cloudora.')));
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WidgetTree()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(friendlyError(e,
                fallback:
                    'Could not start your trial. Please check your connection and try again.'))),
      );
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
  }

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  // Theme-aware color palette for feature icons
  static Map<IconData, Color> getFeatureIconColors(
      bool isDarkMode, Color primaryColor) {
    if (isDarkMode) {
      // Dark mode: Brighter, more saturated colors for better visibility
      return {
        Icons.timeline: const Color(0xFF42A5F5), // Bright blue
        Icons.sync_alt: const Color(0xFF66BB6A), // Bright green
        Icons.auto_graph:
            const Color.fromARGB(255, 44, 37, 26), // Bright orange
        Icons.people_alt_outlined: const Color(0xFFBA68C8), // Bright purple
        Icons.inventory_2: const Color(0xFF42A5F5), // Bright blue
        Icons.inventory: const Color(0xFF42A5F5), // Bright blue
        Icons.bar_chart: const Color(0xFF42A5F5), // Bright blue
        Icons.notifications: const Color(0xFFFFB74D), // Bright orange
        Icons.security: const Color(0xFFBA68C8), // Bright purple
        Icons.login: const Color(0xFF42A5F5), // Bright blue
        Icons.analytics: const Color(0xFF42A5F5), // Bright blue
        Icons.group_add: const Color(0xFF42A5F5), // Bright blue
        Icons.trending_up: const Color(0xFF66BB6A), // Bright green
        Icons.speed: const Color(0xFFFFB74D), // Bright orange
        Icons.group: const Color(0xFFBA68C8), // Bright purple
      };
    } else {
      // Light mode: Professional colors with good contrast
      return {
        Icons.timeline: const Color(0xFF1976D2), // Professional blue
        Icons.sync_alt: const Color(0xFF388E3C), // Professional green
        Icons.auto_graph: const Color(0xFFF57C00), // Professional orange
        Icons.people_alt_outlined:
            const Color(0xFF7B1FA2), // Professional purple
        Icons.inventory_2: const Color(0xFF1976D2), // Professional blue
        Icons.inventory: const Color(0xFF1976D2), // Professional blue
        Icons.bar_chart: const Color(0xFF1976D2), // Professional blue
        Icons.notifications: const Color(0xFFF57C00), // Professional orange
        Icons.security: const Color(0xFF7B1FA2), // Professional purple
        Icons.login: const Color(0xFF1976D2), // Professional blue
        Icons.analytics: const Color(0xFF1976D2), // Professional blue
        Icons.group_add: const Color(0xFF1976D2), // Professional blue
        Icons.trending_up: const Color(0xFF388E3C), // Professional green
        Icons.speed: const Color(0xFFF57C00), // Professional orange
        Icons.group: const Color(0xFF7B1FA2), // Professional purple
      };
    }
  }

  @override
  void initState() {
    super.initState();

    // Fade animation for overall content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations with delays for smooth, professional loading
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                'StockSense',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              actions: [
                if (!isSmallScreen) ...[
                  _buildNavLink('Features', isDarkMode,
                      () => _scrollToSection(_featuresKey)),
                  _buildNavLink('Pricing', isDarkMode,
                      () => _scrollToSection(_pricingKey)),
                  _buildNavLink(
                      'About', isDarkMode, () => _scrollToSection(_aboutKey)),
                ],
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF121212),
                          const Color(0xFF1e1e1e),
                          const Color(0xFF0f0f0f),
                        ]
                      : [
                          Colors.grey[50]!,
                          Colors.grey[25] ?? Colors.white,
                          Colors.white,
                          Colors.white,
                        ],
                  stops: isDarkMode
                      ? const [0.0, 0.5, 1.0]
                      : const [0.0, 0.33, 0.67, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          // Hero Section with Background
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: _buildHeroSection(context, isDarkMode,
                                    isSmallScreen, isMediumScreen),
                              );
                            },
                          ),

                          Padding(
                            key: _featuresKey,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                // App Overview Section
                                _buildAppOverview(context, isDarkMode,
                                    isSmallScreen, isMediumScreen),

                                const SizedBox(height: 40),

                                // Interactive Features Section
                                _buildFeaturesSection(context, isDarkMode),
                              ],
                            ),
                          ),

                          Padding(
                            key: _pricingKey,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 40),

                                // Pricing Section
                                _buildPricingSection(context, isDarkMode,
                                    isSmallScreen, isMediumScreen),
                              ],
                            ),
                          ),

                          Padding(
                            key: _aboutKey,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 60),

                                // Consultation Section
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => ConsultationUtils
                                        .showConsultationDialog(context),
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      'Book a Consultation',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFFFF6B00),
                                      side: BorderSide(
                                          color: isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFFFF6B00)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Quick Start Guide
                                _buildQuickGuideSection(context, isDarkMode),

                                const SizedBox(height: 40),

                                // Stats Section
                                _buildStatsSection(context, isDarkMode),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),

                          // Footer
                          _buildFooter(context, isDarkMode),
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
    );
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final muted = isDarkMode ? Colors.white60 : Colors.black54;
    final strong = isDarkMode ? Colors.white : Colors.black87;

    Widget link(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 13, color: muted)),
          ),
        );

    Widget group(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: strong)),
            const SizedBox(height: 8),
            ...children,
          ],
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Wrap(
                spacing: 48,
                runSpacing: 28,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/icons/orange_logo.jpeg',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(ContactConfig.productName,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: strong)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Smart inventory management for shops, wholesalers and growing businesses in Kenya.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, height: 1.6, color: muted),
                        ),
                      ],
                    ),
                  ),
                  group('Explore', [
                    link('Features', () => _scrollToSection(_featuresKey)),
                    link('Pricing', () => _scrollToSection(_pricingKey)),
                    link(
                        'Book a consultation',
                        () =>
                            ConsultationUtils.showConsultationDialog(context)),
                  ]),
                  group('Contact', [
                    link(
                        ContactConfig.email,
                        () => _openUrl(
                            'mailto:${ContactConfig.email}?subject=StockSense%20enquiry')),
                    if (ContactConfig.phone.isNotEmpty)
                      link(
                          ContactConfig.phone,
                          () => _openUrl(
                              'tel:${ContactConfig.phone.replaceAll(' ', '')}')),
                    if (ContactConfig.whatsapp.isNotEmpty)
                      link(
                          'WhatsApp',
                          () => _openUrl(
                              'https://wa.me/${ContactConfig.whatsapp}')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(ContactConfig.location,
                          style:
                              GoogleFonts.poppins(fontSize: 13, color: muted)),
                    ),
                  ]),
                  group('Legal', [
                    link(
                        'Privacy notice',
                        () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                                document: LegalDocument.privacy)))),
                    link(
                        'Free trial terms',
                        () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                                document: LegalDocument.terms)))),
                  ]),
                ],
              ),
              const SizedBox(height: 28),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 14),
              Text(
                '© ${DateTime.now().year} ${ContactConfig.companyName}. All rights reserved. Prices shown in Kenya shillings (KES).',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, bool isDarkMode, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDarkMode,
      bool isSmallScreen, bool isMediumScreen) {
    final theme = Theme.of(context);
    final headlineColor = isDarkMode ? Colors.white : Colors.black87;
    final bodyColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/landing_image.png'),
          fit: BoxFit.cover,
          opacity: 0.25,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 80, 24, 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              // Logo with glow
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.3),
                      theme.primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/orange_logo.jpeg',
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Product name
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDarkMode
                      ? [Colors.white, Colors.white70]
                      : [Colors.black87, Colors.black],
                ).createShader(bounds),
                child: Text(
                  'StockSense',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontFamilyFallback: ['Roboto', 'sans-serif'],
                    fontSize: isSmallScreen ? 32 : (isMediumScreen ? 36 : 42),
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Required for ShaderMask
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Headline: the outcome for the visitor
              Text(
                "Always know what's in stock, what's selling and what to reorder.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 20 : (isMediumScreen ? 24 : 30),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: headlineColor,
                ),
              ),

              const SizedBox(height: 16),

              // What it is and who it is for
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(
                  'StockSense helps shops, wholesalers and growing businesses '
                  'track every item, record each stock movement, and spot low '
                  'stock and expiring products early. Use it on your phone or '
                  'computer.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 13 : 15,
                    height: 1.6,
                    color: bodyColor,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Three concrete benefits
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth =
                      constraints.maxWidth < 520 ? constraints.maxWidth : 220.0;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildHeroBenefit(
                        Icons.inventory_2_outlined,
                        'Live stock levels',
                        'Quantities, values and low-stock items at a glance.',
                        cardWidth,
                        isDarkMode,
                        theme,
                      ),
                      _buildHeroBenefit(
                        Icons.swap_vert_rounded,
                        'Every movement recorded',
                        'Stock in, stock out and adjustments, with date and user.',
                        cardWidth,
                        isDarkMode,
                        theme,
                      ),
                      _buildHeroBenefit(
                        Icons.notifications_active_outlined,
                        'Early warnings',
                        'Low-stock and expiry alerts, plus days-left estimates.',
                        cardWidth,
                        isDarkMode,
                        theme,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Free trial button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF8C00), // Dark Orange
                      Color(0xFFFF6B00), // Cloudora Orange
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _startingTrial ? null : _startFreeTrial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _startingTrial
                          ? 'Setting up your workspace…'
                          : 'Start 14-Day Free Trial',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Removes the doubts before the click
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  'Free for 14 days. No sign-up, password or card needed. '
                  'Your workspace opens with a sample shop you can explore and edit.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.5,
                    color: bodyColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBenefit(IconData icon, String title, String description,
      double width, bool isDarkMode, ThemeData theme) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primaryColor, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppOverview(BuildContext context, bool isDarkMode,
      bool isSmallScreen, bool isMediumScreen) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'What is StockSense?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontFamilyFallback: ['Roboto', 'sans-serif'],
                fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 32,
                    color: isDarkMode ? Colors.amber[400] : theme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'StockSense helps you keep track of every item you sell, record each stock movement, and see what needs reordering before it runs out. It works on your phone, tablet or computer, and prices are shown in Kenya shillings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontFamilyFallback: ['Roboto', 'sans-serif'],
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context, bool isDarkMode,
      bool isSmallScreen, bool isMediumScreen) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => ScaleAnimation(
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Simple Pricing',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose the plan that fits your business',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            if (isSmallScreen) ...[
              _PricingCard(
                title: 'Entry',
                price: 'KES 5,200',
                usdPrice: '\$40',
                description: 'Small shops & boutiques',
                features: const ['Basic Inventory', '5 Users', 'Email Support'],
                isDarkMode: isDarkMode,
                isHighlight: false,
                onSelectPlan: () => ConsultationUtils.showConsultationDialog(
                    context,
                    plan: 'Entry'),
              ),
              const SizedBox(height: 16),
              _PricingCard(
                title: 'Mid',
                price: 'KES 13,000',
                usdPrice: '\$100',
                description: 'Growing SMEs',
                features: const [
                  'Advanced Analytics',
                  '20 Users',
                  'Priority Support',
                  'AI Predictions'
                ],
                isDarkMode: isDarkMode,
                isHighlight: true,
                onSelectPlan: () => ConsultationUtils.showConsultationDialog(
                    context,
                    plan: 'Mid'),
              ),
              const SizedBox(height: 16),
              _PricingCard(
                title: 'High',
                price: 'KES 45,500',
                usdPrice: '\$350',
                description: 'Retail chains',
                features: const [
                  'Unlimited Users',
                  'Dedicated Support',
                  'Custom Integrations',
                  'Multi-location'
                ],
                isDarkMode: isDarkMode,
                isHighlight: false,
                onSelectPlan: () => ConsultationUtils.showConsultationDialog(
                    context,
                    plan: 'High'),
              ),
            ] else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PricingCard(
                      title: 'Entry',
                      price: 'KES 5,200',
                      usdPrice: '\$40',
                      description: 'Small shops & boutiques',
                      features: const [
                        'Basic Inventory',
                        '5 Users',
                        'Email Support'
                      ],
                      isDarkMode: isDarkMode,
                      isHighlight: false,
                      onSelectPlan: () =>
                          ConsultationUtils.showConsultationDialog(context,
                              plan: 'Entry'),
                    ),
                    const SizedBox(width: 16),
                    _PricingCard(
                      title: 'Mid',
                      price: 'KES 13,000',
                      usdPrice: '\$100',
                      description: 'Growing SMEs',
                      features: const [
                        'Advanced Analytics',
                        '20 Users',
                        'Priority Support',
                        'AI Predictions'
                      ],
                      isDarkMode: isDarkMode,
                      isHighlight: true,
                      onSelectPlan: () =>
                          ConsultationUtils.showConsultationDialog(context,
                              plan: 'Mid'),
                    ),
                    const SizedBox(width: 16),
                    _PricingCard(
                      title: 'High',
                      price: 'KES 45,500',
                      usdPrice: '\$350',
                      description: 'Retail chains',
                      features: const [
                        'Unlimited Users',
                        'Dedicated Support',
                        'Custom Integrations',
                        'Multi-location'
                      ],
                      isDarkMode: isDarkMode,
                      isHighlight: false,
                      onSelectPlan: () =>
                          ConsultationUtils.showConsultationDialog(context,
                              plan: 'High'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDarkMode) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Powerful Features',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontFamilyFallback: ['Roboto', 'sans-serif'],
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildInteractiveFeature(
              context,
              icon: Icons.timeline,
              title: 'Live Stock Levels',
              subtitle:
                  'See quantities, values and low-stock items at a glance.',
              details:
                  'Your dashboard updates as you add items and record stock movements, so you always know what you have on hand.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.sync_alt,
              title: 'Stock Movements',
              subtitle: 'Every stock in, stock out and adjustment, recorded.',
              details:
                  'Each movement is saved with its date, reason and who made it, giving you a clear history of your stock.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.auto_graph,
              title: 'Stock Predictions',
              subtitle: 'Estimate how many days of stock you have left.',
              details:
                  'StockSense studies your recent sales to estimate when each item will run out, so you can reorder before shelves go empty.',
              isDarkMode: isDarkMode,
            ),
            _buildInteractiveFeature(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Roles & Team Access',
              subtitle: 'Give your team the access they need.',
              details:
                  'Full plans support several users with Admin and Staff roles. Team accounts are set up with you when you upgrade.',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final iconColor =
        getFeatureIconColors(isDarkMode, theme.primaryColor)[icon] ??
            theme.primaryColor;
    final isSelected = _selectedFeature == icon.hashCode;

    return AnimationLimiter(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFeature = isSelected ? -1 : icon.hashCode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withValues(alpha: 0.1)
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? iconColor.withValues(alpha: 0.3)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          iconColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isSelected ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isSelected ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkMode ? Colors.white60 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? null : 0,
                child: isSelected
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[300],
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            details,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickGuideSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Quick Start Guide',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get up and running in minutes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white60 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildGuideStep(
              context,
              step: 1,
              icon: Icons.login,
              title: 'Start Your Free Trial',
              description:
                  'Tap Start Free Trial. No sign-up or password needed.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 2,
              icon: Icons.inventory,
              title: 'Add Your First Item',
              description:
                  'Start by adding your inventory items with details and categories.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 3,
              icon: Icons.analytics,
              title: 'Monitor & Predict',
              description: 'See what is selling and which items to reorder.',
              isDarkMode: isDarkMode,
            ),
            _buildGuideStep(
              context,
              step: 4,
              icon: Icons.group_add,
              title: 'Upgrade When Ready',
              description:
                  'Add your team and unlock full plans when the trial ends.',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context, {
    required int step,
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final iconColor =
        getFeatureIconColors(isDarkMode, theme.primaryColor)[icon] ??
            theme.primaryColor;
    final isSelected = _selectedGuideStep == step;

    return AnimationLimiter(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGuideStep = isSelected ? -1 : step;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withValues(alpha: 0.1)
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? iconColor.withValues(alpha: 0.3)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          iconColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.poppins(
                          fontSize: isSelected ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        child: Text(step.toString()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isSelected ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: isDarkMode ? Colors.white60 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? null : 0,
                child: isSelected
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[300],
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailedGuideStep(step, isDarkMode),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedGuideStep(int step, bool isDarkMode) {
    final details = _getGuideStepDetails(step);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              'What you\'ll do:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getGuideStepTip(step),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getGuideStepDetails(int step) {
    switch (step) {
      case 1:
        return [
          'Tap "Start 14-Day Free Trial" on this page',
          'Your workspace opens straight away',
          'Add your own items and stock movements',
          'Your trial runs for 14 days'
        ];
      case 2:
        return [
          'Navigate to the inventory section',
          'Tap "Add Item" to create your first product',
          'Fill in item details: name, description, category',
          'Set quantity, price, and reorder levels',
          'Upload product images if available'
        ];
      case 3:
        return [
          'View your dashboard for real-time insights',
          'Check stock predictions and alerts',
          'Monitor inventory value and trends',
          'Review stock movement history',
          'Spot low stock and expiring items on the dashboard'
        ];
      case 4:
        return [
          'Open Upgrade from the top bar at any time',
          'Compare the Entry, Mid and High plans',
          'Tell us about your business',
          'Our team sets up your account and your staff'
        ];
      default:
        return [];
    }
  }

  String _getGuideStepTip(int step) {
    switch (step) {
      case 1:
        return 'Pro tip: Add a few real items early to see how much time StockSense saves you.';
      case 2:
        return 'Pro tip: Start with your most important or fast-moving items to see immediate benefits.';
      case 3:
        return 'Pro tip: Check the Predict tab to see which items will run out first.';
      case 4:
        return 'Pro tip: Not sure which plan fits? Tap Book a Consultation and we will recommend one.';
      default:
        return '';
    }
  }

  Widget _buildStatsSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => ScaleAnimation(
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(
              'Why Choose StockSense?',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.timer_outlined,
                    value: '14 days',
                    label: 'Free trial',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.credit_card_off_outlined,
                    value: 'No card',
                    label: 'Needed to start',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.devices_outlined,
                    value: 'Any device',
                    label: 'Phone, tablet & desktop',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.support_agent,
                    value: 'Nairobi',
                    label: 'Local support team',
                    color: Colors.transparent, // Not used anymore
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    // Get theme-aware color for the stat icon
    final theme = Theme.of(context);
    final statIconColor =
        getStatIconColor(icon, isDarkMode, theme.primaryColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: statIconColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Get theme-aware colors for stat icons
  static Color getStatIconColor(
      IconData icon, bool isDarkMode, Color primaryColor) {
    if (isDarkMode) {
      // Dark mode: Bright, vibrant colors for visibility
      switch (icon) {
        case Icons.trending_up:
          return const Color(0xFF66BB6A); // Bright green
        case Icons.security:
          return const Color(0xFF42A5F5); // Bright blue
        case Icons.speed:
          return const Color(0xFFFFB74D); // Bright orange
        case Icons.group:
          return const Color(0xFFBA68C8); // Bright purple
        default:
          return primaryColor;
      }
    } else {
      // Light mode: Professional colors with good contrast
      switch (icon) {
        case Icons.trending_up:
          return const Color(0xFF388E3C); // Professional green
        case Icons.security:
          return const Color(0xFF1976D2); // Professional blue
        case Icons.speed:
          return const Color(0xFFF57C00); // Professional orange
        case Icons.group:
          return const Color(0xFF7B1FA2); // Professional purple
        default:
          return primaryColor;
      }
    }
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String usdPrice;
  final String description;
  final List<String> features;
  final bool isDarkMode;
  final bool isHighlight;
  final VoidCallback onSelectPlan;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.usdPrice,
    required this.description,
    required this.features,
    required this.isDarkMode,
    required this.isHighlight,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode
            ? (isHighlight
                ? theme.primaryColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05))
            : (isHighlight ? const Color(0xFFF0F4FF) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight
              ? theme.primaryColor
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200]!),
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? theme.primaryColor
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            usdPrice,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: isHighlight
                          ? theme.primaryColor
                          : (isDarkMode ? Colors.white60 : Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelectPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlight
                    ? theme.primaryColor
                    : (isDarkMode ? Colors.white10 : Colors.grey[100]),
                foregroundColor: isHighlight
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isHighlight ? 4 : 0,
              ),
              child: Text(
                'Choose Plan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
