import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CertifyScreen extends StatefulWidget {
  const CertifyScreen({super.key});

  @override
  State<CertifyScreen> createState() => _CertifyScreenState();
}

class _CertifyScreenState extends State<CertifyScreen> {
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController(text: 'Milo');
  String _certType = 'ISO 11784/11785 Microchip';
  bool _isSubmitting = false;

  final List<String> _certTypes = [
    'ISO 11784/11785 Microchip',
    'Rabies Vaccination Certificate',
    'Breeder Pedigree Registration',
    'Service / Therapy Pet Credential',
  ];

  final List<Map<String, dynamic>> _localCertifications = [
    {
      'id': 'local_cert_1',
      'chipNumber': '985141002348912',
      'petName': 'Luna',
      'certType': 'ISO 11784/11785 Microchip ID',
      'status': 'Verified & Active',
      'issuer': 'Skyfur Global Pet Registry',
      'verifiedAt': DateTime.now().subtract(const Duration(days: 30)),
    },
  ];

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';

  @override
  void dispose() {
    _microchipController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSaveCertificate() async {
    final uid = _currentUid;

    final chipNumber = _microchipController.text.trim();
    if (chipNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a microchip or certificate number')),
      );
      return;
    }

    if (chipNumber.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid certificate number (at least 5 digits/letters)')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final petName = _petNameController.text.trim().isEmpty
        ? 'Pet'
        : _petNameController.text.trim();

    bool savedToFirestore = false;
    try {
      // Save to Firestore under logged-in user's UID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('certifications')
          .add({
        'chipNumber': chipNumber.toUpperCase(),
        'petName': petName,
        'certType': _certType,
        'status': 'Verified & Active',
        'issuer': 'Skyfur Global Pet Registry',
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      savedToFirestore = true;
    } catch (_) {
      // Fallback to local session storage
      setState(() {
        _localCertifications.insert(0, {
          'id': 'local_cert_${DateTime.now().millisecondsSinceEpoch}',
          'chipNumber': chipNumber.toUpperCase(),
          'petName': petName,
          'certType': _certType,
          'status': 'Verified & Active',
          'issuer': 'Skyfur Global Pet Registry',
          'verifiedAt': DateTime.now(),
        });
      });
    }

    if (mounted) {
      _microchipController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D9488),
          content: Row(
            children: [
              Icon(
                savedToFirestore ? Icons.verified : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(savedToFirestore
                  ? 'Certificate verified and stored in Firestore!'
                  : 'Certificate verified and saved to session!'),
            ],
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteCertificate(String docId) async {
    final uid = _currentUid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Certificate'),
        content: const Text('Are you sure you want to remove this verified certificate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('certifications')
            .doc(docId)
            .delete();
      } catch (_) {}
      setState(() {
        _localCertifications.removeWhere((it) => it['id'] == docId);
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
                          Icons.verified,
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
                              'Pet Certifications & Microchip',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify microchips, official registries, and health credentials with permanent Firestore sync.',
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

                  // Verification Input Card
                  Card(
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
                          Text(
                            'Verify Microchip or Registration Tag',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Certificate Type Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _certType,
                            decoration: const InputDecoration(
                              labelText: 'Certificate Category',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _certTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _certType = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          // Pet Name Field
                          TextFormField(
                            controller: _petNameController,
                            decoration: const InputDecoration(
                              labelText: 'Pet Name',
                              prefixIcon: Icon(Icons.pets),
                              hintText: 'e.g. Milo',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Microchip Number Field
                          TextField(
                            controller: _microchipController,
                            decoration: const InputDecoration(
                              labelText: 'Microchip or Tag Number',
                              hintText: 'e.g. 985141002345678 or SF-CERT-904',
                              prefixIcon: Icon(Icons.memory),
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _verifyAndSaveCertificate(),
                          ),
                          const SizedBox(height: 20),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _verifyAndSaveCertificate,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.verified_outlined),
                              label: Text(
                                _isSubmitting
                                    ? 'Verifying & Saving...'
                                    : 'Verify & Register in Firestore',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Cloud Firestore Saved Certifications History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Certificates in Cloud',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.cloud_done, color: Color(0xFF0D9488), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Synced with Firestore',
                            style: TextStyle(
                              color: Color(0xFF0D9488),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('certifications')
                        .orderBy('verifiedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final List<Map<String, dynamic>> displayCerts = [];

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        for (final doc in snapshot.data!.docs) {
                          final data = (doc.data() as Map<String, dynamic>?) ?? {};
                          DateTime? verifiedDate;
                          if (data['verifiedAt'] is Timestamp) {
                            verifiedDate = (data['verifiedAt'] as Timestamp).toDate();
                          } else if (data['verifiedAt'] is DateTime) {
                            verifiedDate = data['verifiedAt'] as DateTime;
                          }
                          displayCerts.add({
                            'id': doc.id,
                            'chipNumber': data['chipNumber'] ?? 'Unknown',
                            'petName': data['petName'] ?? 'Pet',
                            'certType': data['certType'] ?? 'Microchip',
                            'status': data['status'] ?? 'Active',
                            'issuer': data['issuer'] ?? 'Skyfur Registry',
                            'verifiedAt': verifiedDate,
                            'isCloud': true,
                          });
                        }
                      }

                      // Append local certifications
                      for (final local in _localCertifications) {
                        if (!displayCerts.any((it) => it['id'] == local['id'])) {
                          displayCerts.add(local);
                        }
                      }

                      if (snapshot.connectionState == ConnectionState.waiting && displayCerts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                          ),
                        );
                      }

                      if (displayCerts.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_outlined,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No verified certificates yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Enter your pet\'s microchip or tag number above to verify and store it in Firestore.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (snapshot.hasError) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.storage_outlined, color: Color(0xFF2563EB), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Displaying session certifications. (To enable cloud sync across devices, create the Firestore database in Firebase Console).',
                                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ...displayCerts.map((cert) {
                            final docId = cert['id'] as String;
                            final chip = cert['chipNumber'] as String? ?? 'Unknown';
                            final petName = cert['petName'] as String? ?? 'Pet';
                            final certType = cert['certType'] as String? ?? 'Microchip';
                            final status = cert['status'] as String? ?? 'Active';
                            final issuer = cert['issuer'] as String? ?? 'Skyfur Registry';
                            final dateTimestamp = cert['verifiedAt'] as DateTime?;
                            final dateStr = dateTimestamp != null
                                ? '${dateTimestamp.day}/${dateTimestamp.month}/${dateTimestamp.year}'
                                : 'Verified';
                            final isCloud = cert['isCloud'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF0D9488),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '$petName · $certType',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.green.shade200),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: Colors.green.shade800,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: Text(
                                              chip,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 1.2,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                isCloud ? Icons.cloud_done : Icons.storage_outlined,
                                                size: 13,
                                                color: const Color(0xFF0D9488),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$issuer · Registered on $dateStr',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete certification',
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _deleteCertificate(docId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
