import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_state.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDemo = isDemoLoggedIn;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final emailPrefix = (email.isNotEmpty && email.contains('@'))
        ? email.split('@').first
        : 'Pet Parent';
    final displayName = isDemo
        ? 'Alex Morgan'
        : ((user?.displayName != null && user!.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : emailPrefix);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Welcome Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_done, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cloud Sync Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome, $displayName!',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manage documents, veterinary visits, insurance, and personalized care for your beloved furry family.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pet Care Hub',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'All features backed by Firestore',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0D9488),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Feature Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900
                          ? 4
                          : (constraints.maxWidth > 550 ? 2 : 1);
                      final childAspectRatio = crossAxisCount == 1 ? 2.6 : 1.25;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _FeatureCard(
                            icon: Icons.qr_code_scanner,
                            title: 'Scan Documents',
                            description: 'Digitize & store medical papers securely in Firestore',
                            badge: 'Cloud Sync',
                            onTap: () => onNavigate(1),
                          ),
                          _FeatureCard(
                            icon: Icons.local_hospital,
                            title: 'Find Vets',
                            description: 'Book verified appointments & track consultation history',
                            badge: 'Appointments',
                            onTap: () => onNavigate(2),
                          ),
                          _FeatureCard(
                            icon: Icons.security,
                            title: 'Pet Insurance',
                            description: 'Compare plans & activate coverage for your pet',
                            badge: 'Plans',
                            onTap: () => onNavigate(3),
                          ),
                          _FeatureCard(
                            icon: Icons.verified,
                            title: 'Certifications',
                            description: 'Verify microchip numbers & registry status',
                            badge: 'Verified',
                            onTap: () => onNavigate(4),
                          ),
                          _FeatureCard(
                            icon: Icons.pets,
                            title: 'Pet Care Plan',
                            description: 'Personalized nutrition & Dog CEO breed photos',
                            badge: 'Live API',
                            onTap: () => onNavigate(5),
                          ),
                          _FeatureCard(
                            icon: Icons.badge,
                            title: 'Pet Profile',
                            description: 'View vaccination history & wellness timeline',
                            onTap: () => onNavigate(6),
                          ),
                          _FeatureCard(
                            icon: Icons.shopping_bag,
                            title: 'Pet Shop',
                            description: 'Quality pet food, accessories & healthcare essentials',
                            onTap: () => onNavigate(7),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: primaryTeal.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 26, color: primaryTeal),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
