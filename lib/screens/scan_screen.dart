import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _previewImageBytes;
  String? _previewTitle;
  bool _isUploading = false;
  String? _documentType = 'Vaccination Record';

  final List<String> _docTypes = [
    'Vaccination Record',
    'Prescription & Medication',
    'Lab Test Report',
    'Deworming Certificate',
    'Other Document',
  ];

  final List<Map<String, dynamic>> _localScans = [];

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';

  Future<void> _pickAndSaveImage(ImageSource source) async {
    final uid = _currentUid;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final sizeKb = (bytes.lengthInBytes / 1024).round();

      bool savedToFirestore = false;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('scans')
            .add({
          'title': _documentType ?? 'Document Scan',
          'imageBase64': base64String,
          'timestamp': FieldValue.serverTimestamp(),
          'fileSize': '$sizeKb KB',
          'fileName': image.name,
        });
        savedToFirestore = true;
      } catch (_) {
        // Fallback to local session storage if Firestore is unprovisioned or offline
        setState(() {
          _localScans.insert(0, {
            'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
            'title': _documentType ?? 'Document Scan',
            'fileSize': '$sizeKb KB',
            'fileName': image.name,
            'imageBase64': base64String,
            'timestamp': DateTime.now(),
          });
        });
      }

      if (mounted) {
        setState(() {
          _previewImageBytes = bytes;
          _previewTitle = _documentType;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D9488),
            content: Row(
              children: [
                Icon(
                  savedToFirestore ? Icons.cloud_done : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(savedToFirestore
                    ? 'Scan saved to your Firestore records!'
                    : 'Scan saved to session records!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Failed to process scan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteScan(String docId) async {
    final uid = _currentUid;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to remove this scan from your records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
            .collection('scans')
            .doc(docId)
            .delete();
      } catch (_) {}
      setState(() {
        _localScans.removeWhere((item) => item['id'] == docId);
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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                          Icons.qr_code_scanner,
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
                              'Scan Documents',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Preserve vaccinations, medical reports, and certificates securely in Firestore.',
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

                  const SizedBox(height: 24),

                  // Action Upload Card
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
                            'Digitize New Document',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Document Type Selector
                          DropdownButtonFormField<String>(
                            initialValue: _documentType,
                            decoration: const InputDecoration(
                              labelText: 'Document Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _docTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _documentType = val;
                              });
                            },
                          ),
                          const SizedBox(height: 18),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading
                                      ? null
                                      : () => _pickAndSaveImage(ImageSource.gallery),
                                  icon: _isUploading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.photo_library_outlined),
                                  label: Text(_isUploading ? 'Uploading...' : 'Choose from Gallery'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUploading
                                      ? null
                                      : () => _pickAndSaveImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Capture with Camera'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Active / Just Uploaded Preview
                  if (_previewImageBytes != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Current Preview: ${_previewTitle ?? ""}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: primaryTeal.withValues(alpha: 0.3)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: const Color(0xFFCCFBF1),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploaded to Cloud Records',
                                  style: TextStyle(
                                    color: const Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _previewImageBytes = null),
                                ),
                              ],
                            ),
                          ),
                          Image.memory(
                            _previewImageBytes!,
                            height: 260,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Cloud Firestore Saved Scans List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cloud Scans History',
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
                        .collection('scans')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final List<Map<String, dynamic>> displayItems = [];

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        for (final doc in snapshot.data!.docs) {
                          final data = (doc.data() as Map<String, dynamic>?) ?? {};
                          DateTime? date;
                          if (data['timestamp'] is Timestamp) {
                            date = (data['timestamp'] as Timestamp).toDate();
                          } else if (data['timestamp'] is DateTime) {
                            date = data['timestamp'] as DateTime;
                          }
                          displayItems.add({
                            'id': doc.id,
                            'title': data['title'] ?? 'Pet Document',
                            'imageBase64': data['imageBase64'],
                            'timestamp': date,
                            'fileSize': data['fileSize'] ?? '',
                            'fileName': data['fileName'] ?? '',
                            'isCloud': true,
                          });
                        }
                      }

                      // Append local scans
                      for (final local in _localScans) {
                        if (!displayItems.any((it) => it['id'] == local['id'])) {
                          displayItems.add(local);
                        }
                      }

                      // Loading state if nothing local either
                      if (snapshot.connectionState == ConnectionState.waiting && displayItems.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                          ),
                        );
                      }

                      // Empty state
                      if (displayItems.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.document_scanner_outlined,
                                  size: 32,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No saved scans yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Upload from gallery or snap a photo using the buttons above. Scans are saved directly to your records.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        );
                      }

                      // Grid of Saved Scans
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
                                      'Displaying session records. (To enable cloud sync across devices, create the Firestore database in Firebase Console).',
                                      style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final count = constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 450 ? 2 : 1);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayItems.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: count,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.85,
                                ),
                                itemBuilder: (context, index) {
                                  final item = displayItems[index];
                                  final docId = item['id'] as String;
                                  final title = item['title'] as String? ?? 'Pet Document';
                                  final base64 = item['imageBase64'] as String?;
                                  final timestamp = item['timestamp'] as DateTime?;
                                  final size = item['fileSize'] as String? ?? '';
                                  final isCloud = item['isCloud'] == true;

                                  Uint8List? imageBytes;
                                  if (base64 != null && base64.isNotEmpty) {
                                    try {
                                      imageBytes = base64Decode(base64);
                                    } catch (_) {}
                                  }

                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () {
                                        if (imageBytes != null) {
                                          setState(() {
                                            _previewImageBytes = imageBytes;
                                            _previewTitle = title;
                                          });
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              color: const Color(0xFFF1F5F9),
                                              width: double.infinity,
                                              child: imageBytes != null
                                                  ? Image.memory(
                                                      imageBytes,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.image_not_supported_outlined,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () => _deleteScan(docId),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          isCloud ? Icons.cloud_done : Icons.storage_outlined,
                                                          size: 13,
                                                          color: const Color(0xFF0D9488),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          timestamp != null
                                                              ? '${timestamp.day}/${timestamp.month}/${timestamp.year}'
                                                              : 'Saved',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (size.isNotEmpty)
                                                      Text(
                                                        size,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF94A3B8),
                                                        ),
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
                                },
                              );
                            },
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
