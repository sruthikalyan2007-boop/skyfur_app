import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  int? _selectedPlanIndex;
  bool _isSaving = false;

  final List<InsurancePlan> _plans = [
    InsurancePlan(
      name: 'Basic Care',
      price: '\$29.99/month',
      coverage: 'Accident coverage, routine wellness checkups, core vaccinations',
      icon: Icons.shield_outlined,
      features: [
        'Accident emergencies up to \$3,000/yr',
        'Annual core vaccinations',
        '24/7 Pet Telehealth access',
      ],
    ),
    InsurancePlan(
      name: 'Premium Care',
      price: '\$49.99/month',
      coverage: 'Everything in Basic + illness coverage, dental scaling, prescription meds',
      icon: Icons.security,
      popular: true,
      features: [
        'Illness & accident coverage up to \$7,500/yr',
        'Annual dental cleaning & check',
        'Prescription medications coverage (80%)',
        'Specialist & ultrasound diagnostic visits',
      ],
    ),
    InsurancePlan(
      name: 'Complete Care',
      price: '\$79.99/month',
      coverage: 'Everything in Premium + emergency surgeries, cancer care, rehabilitation',
      icon: Icons.verified_user,
      features: [
        'Unlimited annual medical benefit limit',
        'Emergency surgery & ICU hospital stays',
        'Orthopedic & hereditary conditions',
        'Rehabilitation & acupuncture therapy',
      ],
    ),
  ];

  Map<String, dynamic>? _localActivePolicy = {
    'id': 'local_policy_demo',
    'planName': 'Complete Protection',
    'price': '\$49 / month',
    'policyNumber': 'SF-INS-8421',
    'confirmedAt': DateTime.now().subtract(const Duration(days: 14)),
    'status': 'Active',
  };

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';

  Future<void> _confirmAndSavePlan() async {
    final uid = _currentUid;

    if (_selectedPlanIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an insurance plan first')),
      );
      return;
    }

    final plan = _plans[_selectedPlanIndex!];
    setState(() {
      _isSaving = true;
    });

    final randomPolicyId = 'SF-INS-${1000 + Random().nextInt(9000)}';
    bool savedToFirestore = false;

    try {
      // Save to Firestore under logged-in user's UID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('insurance_plans')
          .add({
        'planName': plan.name,
        'price': plan.price,
        'coverage': plan.coverage,
        'policyNumber': randomPolicyId,
        'status': 'Active',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      savedToFirestore = true;
    } catch (_) {
      // Fallback to local session storage
      setState(() {
        _localActivePolicy = {
          'id': 'local_policy_${DateTime.now().millisecondsSinceEpoch}',
          'planName': plan.name,
          'price': plan.price,
          'coverage': plan.coverage,
          'policyNumber': randomPolicyId,
          'status': 'Active',
          'confirmedAt': DateTime.now(),
        };
      });
    }

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('Plan Activated!'),
            ],
          ),
          content: Text(
            'Your ${plan.name} policy ($randomPolicyId) is now active.\nYour pet is protected with ${plan.price}.\n\n${savedToFirestore ? "Recorded securely in Cloud Firestore." : "Saved to your active session records."}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _cancelPolicy(String docId) async {
    final uid = _currentUid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Policy'),
        content: const Text('Are you sure you want to cancel this insurance plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Policy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('insurance_plans')
            .doc(docId)
            .delete();
      } catch (_) {}
      setState(() {
        _localActivePolicy = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;
    final uid = _currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Header
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.security,
                          size: 34,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pet Insurance Plans',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Compare comprehensive plans, activate coverage, and maintain policies securely in Firestore.',
                              style: TextStyle(
                                color: Colors.blueGrey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('insurance_plans')
                        .orderBy('confirmedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      Map<String, dynamic>? activeData;
                      String activeDocId = '';
                      bool isCloud = false;

                      if (snapshot.hasData && snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
                        final latestDoc = snapshot.data!.docs.first;
                        activeData = (latestDoc.data() as Map<String, dynamic>?) ?? {};
                        activeDocId = latestDoc.id;
                        isCloud = true;
                      } else if (_localActivePolicy != null) {
                        activeData = _localActivePolicy;
                        activeDocId = _localActivePolicy!['id']?.toString() ?? 'local_policy';
                        isCloud = false;
                      }

                      if (activeData == null) {
                        return const SizedBox.shrink();
                      }

                      final planName = activeData['planName'] ?? 'Active Plan';
                      final price = activeData['price'] ?? '';
                      final policyNumber = activeData['policyNumber'] ?? 'SF-INS-0000';
                      final confirmedAt = activeData['confirmedAt'];
                      DateTime? confirmedTimestamp;
                      if (confirmedAt is Timestamp) {
                        confirmedTimestamp = confirmedAt.toDate();
                      } else if (confirmedAt is DateTime) {
                        confirmedTimestamp = confirmedAt;
                      }
                      final dateStr = confirmedTimestamp != null
                          ? '${confirmedTimestamp.day}/${confirmedTimestamp.month}/${confirmedTimestamp.year}'
                          : 'Active';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isCloud ? 'Your Active Cloud Policy' : 'Your Active Policy',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      planName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Policy #: $policyNumber · Activated on $dateStr',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _cancelPolicy(activeDocId),
                                icon: const Icon(Icons.cancel_outlined, color: Colors.white70, size: 16),
                                label: const Text(
                                  'Cancel Policy',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Plans Comparison
                  Text(
                    'Select or Change Coverage Tier',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Plans List
                  ..._plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    final isSelected = _selectedPlanIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PlanCard(
                        plan: plan,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedPlanIndex = index),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Confirm Plan Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _confirmAndSavePlan,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? 'Saving Policy to Firestore...'
                            : (_selectedPlanIndex != null
                                ? 'Confirm & Activate ${_plans[_selectedPlanIndex!].name}'
                                : 'Select a Plan to Confirm'),
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
}

class _PlanCard extends StatelessWidget {
  final InsurancePlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D9488);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      plan.icon,
                      color: isSelected ? Colors.white : primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (plan.popular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MOST POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan.price,
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? primary : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.coverage,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Column(
                children: plan.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 15, color: Color(0xFF0D9488)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsurancePlan {
  final String name;
  final String price;
  final String coverage;
  final IconData icon;
  final bool popular;
  final List<String> features;

  InsurancePlan({
    required this.name,
    required this.price,
    required this.coverage,
    required this.icon,
    this.popular = false,
    required this.features,
  });
}
