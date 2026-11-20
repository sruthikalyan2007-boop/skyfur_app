import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/vets_screen.dart';
import 'screens/insurance_screen.dart';
import 'screens/certify_screen.dart';
import 'screens/petcare_screen.dart';
import 'screens/pet_details_screen.dart';
import 'screens/pet_shop_screen.dart';
import 'services/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkyfurApp());
}

class SkyfurApp extends StatelessWidget {
  const SkyfurApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    const tealContainer = Color(0xFFCCFBF1);

    return MaterialApp(
      title: 'Skyfur - Pet Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          onPrimary: Colors.white,
          primaryContainer: tealContainer,
          onPrimaryContainer: const Color(0xFF0F766E),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryTeal,
            side: const BorderSide(color: primaryTeal, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryTeal, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF475569)),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// Note: demoUserLoggedInNotifier is imported from services/auth_state.dart

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: demoUserLoggedInNotifier,
      builder: (context, isDemo, _) {
        if (isDemo) {
          return const MainNavigationShell();
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0D9488),
                  ),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const MainNavigationShell();
            }
            return const AuthScreen();
          },
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const ScanScreen(),
    const VetsScreen(),
    const InsuranceScreen(),
    const CertifyScreen(),
    PetCareScreen(onNavigate: _onNavigate),
    PetDetailsScreen(onNavigate: _onNavigate),
    const PetShopScreen(),
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Skyfur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      demoUserLoggedInNotifier.value = false;
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    final isDemo = isDemoLoggedIn;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final emailPrefix = (email.isNotEmpty && email.contains('@'))
        ? email.split('@').first
        : 'Pet Parent';
    final displayName = isDemo
        ? 'Alex Morgan (Demo)'
        : ((user?.displayName != null && user!.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : emailPrefix);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Skyfur', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.pets, color: Color(0xFF0D9488), size: 36),
              ),
              accountName: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(email),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onNavigate(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner),
                    title: const Text('Scan Documents'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      _onNavigate(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_hospital),
                    title: const Text('Find Vets'),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      _onNavigate(2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Insurance'),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      _onNavigate(3);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified),
                    title: const Text('Certify & Microchip'),
                    selected: _selectedIndex == 4,
                    onTap: () {
                      _onNavigate(4);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.pets),
                    title: const Text('Pet Care Plan'),
                    selected: _selectedIndex == 5,
                    onTap: () {
                      _onNavigate(5);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('Pet Profile'),
                    selected: _selectedIndex == 6,
                    onTap: () {
                      _onNavigate(6);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: const Text('Pet Shop'),
                    selected: _selectedIndex == 7,
                    onTap: () {
                      _onNavigate(7);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? HomeScreen(onNavigate: _onNavigate)
          : _screens[_selectedIndex - 1],
    );
  }

  Widget _buildDesktopLayout() {
    final compactRail = MediaQuery.sizeOf(context).height < 600;
    final isDemo = isDemoLoggedIn;
    final user = FirebaseAuth.instance.currentUser;
    final email = isDemo
        ? 'alex.skyfur.demo@gmail.com'
        : (user?.email ?? 'petparent@skyfur.app');

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavigate,
            labelType: compactRail
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: compactRail
                ? null
                : Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 32,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Skyfur',
                        style: TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Log Out ($email)',
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: _logout,
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: Text('Scan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_hospital),
                selectedIcon: Icon(Icons.local_hospital),
                label: Text('Vets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.security),
                selectedIcon: Icon(Icons.security),
                label: Text('Insurance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified),
                selectedIcon: Icon(Icons.verified),
                label: Text('Certify'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pets),
                selectedIcon: Icon(Icons.pets),
                label: Text('Pet Care'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge),
                selectedIcon: Icon(Icons.badge),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag),
                selectedIcon: Icon(Icons.shopping_bag),
                label: Text('Shop'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _selectedIndex == 0
                ? HomeScreen(onNavigate: _onNavigate)
                : _screens[_selectedIndex - 1],
          ),
        ],
      ),
    );
  }
}
