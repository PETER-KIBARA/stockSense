import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/contact_config.dart';
import '../config/plans_config.dart';
import '../services/trial_service.dart';
import '../utils/consultation_utils.dart';
import '../utils/friendly_error.dart';
import '../widgets/trial_expired_dialog.dart';
import 'auth/widget_tree.dart';
import 'legal_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const Color _brand = Color(0xFFFF6B00);
const Color _brandLight = Color(0xFFFF8C00);
const Color _brandDark = Color(0xFFE85D00);
const Color _success = Color(0xFF16A34A);
const Color _info = Color(0xFF2563EB);
const double _maxContentWidth = 1120;

Color _ink(bool dark) => dark ? Colors.white : const Color(0xFF111827);
Color _muted(bool dark) => dark ? Colors.white70 : const Color(0xFF4B5563);
Color _subtle(bool dark) => dark ? Colors.white60 : const Color(0xFF6B7280);
Color _tint(bool dark) =>
    dark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);

TextStyle _t(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

BoxDecoration _cardDecoration(bool dark, {bool highlight = false}) {
  return BoxDecoration(
    color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: highlight
          ? _brand
          : (dark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE5E7EB)),
      width: highlight ? 2 : 1,
    ),
    boxShadow: dark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
  );
}

/// Responsive helpers.
class _L {
  final double w;
  const _L(this.w);

  bool get phone => w < 600;
  bool get tablet => w >= 600 && w < 1024;
  double get hPad => phone ? 20 : (tablet ? 32 : 48);
  double get sectionV => phone ? 56 : (tablet ? 72 : 96);
  double get headerGap => phone ? 32 : 48;
  double sz(double phoneSize, double tabletSize, double desktopSize) =>
      phone ? phoneSize : (tablet ? tabletSize : desktopSize);
}

/// Equal-height card grid. Do not put LayoutBuilder or scrollables inside the
/// items: the rows are measured with IntrinsicHeight.
Widget _equalGrid(
  List<Widget> items, {
  required int Function(double width) columnsFor,
  double gap = 20,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final cols =
          columnsFor(constraints.maxWidth).clamp(1, items.length).toInt();

      if (cols == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              items[i],
            ],
          ],
        );
      }

      final rows = <Widget>[];
      for (var i = 0; i < items.length; i += cols) {
        final slice = items.sublist(i, math.min(i + cols, items.length));
        rows.add(
          _EqualHeightRow(
            gap: gap,
            children: [
              ...slice,
              // Empty slots keep the last row's cards the same width.
              for (var k = slice.length; k < cols; k++) const SizedBox.shrink(),
            ],
          ),
        );
        if (i + cols < items.length) rows.add(SizedBox(height: gap));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      );
    },
  );
}

/// Lays its children out as one row of equal-width columns, then makes every
/// child as tall as the tallest one. It uses the children's real layout (not
/// an advance measurement), so text can never overflow its card.
class _EqualHeightRow extends MultiChildRenderObjectWidget {
  final double gap;

  const _EqualHeightRow({required this.gap, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualHeightRow(gap: gap);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEqualHeightRow renderObject,
  ) {
    renderObject.gap = gap;
  }
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  _RenderEqualHeightRow({required double gap}) : _gap = gap;

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) {
      child.parentData = _EqualHeightParentData();
    }
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    final count = childCount;
    if (count == 0) {
      size = constraints.smallest;
      return;
    }

    final width = constraints.maxWidth;
    final childWidth = math.max(0.0, (width - _gap * (count - 1)) / count);

    // Pass 1: the natural height of every child at its real width.
    var tallest = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints.tightFor(width: childWidth),
        parentUsesSize: true,
      );
      tallest = math.max(tallest, child.size.height);
      child = childAfter(child);
    }

    // Pass 2: stretch every child to at least the tallest one. The height is
    // a MINIMUM, not a fixed value, and the parent uses the size, so a child
    // that grows later (for example when a web font finishes loading) re-runs
    // this layout instead of overflowing inside its own fixed-height box.
    var height = 0.0;
    var x = 0.0;
    child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints(
          minWidth: childWidth,
          maxWidth: childWidth,
          minHeight: tallest,
        ),
        parentUsesSize: true,
      );
      (child.parentData! as _EqualHeightParentData).offset = Offset(x, 0);
      height = math.max(height, child.size.height);
      x += childWidth + _gap;
      child = childAfter(child);
    }

    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// Landing screen
