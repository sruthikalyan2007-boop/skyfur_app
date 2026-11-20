import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VetsScreen extends StatefulWidget {
  const VetsScreen({super.key});

  @override
  State<VetsScreen> createState() => _VetsScreenState();
}

class _VetsScreenState extends State<VetsScreen> {
  final _reasonController = TextEditingController();
  final _pets = const ['Milo (Dog)', 'Luna (Cat)', 'Charlie (Puppy)', 'Bella (Golden)'];
  final _vets = const [
    _Vet(
      name: 'Dr. Ananya Rao',
      qualification: 'BVSc & AH, MVSc',
      specialization: 'Small Animal Medicine & Surgery',
      experience: '8 years experience',
      clinic: 'Paws & Care Veterinary Clinic',
      location: 'Banjara Hills, Hyderabad',
      fee: '₹700',
      rating: '4.9 (124 reviews)',
      whatsappNumber: '919876543210',
      photoUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400',
    ),
    _Vet(
      name: 'Dr. Rohan Mehta',
      qualification: 'MVSc (Dermatology)',
      specialization: 'Dermatology, Allergies & Surgery',
      experience: '11 years experience',
      clinic: 'Happy Tails Multispeciality Hospital',
      location: 'Jubilee Hills, Hyderabad',
      fee: '₹900',
      rating: '4.8 (98 reviews)',
      whatsappNumber: '919876543211',
      photoUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400',
    ),
  ];

