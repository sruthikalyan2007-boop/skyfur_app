import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_profile_service.dart';

class PetDetailsScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const PetDetailsScreen({super.key, this.onNavigate});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';

  @override
  void initState() {
    super.initState();
    PetProfileService.listenToProfile(_currentUid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pet Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Edit / Create Care Plan',
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () => widget.onNavigate?.call(5),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<PetProfile?>(
          valueListenable: PetProfileService.petProfileNotifier,
          builder: (context, profile, _) {
            if (profile == null) {
              return _buildEmptyState(context);
            }
            return _buildProfileContent(context, profile);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 46,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Pet Profile Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Build a personalized care plan in Pet Care to generate your pet\'s verified profile with breed photo, nutrition guidelines, and wellness focus areas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _EmptyFeatureRow(
                          icon: Icons.photo_camera_back_outlined,
                          text: 'Live Dog CEO Breed Photo & Identification',
                        ),
                        SizedBox(height: 10),
                        _EmptyFeatureRow(
                          icon: Icons.spa_outlined,
                          text: 'Tailored Care Focus Areas (Skin, Joints, Weight)',
                        ),
                        SizedBox(height: 10),
                        _EmptyFeatureRow(
                          icon: Icons.cloud_done_outlined,
                          text: 'Instant Cloud Sync with your Firestore account',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onNavigate?.call(5),
                      icon: const Icon(Icons.add_task, size: 20),
                      label: const Text(
                        'Create Pet Profile in Pet Care',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, PetProfile profile) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Profile Header
              _buildHeroHeader(context, profile),
              const SizedBox(height: 24),

              // Detail Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 640;
                  final overviewCard = _buildOverviewCard(context, profile);
                  final focusAreasCard = _buildFocusAreasCard(context, profile);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: overviewCard),
                        const SizedBox(width: 20),
                        Expanded(child: focusAreasCard),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        overviewCard,
                        const SizedBox(height: 20),
                        focusAreasCard,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Preventative Health Routine Timeline
              _buildTimelineSection(theme, profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, PetProfile profile) {
    const primaryTeal = Color(0xFF0D9488);
    final hasBreedImage = profile.breedPhotoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Breed Photo / Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCCFBF1), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasBreedImage
                ? Image.network(
                    profile.breedPhotoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
          ),
          const SizedBox(width: 22),

          // Pet Details Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done, size: 13, color: Color(0xFF0D9488)),
                          SizedBox(width: 5),
                          Text(
                            'Live Firestore',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${profile.breed} · ${profile.age}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPill(Icons.verified, 'Verified Pet', const Color(0xFF0D9488), const Color(0xFFF0FDF4)),
                    if (profile.careAreas.isNotEmpty)
                      _buildPill(
                        Icons.check_circle_outline,
                        '${profile.careAreas.length} Care Focus ${profile.careAreas.length == 1 ? "Area" : "Areas"}',
                        const Color(0xFF0284C7),
                        const Color(0xFFF0F9FF),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFCCFBF1),
      child: const Center(
        child: Icon(Icons.pets, size: 48, color: Color(0xFF0D9488)),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, PetProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pet Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => widget.onNavigate?.call(5),
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Update', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Pet Name', value: profile.name, icon: Icons.pets),
            _DetailRow(label: 'Breed', value: profile.breed, icon: Icons.category_outlined),
            _DetailRow(label: 'Age / Life Stage', value: profile.age, icon: Icons.cake_outlined),
            _DetailRow(
              label: 'Gender',
              value: profile.gender ?? 'Not specified',
              icon: Icons.male_outlined,
            ),
            _DetailRow(
              label: 'Microchip ID',
              value: profile.microchip ?? 'Registered in Cloud',
              icon: Icons.memory_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreasCard(BuildContext context, PetProfile profile) {
    final areas = profile.careAreas;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Care Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${areas.length} active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (areas.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No specific care focus areas selected yet. You can add Skin & Coat, Healthy Weight, Joints, or Dental Care in the Pet Care flow.',
                  style: TextStyle(fontSize: 13, color: Colors.blueGrey[600], height: 1.4),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: areas.map((areaId) {
                  return _buildCareBadge(areaId);
                }).toList(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 18, color: Color(0xFF0D9488)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nutrition and routines are actively optimized for ${profile.name}\'s focus areas.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F766E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareBadge(String areaId) {
    IconData icon;
    String label;
    Color color;
    Color bg;

    switch (areaId) {
      case 'skin_coat':
        icon = Icons.brush;
        label = 'Skin & Coat';
        color = const Color(0xFF0D9488);
        bg = const Color(0xFFCCFBF1);
        break;
      case 'weight':
        icon = Icons.monitor_weight;
        label = 'Healthy Weight';
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        break;
      case 'joints':
        icon = Icons.accessibility;
        label = 'Joints & Mobility';
        color = const Color(0xFF6366F1);
        bg = const Color(0xFFEEF2FF);
        break;
      case 'dental':
        icon = Icons.sentiment_satisfied;
        label = 'Dental Care';
        color = const Color(0xFF0284C7);
        bg = const Color(0xFFE0F2FE);
        break;
      default:
        icon = Icons.health_and_safety;
        label = areaId;
        color = const Color(0xFF0F766E);
        bg = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, PetProfile profile) {
    final events = [
      _HealthEvent(
        title: 'Care Plan Established',
        date: profile.updatedAt != null
            ? '${profile.updatedAt!.day}/${profile.updatedAt!.month}/${profile.updatedAt!.year}'
            : 'Active',
        detail: 'Personalized care focus areas configured for ${profile.name}.',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF0D9488),
      ),
      _HealthEvent(
        title: 'Core Vaccinations (DHPP & Rabies)',
        date: 'Scheduled',
        detail: 'Up-to-date booster records verified in Skyfur Scans.',
        icon: Icons.vaccines,
        color: const Color(0xFF6366F1),
      ),
      _HealthEvent(
        title: 'Annual Veterinary Wellness',
        date: 'Recommended annually',
        detail: 'Book your next wellness exam via Skyfur Find Vets.',
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFF0284C7),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellness & Preventative Routine',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...events.map((event) => _TimelineCard(event: event)),
      ],
    );
  }
}

class _EmptyFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0D9488)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HealthEvent {
  final String title;
  final String date;
  final String detail;
  final IconData icon;
  final Color color;

  const _HealthEvent({
    required this.title,
    required this.date,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _TimelineCard extends StatelessWidget {
  final _HealthEvent event;

  const _TimelineCard({required this.event});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(event.icon, color: event.color, size: 22),
          ),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${event.detail}\n${event.date}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.3),
            ),
          ),
          isThreeLine: true,
        ),
      );
}