// ---------------------------------------------------------------------------
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _fadeIn;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fade.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---- actions ------------------------------------------------------------

  Future<void> _startDemo() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final status = await TrialService.beginTrial();
      if (!mounted) return;
      if (status == TrialStatus.expired) {
        await TrialExpiredDialog.show(context, signedIn: false);
        return;
      }
      if (status == TrialStatus.invalid) {
        _snack('We could not verify your demo. Please contact Cloudora.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WidgetTree()),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(friendlyError(
        e,
        fallback:
            'Could not start your demo. Please check your connection and try again.',
      ));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _bookConsultation() => ConsultationUtils.showConsultationDialog(context);

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = _L(MediaQuery.of(context).size.width);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: _buildAppBar(l, isDark),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            children: [
              _buildHero(l, isDark),
              _buildFeatures(l, isDark),
              _buildHowItWorks(l, isDark),
              _buildDemoInside(l, isDark),
              _buildPricing(l, isDark),
              _buildDeployment(l, isDark),
              _buildFaq(l, isDark),
              _buildFinalCta(l, isDark),
              _buildFooter(l, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ---- top bar ------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(_L l, bool isDark) {
    final linkColor = isDark ? Colors.white70 : const Color(0xFF374151);
    final showLinks = l.w >= 860;

    Widget navLink(String label, GlobalKey key) => TextButton(
          onPressed: () => _scrollTo(key),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 40),
            foregroundColor: linkColor,
          ),
          child: Text(label,
              style: _t(14, weight: FontWeight.w500, color: linkColor)),
        );

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AppBar(
            toolbarHeight: 64,
            automaticallyImplyLeading: false,
            backgroundColor: (isDark ? const Color(0xFF121212) : Colors.white)
                .withValues(alpha: 0.78),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: l.phone ? 16 : l.hPad,
            title: Row(
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
                Flexible(
                  child: Text(
                    'StockSense',
                    overflow: TextOverflow.ellipsis,
                    style: _t(18, weight: FontWeight.w700, color: _ink(isDark)),
                  ),
                ),
              ],
            ),
            actions: [
              if (showLinks) ...[
                navLink('Features', _featuresKey),
                navLink('How it works', _howKey),
                navLink('Pricing', _pricingKey),
                navLink('FAQ', _faqKey),
                const SizedBox(width: 12),
              ],
              Padding(
                padding: EdgeInsets.only(right: l.phone ? 12 : l.hPad),
                child: Center(
                  child: _BrandButton(
                    label: l.w < 380 ? 'Demo' : 'Start a Demo',
                    size: _BtnSize.small,
                    loading: _starting,
                    onPressed: _starting ? null : _startDemo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- hero ---------------------------------------------------------------

  Widget _buildHero(_L l, bool isDark) {
    final topInset = MediaQuery.of(context).padding.top + 64;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF1C1410), Color(0xFF121212)]
              : const [Color(0xFFFFF3E8), Colors.white],
        ),
        image: DecorationImage(
          image: const AssetImage('assets/images/landing_image.png'),
          fit: BoxFit.cover,
          opacity: isDark ? 0.10 : 0.14,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        l.hPad,
        topInset + (l.phone ? 32 : 64),
        l.hPad,
        l.phone ? 56 : 88,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoBadge(l),
              SizedBox(height: l.phone ? 20 : 28),
              _eyebrowChip(isDark),
              SizedBox(height: l.phone ? 18 : 24),
              Semantics(
                header: true,
                child: Text(
                  'Know what’s in stock, what’s selling and what to reorder.',
                  textAlign: TextAlign.center,
                  style: _t(
                    l.sz(30, 42, 54),
                    weight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: l.phone ? -0.3 : -0.8,
                    color: _ink(isDark),
                  ),
                ),
              ),
              SizedBox(height: l.phone ? 16 : 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'StockSense helps retailers and SMEs reduce stock loss, '
                  'improve profit margins and gain real-time visibility into '
                  'inventory across outlets.',
                  textAlign: TextAlign.center,
                  style:
                      _t(l.sz(15, 17, 18), height: 1.65, color: _muted(isDark)),
                ),
              ),
              SizedBox(height: l.phone ? 28 : 36),
              _ctaButtons(l, onBrand: false),
              SizedBox(height: l.phone ? 22 : 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 22,
                runSpacing: 10,
                children: [
                  _Tick(text: 'No sign-up needed', color: _muted(isDark)),
                  _Tick(text: 'Opens in seconds', color: _muted(isDark)),
                  _Tick(text: 'One-hour demo session', color: _muted(isDark)),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'The one-hour demo opens a ready-made sample shop. Explore it, '
                  'edit it, or clear it and add your own stock.',
                  textAlign: TextAlign.center,
                  style: _t(12.5, height: 1.6, color: _subtle(isDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoBadge(_L l) {
    final size = l.phone ? 72.0 : 88.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.30),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/orange_logo.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _eyebrowChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _brand.withValues(alpha: 0.30)),
      ),
      child: Text(
        'Inventory management, simplified',
        textAlign: TextAlign.center,
        style: _t(
          12.5,
          weight: FontWeight.w600,
          letterSpacing: 0.3,
          color: isDark ? _brandLight : _brandDark,
        ),
      ),
    );
  }

  /// The two main buttons, used in the hero and the closing band.
  Widget _ctaButtons(_L l, {required bool onBrand}) {
    final primary = _BrandButton(
      label: _starting ? 'Setting up your demo…' : 'Start a Demo',
      icon: Icons.play_arrow_rounded,
      size: _BtnSize.xl,
      style: onBrand ? _BtnStyle.onBrandFilled : _BtnStyle.filled,
      loading: _starting,
      expand: l.phone,
      onPressed: _starting ? null : _startDemo,
    );
    final secondary = _BrandButton(
      label: 'Book a Consultation',
      icon: Icons.calendar_today_outlined,
      size: _BtnSize.xl,
      style: onBrand ? _BtnStyle.onBrandOutlined : _BtnStyle.outlined,
      expand: l.phone,
      onPressed: _bookConsultation,
    );

    if (l.phone) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [primary, const SizedBox(height: 14), secondary],
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 16,
      children: [primary, secondary],
    );
  }

  // ---- features -----------------------------------------------------------

  Widget _buildFeatures(_L l, bool isDark) {
    final cards = <Widget>[
      _InfoCard(
        icon: Icons.swap_vert_rounded,
        title: 'Every movement recorded',
        body:
            'Stock in, stock out and adjustments are saved with the date, the reason and who made them, so you always know where stock went.',
        isDark: isDark,
      ),
      _InfoCard(
        icon: Icons.notifications_active_outlined,
        title: 'Reminders',
        body:
            'Get reminded about low stock and products nearing their expiry date, so you reorder and sell in time.',
        isDark: isDark,
      ),
      _InfoCard(
        icon: Icons.insights_rounded,
        title: 'Insights & strategies',
        body:
            'See stock value, category mix and monthly activity at a glance, then use days-of-stock estimates to decide what to reorder and when.',
        isDark: isDark,
        badge: 'Pro & Premium',
      ),
      _InfoCard(
        icon: Icons.assessment_outlined,
        title: 'Stock reports',
        body:
            'Download PDF reports and export your items and stock history as CSV files that open in Excel.',
        isDark: isDark,
        badge: 'Pro & Premium',
      ),
      _InfoCard(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Scan to add',
        body:
            'Scan a product QR code with your phone camera to start a new item, then check the details and save.',
        isDark: isDark,
        badge: 'Phone only',
        badgeColor: _info,
      ),
      _InfoCard(
        icon: Icons.auto_awesome_rounded,
        title: 'AI predictions',
        body:
            'Know roughly how many days of stock each product has left, based on your recent stock movements, so you can reorder before you run out.',
        isDark: isDark,
        badge: 'Pro & Premium',
      ),
    ];

    return _Section(
      key: _featuresKey,
      l: l,
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'Features',
            title: 'Everything you need to run your stock with confidence',
            subtitle:
                'Track every movement, get reminded in time, understand your numbers and share reports.',
          ),
          SizedBox(height: l.headerGap),
          _equalGrid(
            cards,
            columnsFor: (w) => w >= 900 ? 3 : (w >= 560 ? 2 : 1),
          ),
        ],
      ),
    );
  }
  // ---- how it works -------------------------------------------------------

  Widget _buildHowItWorks(_L l, bool isDark) {
    final steps = <Widget>[
      _StepCard(
        number: 1,
        title: 'Start the demo',
        body:
            'One tap opens a ready-made sample shop for one hour. There is no sign-up or password.',
        isDark: isDark,
      ),
      _StepCard(
        number: 2,
        title: 'Explore and try it',
        body:
            'Browse the dashboard, record stock movements, check the insights and download a report. Edit anything you like.',
        isDark: isDark,
      ),
      _StepCard(
        number: 3,
        title: 'Make it yours',
        body:
            'Clear the sample data and add your own products, or upgrade and our team will set up your account and staff.',
        isDark: isDark,
      ),
    ];

    return _Section(
      key: _howKey,
      l: l,
      background: _tint(isDark),
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'How the demo works',
            title: 'From first tap to your own stock in three steps',
            subtitle:
                'No installation and no forms. See how StockSense fits your business before you commit.',
          ),
          SizedBox(height: l.headerGap),
          _equalGrid(steps, columnsFor: (w) => w >= 800 ? 3 : 1),
        ],
      ),
    );
  }

  // ---- inside the demo ----------------------------------------------------

  Widget _buildDemoInside(_L l, bool isDark) {
    const items = <String>[
      '30 sample products to explore and edit, or clear and add your own',
      'About a month of stock history: sales, deliveries and adjustments',
      'Reminders for low stock and expiring products, already set up',
      'Days-of-stock estimates for every product',
      'PDF reports and CSV export',
      'Add, edit and delete products, with photos, whenever you like',
    ];

    return _Section(
      l: l,
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'Inside the demo',
            title: 'A complete working shop, ready in seconds',
            subtitle:
                'This is the real StockSense app, filled with realistic shop data so every screen has something to show.',
          ),
          SizedBox(height: l.headerGap),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(l.phone ? 22 : 40),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _brand.withValues(alpha: 0.20)),
            ),
            child: Column(
              children: [
                _equalGrid(
                  [for (final t in items) _CheckRow(text: t, isDark: isDark)],
                  columnsFor: (w) => w >= 700 ? 2 : 1,
                  gap: 18,
                ),
                SizedBox(height: l.phone ? 28 : 36),
                _BrandButton(
                  label: _starting ? 'Setting up your demo…' : 'Start a Demo',
                  icon: Icons.play_arrow_rounded,
                  size: _BtnSize.large,
                  loading: _starting,
                  expand: l.phone,
                  onPressed: _starting ? null : _startDemo,
                ),
                const SizedBox(height: 12),
                Text(
                  'One-hour demo. No sign-up needed.',
                  textAlign: TextAlign.center,
                  style: _t(13, color: _subtle(isDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- pricing ------------------------------------------------------------

  Widget _buildPricing(_L l, bool isDark) {
    return _Section(
      key: _pricingKey,
      l: l,
      background: _tint(isDark),
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'Pricing',
            title: 'Simple monthly plans that grow with your team',
            subtitle:
                'Choose the plan that fits your business, then the team size that fits your staff.',
          ),
          SizedBox(height: l.headerGap),
          LayoutBuilder(
            builder: (context, c) {
              final three = c.maxWidth >= 940;
              final cards = <Widget>[
                for (final plan in PlansConfig.plans)
                  _PlanCard(
                    plan: plan,
                    isDark: isDark,
                    onChoose: () => ConsultationUtils.showConsultationDialog(
                      context,
                      plan: plan.name,
                    ),
                  ),
              ];
              return Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: three ? c.maxWidth : 460),
                  child: _equalGrid(
                    cards,
                    columnsFor: (_) => three ? 3 : 1,
                    gap: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Prices are in US dollars, billed monthly. A one-time deployment fee covers setup and onboarding.',
              textAlign: TextAlign.center,
              style: _t(13, height: 1.6, color: _subtle(isDark)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _bookConsultation,
            child: Text(
              'Not sure which plan fits? Talk to us',
              style: _t(14, weight: FontWeight.w600, color: _brandDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployment(_L l, bool isDark) {
    final fee = PlansConfig.deploymentFeePercent;
    final exampleFee = (100 * fee / 100).round();

    final custom = Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: _brand, size: 24),
          ),
          const SizedBox(height: 18),
          Text('Customized deployment',
              style: _t(19, weight: FontWeight.w600, color: _ink(isDark))),
          const SizedBox(height: 8),
          Text(
            'We adapt StockSense to your inventory processes. The core product stays the same, while settings, workflows and reports are tailored to you.',
            style: _t(14, height: 1.65, color: _muted(isDark)),
          ),
          const SizedBox(height: 20),
          for (final item in PlansConfig.customDeploymentExamples)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CheckRow(text: item, isDark: isDark),
            ),
          const SizedBox(height: 4),
          Text(
            'For example, a retailer with three warehouses can have reorder levels set for each warehouse and weekly stock reports.',
            style: _t(13, height: 1.65, color: _subtle(isDark)),
          ),
        ],
      ),
    );

    final feeCard = Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(isDark, highlight: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ONE-TIME DEPLOYMENT FEE',
                  style: _t(12,
                      weight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: _brand)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$fee%',
                      style:
                          _t(48, weight: FontWeight.w700, color: _ink(isDark))),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text('of your monthly plan',
                        style: _t(15, color: _muted(isDark))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Covers inventory structure setup, system configuration and onboarding.',
                style: _t(14, height: 1.65, color: _muted(isDark)),
              ),
              const SizedBox(height: 12),
              Text(
                'For example, a plan of \$100 a month has a one-time fee of \$$exampleFee.',
                style: _t(13, height: 1.65, color: _subtle(isDark)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _BrandButton(
              label: 'Talk to us about your setup',
              size: _BtnSize.medium,
              expand: true,
              onPressed: _bookConsultation,
            ),
          ),
        ],
      ),
    );

    return _Section(
      l: l,
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'Setup',
            title: 'Set up around the way you work',
            subtitle:
                'Every business keeps stock differently. We configure StockSense to match yours.',
          ),
          SizedBox(height: l.headerGap),
          _equalGrid(
            [custom, feeCard],
            columnsFor: (w) => w >= 800 ? 2 : 1,
            gap: 24,
          ),
        ],
      ),
    );
  }
  // ---- FAQ ----------------------------------------------------------------

  Widget _buildFaq(_L l, bool isDark) {
    return _Section(
      key: _faqKey,
      l: l,
      background: _tint(isDark),
      child: Column(
        children: [
          _SectionHeader(
            l: l,
            isDark: isDark,
            eyebrow: 'FAQ',
            title: 'Questions, answered',
            subtitle: 'Everything you need to know before you start the demo.',
          ),
          SizedBox(height: l.headerGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in _faqs) _FaqTile(faq: f, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- closing call to action ----------------------------------------------

  Widget _buildFinalCta(_L l, bool isDark) {
    return _Section(
      l: l,
      vertical: l.phone ? 52 : 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandLight, _brand, _brandDark],
        ),
      ),
      child: Column(
        children: [
          Semantics(
            header: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                'See StockSense working for your business',
                textAlign: TextAlign.center,
                style: _t(
                  l.sz(26, 32, 38),
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Start the demo now, or talk to our team and we will walk you through it.',
              textAlign: TextAlign.center,
              style: _t(
                l.sz(15, 16, 17),
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
          SizedBox(height: l.phone ? 28 : 36),
          _ctaButtons(l, onBrand: true),
        ],
      ),
    );
  }

  // ---- footer -------------------------------------------------------------

  Widget _buildFooter(_L l, bool isDark) {
    final muted = _subtle(isDark);
    final strong = _ink(isDark);

    Widget link(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: _t(13.5, color: muted)),
          ),
        );

    // One contact line with an icon. The text never wraps: it shrinks to fit.
    Widget contactRow(IconData icon, String text, {VoidCallback? onTap}) {
      final content = Row(
        children: [
          Icon(icon, size: 17, color: _brand),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: _t(13.5, color: muted),
              ),
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: content,
              ),
      );
    }

    Widget group(String title, List<Widget> kids, {double width = 170}) =>
        SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: _t(13.5, weight: FontWeight.w600, color: strong)),
              const SizedBox(height: 8),
              ...kids,
            ],
          ),
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.30)
            : const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(l.hPad, l.phone ? 40 : 56, l.hPad, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            children: [
              Wrap(
                spacing: 56,
                runSpacing: 32,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/icons/orange_logo.jpeg',
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(ContactConfig.productName,
                                style: _t(17,
                                    weight: FontWeight.w700, color: strong)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Smart inventory management for businesses in Kenya.',
                          style: _t(13, height: 1.65, color: muted),
                        ),
                        const SizedBox(height: 20),
                        Text('Follow us',
                            style: _t(13.5,
                                weight: FontWeight.w600, color: strong)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SocialButton(
                              icon: FontAwesomeIcons.instagram,
                              label: 'Instagram',
                              url: ContactConfig.instagram,
                              isDark: isDark,
                            ),
                            _SocialButton(
                              icon: FontAwesomeIcons.tiktok,
                              label: 'TikTok',
                              url: ContactConfig.tiktok,
                              isDark: isDark,
                            ),
                            _SocialButton(
                              icon: FontAwesomeIcons.linkedinIn,
                              label: 'LinkedIn',
                              url: ContactConfig.linkedin,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  group('Explore', [
                    link('Features', () => _scrollTo(_featuresKey)),
                    link('How it works', () => _scrollTo(_howKey)),
                    link('Pricing', () => _scrollTo(_pricingKey)),
                    link('FAQ', () => _scrollTo(_faqKey)),
                  ]),
                  group(
                    'Contact',
                    [
                      contactRow(
                        Icons.mail_outline_rounded,
                        ContactConfig.email,
                        onTap: () => _openUrl(
                          'mailto:${ContactConfig.email}?subject=${Uri.encodeComponent('StockSense enquiry')}',
                        ),
                      ),
                      if (ContactConfig.phone.isNotEmpty)
                        contactRow(
                          Icons.phone_outlined,
                          ContactConfig.phone,
                          onTap: () => _openUrl(
                              'tel:${ContactConfig.phone.replaceAll(' ', '')}'),
                        ),
                      if (ContactConfig.whatsapp.isNotEmpty)
                        contactRow(
                          Icons.chat_outlined,
                          'WhatsApp',
                          onTap: () => _openUrl(
                              'https://wa.me/${ContactConfig.whatsapp}'),
                        ),
                      contactRow(
                          Icons.location_on_outlined, ContactConfig.location),
                    ],
                    width: 250,
                  ),
                  group('Legal', [
                    link(
                      'Privacy notice',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                              document: LegalDocument.privacy),
                        ),
                      ),
                    ),
                    link(
                      'Demo terms',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(document: LegalDocument.terms),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 36),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 18),
              Text(
                '© ${DateTime.now().year} ${ContactConfig.companyName}. All rights reserved.',
                textAlign: TextAlign.center,
                style: _t(12, height: 1.6, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ content
// ---------------------------------------------------------------------------
class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

const List<_Faq> _faqs = [
  _Faq(
    'How long does the demo last?',
    'The demo lasts one hour from the moment you start it. Before it ends you can download your items and stock history as CSV files.',
  ),
  _Faq(
    'Do I need to create an account?',
    'No. The demo starts with one tap, with no sign-up and no password. It remembers your workspace on this browser for the hour.',
  ),
  _Faq(
    'Can I try it with my own products?',
    'Yes. Add your own products and photos, or clear the sample data and start with an empty shop.',
  ),
  _Faq(
    'How is StockSense priced?',
    'StockSense is a monthly subscription with three plans: Basic, Pro and Premium. Each plan has prices by team size. A one-time deployment fee of 20% of your monthly plan covers setup and onboarding.',
  ),
  _Faq(
    'What is a customized deployment?',
    'We configure StockSense around your processes: custom categories and SKU formats, integration with your POS, e-commerce platform or ERP, reorder levels for each warehouse, and reports and alerts built for your business.',
  ),
  _Faq(
    'Can I scan products to add them?',
    'Scanning uses a phone camera, so it is not part of the browser demo. Ask our team how it works on phones.',
  ),
  _Faq(
    'What are AI predictions?',
    'AI predictions estimate how many days of stock you have left for each product, based on your recent stock movements, so you can reorder in time. They are included in the Pro and Premium plans.',
  ),
  _Faq(
    'What happens when the demo ends?',
    'Access to the demo closes. To keep using StockSense, choose a plan and our team will contact you to set up your account.',
  ),
  _Faq(
    'Will my demo data move to a paid plan?',
    'Talk to our team when you upgrade and we will explain your options.',
  ),
];

// ---------------------------------------------------------------------------
// Reusable pieces
// ---------------------------------------------------------------------------
class _Section extends StatelessWidget {
  final _L l;
  final Widget child;
  final Color? background;
  final Decoration? decoration;
  final double? vertical;

  const _Section({
    super.key,
    required this.l,
    required this.child,
    this.background,
    this.decoration,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final v = vertical ?? l.sectionV;
    return Container(
      width: double.infinity,
      color: decoration == null ? background : null,
      decoration: decoration,
      padding: EdgeInsets.fromLTRB(l.hPad, v, l.hPad, v),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final _L l;
  final bool isDark;
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.l,
    required this.isDark,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: _t(12.5,
              weight: FontWeight.w600, letterSpacing: 1.6, color: _brand),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: _t(
                l.sz(26, 32, 38),
                weight: FontWeight.w700,
                height: 1.2,
                color: _ink(isDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _t(l.sz(15, 16, 17), height: 1.6, color: _muted(isDark)),
          ),
        ),
      ],
    );
  }
}

/// Small label such as "Coming soon" or "Phone only".
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _Pill({required this.text, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: _t(11, weight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;
  final String? badge;
  final Color badgeColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
    this.badge,
    this.badgeColor = _brand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brand, size: 24),
              ),
              if (badge != null)
                _Pill(text: badge!, color: badgeColor, isDark: isDark),
            ],
          ),
          const SizedBox(height: 18),
          Text(title,
              style: _t(17, weight: FontWeight.w600, color: _ink(isDark))),
          const SizedBox(height: 8),
          Text(body, style: _t(14, height: 1.65, color: _muted(isDark))),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final bool isDark;

  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_brandLight, _brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text('$number',
                style: _t(16, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: _t(17, weight: FontWeight.w600, color: _ink(isDark))),
          const SizedBox(height: 8),
          Text(body, style: _t(14, height: 1.65, color: _muted(isDark))),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CheckRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_circle_rounded, size: 22, color: _success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: _t(15,
                weight: FontWeight.w500, height: 1.5, color: _ink(isDark)),
          ),
        ),
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  final String text;
  final Color color;

  const _Tick({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: _success),
        const SizedBox(width: 8),
        Text(text, style: _t(13.5, weight: FontWeight.w500, color: color)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool isDark;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final line =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: _cardDecoration(isDark, highlight: plan.recommended),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.name,
                        style: _t(20,
                            weight: FontWeight.w600, color: _ink(isDark))),
                  ),
                  if (plan.recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('Most popular',
                          style: _t(11,
                              weight: FontWeight.w600, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(plan.audience, style: _t(13.5, color: _subtle(isDark))),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(plan.priceUsd,
                      style:
                          _t(36, weight: FontWeight.w700, color: _ink(isDark))),
                  const SizedBox(width: 8),
                  Text('/ month', style: _t(14, color: _subtle(isDark))),
                ],
              ),
              const SizedBox(height: 22),
              Divider(height: 1, color: line),
              const SizedBox(height: 22),
              for (final f in plan.features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_circle_rounded,
                            size: 18, color: _brand),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f,
                            style: _t(14.5, height: 1.4, color: _ink(isDark))),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text('PRICING BY TEAM SIZE',
                  style: _t(11.5,
                      weight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: _subtle(isDark))),
              const SizedBox(height: 8),
              for (final t in plan.tiers)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Text(t.users, style: _t(14, color: _muted(isDark))),
                      ),
                      Text('${t.priceUsd}/month',
                          style: _t(14,
                              weight: FontWeight.w600, color: _ink(isDark))),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: _BrandButton(
              label: 'Choose ${plan.name}',
              size: _BtnSize.medium,
              style: plan.recommended ? _BtnStyle.filled : _BtnStyle.outlined,
              expand: true,
              onPressed: onChoose,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  final bool isDark;

  const _FaqTile({required this.faq, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            iconColor: _brand,
            collapsedIconColor: _subtle(isDark),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(faq.q,
                style: _t(15, weight: FontWeight.w600, color: _ink(isDark))),
            children: [
              Text(faq.a, style: _t(14, height: 1.7, color: _muted(isDark))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------
enum _BtnSize { small, medium, large, xl }

enum _BtnStyle { filled, outlined, onBrandFilled, onBrandOutlined }

class _BrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final _BtnSize size;
  final _BtnStyle style;
  final IconData? icon;
  final bool loading;
  final bool expand;

  const _BrandButton({
    required this.label,
    required this.onPressed,
    this.size = _BtnSize.medium,
    this.style = _BtnStyle.filled,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  double get _height {
    switch (size) {
      case _BtnSize.small:
        return 40;
      case _BtnSize.medium:
        return 48;
      case _BtnSize.large:
        return 56;
      case _BtnSize.xl:
        return 62;
    }
  }

  double get _fontSize {
    switch (size) {
      case _BtnSize.small:
        return 13;
      case _BtnSize.medium:
        return 15;
      case _BtnSize.large:
        return 16;
      case _BtnSize.xl:
        return 17;
    }
  }

  double get _hPad {
    switch (size) {
      case _BtnSize.small:
        return 16;
      case _BtnSize.medium:
        return 24;
      case _BtnSize.large:
        return 32;
      case _BtnSize.xl:
        return 40;
    }
  }

  BorderRadius get _radius =>
      BorderRadius.circular(size == _BtnSize.small ? 10 : 14);

  Widget _content(Color color) {
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else if (icon != null)
          Icon(icon, size: _fontSize + 5, color: color),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(_fontSize, weight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extra-large buttons keep a comfortable minimum width on wide screens.
    final minWidth = (!expand && size == _BtnSize.xl) ? 250.0 : 0.0;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: _body(),
    );
  }

  Widget _body() {
    final shape = RoundedRectangleBorder(borderRadius: _radius);
    final padding = EdgeInsets.symmetric(horizontal: _hPad);
    final width = expand ? double.infinity : null;

    switch (style) {
      case _BtnStyle.filled:
        return SizedBox(
          height: _height,
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_brandLight, _brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.35),
                  blurRadius: size == _BtnSize.small ? 8 : 16,
                  offset: Offset(0, size == _BtnSize.small ? 3 : 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: padding,
                shape: shape,
              ),
              child: _content(Colors.white),
            ),
          ),
        );

      case _BtnStyle.outlined:
        return SizedBox(
          height: _height,
          width: width,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandDark,
              side: const BorderSide(color: _brand, width: 1.5),
              padding: padding,
              shape: shape,
            ),
            child: _content(_brandDark),
          ),
        );

      case _BtnStyle.onBrandFilled:
        return SizedBox(
          height: _height,
          width: width,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white,
              foregroundColor: _brandDark,
              disabledForegroundColor: _brandDark,
              elevation: 0,
              padding: padding,
              shape: shape,
            ),
            child: _content(_brandDark),
          ),
        );

      case _BtnStyle.onBrandOutlined:
        return SizedBox(
          height: _height,
          width: width,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.75), width: 1.5),
              padding: padding,
              shape: shape,
            ),
            child: _content(Colors.white),
          ),
        );
    }
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String url;
  final bool isDark;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () async {
            try {
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
          borderRadius: BorderRadius.circular(22),
          hoverColor: _brand.withValues(alpha: 0.12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: FaIcon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
