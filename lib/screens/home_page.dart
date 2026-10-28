import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/trial_service.dart';
import '../widgets/trial_expired_dialog.dart';
import '../widgets/upgrade_widgets.dart';
import '../models/user_model.dart';
import '../screens/inventory_list_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/stock_movements_screen.dart';
import '../screens/predictions_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/session_actions.dart';
import '../widgets/connectivity_banner.dart';
import '../utils/feedback_utils.dart';

class HomePage extends StatefulWidget {
  final AppUser? currentUser;
  const HomePage({super.key, this.currentUser});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  AppUser? currentUser;
  bool isLoading = true;

  Timer? _trialTimer;
  bool _trialDialogShown = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadCurrentIndex();
    _initializeUser();
    _loadUserProfile();

    // Initialize pages here so we can safely pass instance members like _onTabSelected
    _pages = [
      DashboardScreen(onTabSelected: _onTabSelected),
      const InventoryListScreen(),
      const StockMovementsScreen(),
      const PredictionsScreen(),
      const ProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTrialExpiry());
    _trialTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _checkTrialExpiry());
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTrialExpiry() async {
    if (_trialDialogShown || !mounted) return;
    if (!await TrialService.isTrialExpired()) return;
    if (!mounted) return;
    _trialDialogShown = true;
    _trialTimer?.cancel();
    await TrialExpiredDialog.show(context, signedIn: true);
  }

  // keep your private helper
  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
    _saveCurrentIndex(index);
  }

  Future<void> _loadCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('current_tab_index') ?? 0;
    if (_currentIndex != savedIndex) {
      setState(() {
        _currentIndex = savedIndex;
      });
    }
  }

  Future<void> _saveCurrentIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_tab_index', index);
  }

  // **public** method other widgets can call
  void selectTab(int index) {
    if (_currentIndex != index) {
      _onTabSelected(index);
    }
    // Don't save if already selected to avoid unnecessary operations
  }

  void _initializeUser() {
    // Use the AppUser directly since that's what we now receive
    if (widget.currentUser != null) {
      currentUser = widget.currentUser;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // If we already have user data from widget, use AuthService for updates
      if (currentUser != null) {
        // Listen to auth state changes for updates
        AuthService.authStateChanges.listen((user) {
          if (mounted && user != null) {
            setState(() {
              currentUser = user;
            });
          }
        });
      } else {
        // Get current user from AuthService
        currentUser = AuthService.currentUser;

        // Listen to auth state changes
        AuthService.authStateChanges.listen((user) {
          if (mounted) {
            setState(() {
              currentUser = user;
            });
          }
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Updated navigation items with shorter labels
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Items'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Stock'),
    BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Predict'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;

    // Keeps pages readable on large screens; phones are unaffected.
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth > 1200 ? 1200.0 : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (AuthService.isTrialSession) const UpgradeAppBarButton(),
          _buildAccountMenu(),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _onTabSelected,
                        labelType: NavigationRailLabelType.all,
                        leading: AuthService.isTrialSession
                            ? const UpgradeRailButton()
                            : null,
                        selectedIconTheme: IconThemeData(
                            color: isDark ? Colors.white : theme.primaryColor),
                        selectedLabelTextStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : theme.primaryColor,
                        ),
                        unselectedIconTheme: IconThemeData(
                            color: isDark ? Colors.white54 : Colors.grey[600]),
                        unselectedLabelTextStyle: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                        destinations: [
                          for (final item in _navItems)
                            NavigationRailDestination(
                              icon: item.icon,
                              label: Text(item.label ?? ''),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              unselectedItemColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.grey[600],
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).bottomNavigationBarTheme.backgroundColor
                  : null,
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
              items: _navItems,
            ),
    );
  }

  Widget _buildAccountMenu() {
    final isTrial = AuthService.isTrialSession;
    final displayName = currentUser?.displayName ?? 'User';
    final isDefaultTrialName = isTrial && displayName == 'Trial User';
    final primaryLine =
        isDefaultTrialName ? 'Guest' : _getFirstName(displayName);
    final roleLine = isTrial
        ? 'Free Trial'
        : (currentUser?.isAdmin == true ? 'Admin' : 'Staff');
    final showNames = MediaQuery.of(context).size.width >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    PopupMenuItem<String> item(String value, IconData icon, String label,
        {Color? color}) {
      return PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, color: color)),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _onTabSelected(4);
            break;
          case 'upgrade':
            UpgradeSheet.show(context);
            break;
          case 'feedback':
            FeedbackUtils.openFeedbackForm(context);
            break;
          case 'signout':
            SessionActions.confirmSignOut(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primaryLine,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  )),
              Text(roleLine,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  )),
            ],
          ),
        ),
        const PopupMenuDivider(),
        item('profile', Icons.person_outline, 'My profile'),
        if (isTrial)
          item('upgrade', Icons.workspace_premium_outlined, 'Upgrade plan'),
        if (isTrial)
          item('feedback', Icons.rate_review_outlined, 'Share feedback'),
        const PopupMenuDivider(),
        item('signout', Icons.logout, 'Sign out', color: Colors.red[600]),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showNames)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(primaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                    Text(roleLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            if (showNames) const SizedBox(width: 10),
            UserAvatar(
              photo: currentUser?.profilePhotoPath,
              name: displayName,
              size: 36,
              onPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';

    // Split by spaces and get the first word (first name)
    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty && nameParts[0].isNotEmpty
        ? nameParts[0]
        : 'User';
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'StockSense';
      case 1:
        return 'Inventory';
      case 2:
        return 'Stock Movements';
      case 3:
        return 'Predictions';
      case 4:
        return 'Profile';
      default:
        return 'Inventory Manager';
    }
  }
}