  String? _selectedPet = 'Milo (Dog)';
  _Vet? _selectedVet;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _localAppointments = [
    {
      'id': 'local_apt_1',
      'pet': 'Luna (Golden Retriever)',
      'vetName': 'Dr. Sarah Jenkins',
      'clinic': 'Metro Pet Hospital & Dental Clinic',
      'location': 'Downtown Medical Center',
      'fee': '\$75',
      'specialization': 'General Veterinary & Surgery',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '10:30 AM',
      'reason': 'Annual booster vaccine and health checkup',
      'status': 'Confirmed',
    },
  ];

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0D9488),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0D9488),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _confirmBooking() async {
    final uid = _currentUid;

    if (_selectedPet == null ||
        _selectedVet == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all 4 appointment fields and select a vet')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final formattedTime = _selectedTime!.format(context);
    final pet = _selectedPet!;
    final vet = _selectedVet!;
    final reason = _reasonController.text.trim();
    final date = _selectedDate!;

    bool savedToFirestore = false;
    try {
      // Save appointment under logged-in user's UID in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .add({
        'pet': pet,
        'vetName': vet.name,
        'clinic': vet.clinic,
        'location': vet.location,
        'fee': vet.fee,
        'specialization': vet.specialization,
        'whatsappNumber': vet.whatsappNumber,
        'photoUrl': vet.photoUrl,
        'date': Timestamp.fromDate(date),
        'time': formattedTime,
        'reason': reason,
        'status': 'Confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      savedToFirestore = true;
    } catch (_) {
      // Fallback to local session storage
      setState(() {
        _localAppointments.insert(0, {
          'id': 'local_apt_${DateTime.now().millisecondsSinceEpoch}',
          'pet': pet,
          'vetName': vet.name,
          'clinic': vet.clinic,
          'location': vet.location,
          'fee': vet.fee,
          'specialization': vet.specialization,
          'whatsappNumber': vet.whatsappNumber,
          'photoUrl': vet.photoUrl,
          'date': date,
          'time': formattedTime,
          'reason': reason,
          'status': 'Confirmed',
        });
      });
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _selectedPet = null;
        _selectedVet = null;
        _selectedDate = null;
        _selectedTime = null;
        _reasonController.clear();
      });

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('Appointment Confirmed'),
            ],
          ),
          content: Text(
            '$pet is scheduled with ${vet.name} on ${_formatDate(date)} at $formattedTime.\n\n${savedToFirestore ? "Details have been saved to your Cloud Firestore records." : "Details have been saved to your session records."}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cancelAppointment(String docId) async {
    final uid = _currentUid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel and remove this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Visit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('appointments')
            .doc(docId)
            .delete();
      } catch (_) {}
      setState(() {
        _localAppointments.removeWhere((it) => it['id'] == docId);
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
                          Icons.local_hospital,
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
                              'Veterinary Consultations',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with trusted veterinarians and schedule appointments backed by Cloud Firestore.',
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

                  // Available Vets Section
                  Text(
                    'Available Veterinarians',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 780 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _vets.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 1.9 : 1.45,
                        ),
                        itemBuilder: (context, index) {
                          final vet = _vets[index];
                          final isSelected = _selectedVet == vet;
                          return _VetCard(
                            vet: vet,
                            selected: isSelected,
                            onSelect: () => setState(() => _selectedVet = vet),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Booking Card
                  _buildBookingCard(context),

                  const SizedBox(height: 36),

                  // User's Cloud Appointments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Appointments',
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
                            'Live from Firestore',
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
                        .collection('appointments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final List<Map<String, dynamic>> displayApts = [];

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        for (final doc in snapshot.data!.docs) {
                          final data = (doc.data() as Map<String, dynamic>?) ?? {};
                          DateTime? aptDate;
                          if (data['date'] is Timestamp) {
                            aptDate = (data['date'] as Timestamp).toDate();
                          } else if (data['date'] is DateTime) {
                            aptDate = data['date'] as DateTime;
                          }
                          displayApts.add({
                            'id': doc.id,
                            'pet': data['pet'] ?? 'Pet',
                            'vetName': data['vetName'] ?? 'Veterinarian',
                            'clinic': data['clinic'] ?? '',
                            'fee': data['fee'] ?? '',
                            'time': data['time'] ?? '',
                            'reason': data['reason'] ?? '',
                            'date': aptDate,
                            'status': data['status'] ?? 'Confirmed',
                            'isCloud': true,
                          });
                        }
                      }

                      // Append local appointments
                      for (final local in _localAppointments) {
                        if (!displayApts.any((it) => it['id'] == local['id'])) {
                          displayApts.add(local);
                        }
                      }

                      if (snapshot.connectionState == ConnectionState.waiting && displayApts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                          ),
                        );
                      }

                      if (displayApts.isEmpty) {
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
                                  Icons.event_note_outlined,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No appointments booked yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Select a veterinarian above and schedule a consultation.',
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
                                      'Displaying session appointments. (To enable cloud sync across devices, create the Firestore database in Firebase Console).',
                                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ...displayApts.map((apt) {
                            final docId = apt['id'] as String;
                            final pet = apt['pet'] as String? ?? 'Pet';
                            final vetName = apt['vetName'] as String? ?? 'Veterinarian';
                            final clinic = apt['clinic'] as String? ?? '';
                            final fee = apt['fee'] as String? ?? '';
                            final time = apt['time'] as String? ?? '';
                            final reason = apt['reason'] as String? ?? '';
                            final dateTimestamp = apt['date'] as DateTime?;
                            final dateStr = dateTimestamp != null ? _formatDate(dateTimestamp) : '';
                            final isCloud = apt['isCloud'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.event_available,
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
                                                '$pet · $vetName',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
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
                                                  'Confirmed',
                                                  style: TextStyle(
                                                    color: Colors.green.shade800,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$clinic ($fee)',
                                            style: TextStyle(
                                              color: Colors.blueGrey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                isCloud ? Icons.cloud_done : Icons.storage_outlined,
                                                size: 14,
                                                color: const Color(0xFF0D9488),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$dateStr at $time',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Color(0xFF0D9488),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (reason.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Reason: $reason',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Cancel appointment',
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                      onPressed: () => _cancelAppointment(docId),
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

  Widget _buildBookingCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Text(
                  'Schedule an Appointment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Step 1: Pet
            DropdownButtonFormField<String>(
              initialValue: _selectedPet,
              decoration: const InputDecoration(
                labelText: '1. Select Patient Pet',
                prefixIcon: Icon(Icons.pets),
              ),
              items: _pets
                  .map((pet) => DropdownMenuItem(value: pet, child: Text(pet)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPet = value),
            ),
            const SizedBox(height: 14),

            // Step 2 & 3: Date and Time Pickers
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today,
                    label: '2. Date',
                    value: _selectedDate == null
                        ? 'Choose Date'
                        : _formatDate(_selectedDate!),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule,
                    label: '3. Time',
                    value: _selectedTime == null
                        ? 'Choose Time'
                        : _selectedTime!.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Selected Vet Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedVet != null
                    ? const Color(0xFFCCFBF1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedVet != null
                      ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 20,
                    color: _selectedVet != null
                        ? const Color(0xFF0D9488)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedVet != null
                          ? 'Selected Vet: ${_selectedVet!.name} (${_selectedVet!.fee})'
                          : 'Please select a veterinarian from the cards above',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedVet != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedVet != null
                            ? const Color(0xFF0F766E)
                            : Colors.blueGrey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Step 4: Reason
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '4. Reason for Visit & Symptoms',
                hintText: 'e.g. Annual vaccination check, mild allergy, routine checkup',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmBooking,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Saving to Firestore...' : 'Confirm Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _Vet {
  final String name,
      qualification,
      specialization,
      experience,
      clinic,
      location,
      fee,
      rating,
      whatsappNumber,
      photoUrl;

  const _Vet({
    required this.name,
    required this.qualification,
    required this.specialization,
    required this.experience,
    required this.clinic,
    required this.location,
    required this.fee,
    required this.rating,
    required this.whatsappNumber,
    required this.photoUrl,
  });
}

class _VetCard extends StatelessWidget {
  final _Vet vet;
  final bool selected;
  final VoidCallback onSelect;

  const _VetCard({
    required this.vet,
    required this.selected,
    required this.onSelect,
  });

  Future<void> _contactOnWhatsApp(BuildContext context) async {
    final message = 'Hi ${vet.name}, I would like to consult with you regarding my pet via Skyfur.';
    final encoded = Uri.encodeComponent(message);
    final appUrl = Uri.parse('whatsapp://send?phone=${vet.whatsappNumber}&text=$encoded');
    final webUrl = Uri.parse('https://wa.me/${vet.whatsappNumber}?text=$encoded');

    if (!await launchUrl(appUrl, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D9488);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? primary : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                vet.photoUrl,
                width: 90,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 90,
                  height: 120,
                  color: const Color(0xFFCCFBF1),
                  child: const Icon(Icons.person, size: 40, color: primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 15, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            vet.rating.split(' ').first,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    vet.qualification,
                    style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
                  ),
                  Text(
                    vet.specialization,
                    style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vet.clinic} · ${vet.location}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Fee: ${vet.fee}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected ? primary : const Color(0xFFF1F5F9),
                          foregroundColor: selected ? Colors.white : const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: Text(selected ? 'Selected' : 'Select Vet'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'WhatsApp Consult',
                        icon: const Icon(Icons.chat, color: Colors.green, size: 20),
                        onPressed: () => _contactOnWhatsApp(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0D9488)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
