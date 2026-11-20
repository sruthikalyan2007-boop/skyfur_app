import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_profile_service.dart';

class PetCareScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const PetCareScreen({super.key, this.onNavigate});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  
  // Step 1: Pet profile data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  // Dog CEO API state
  Timer? _breedDebounce;
  String? _breedImageUrl;
  bool _isLoadingBreedImage = false;
  bool _breedNotFound = false;
  String? _lastQueriedBreed;

  // Breed suggestions
  final List<String> _commonBreeds = [
    'Golden Retriever',
    'Labrador Retriever',
    'German Shepherd',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Pug',
    'Husky',
    'Chihuahua',
  ];
  
  // Recommended products
  final List<RecommendedProduct> _recommendedProducts = [
    RecommendedProduct(
      title: 'Premium Skin & Coat Supplement',
      matchPercentage: 98,
      description: 'Omega-3 rich formula for healthy skin and shiny coat',
      icon: Icons.spa,
    ),
    RecommendedProduct(
      title: 'Weight Management Food',
      matchPercentage: 95,
      description: 'Balanced nutrition for optimal weight maintenance',
      icon: Icons.restaurant_menu,
    ),
    RecommendedProduct(
      title: 'Joint Support Chews',
      matchPercentage: 92,
      description: 'Glucosamine and chondroitin for joint health',
      icon: Icons.favorite,
    ),
  ];
  
  // Step 2: Care focus areas
  final Set<String> _selectedCareAreas = {};
  final List<CareArea> _careAreas = [
    CareArea(
      id: 'skin_coat',
      name: 'Skin & Coat',
      icon: Icons.brush,
      description: 'Healthy skin and shiny coat',
    ),
    CareArea(
      id: 'weight',
      name: 'Healthy Weight',
      icon: Icons.monitor_weight,
      description: 'Optimal weight management',
    ),
    CareArea(
      id: 'joints',
      name: 'Joints & Mobility',
      icon: Icons.accessibility,
      description: 'Joint health and flexibility',
    ),
    CareArea(
      id: 'dental',
      name: 'Dental Care',
      icon: Icons.sentiment_satisfied,
      description: 'Oral health and hygiene',
    ),
  ];
  
  // Step 3: Success state
  bool _carePlanCreated = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onProfileChanged);
    _breedController.addListener(_onBreedInputChanged);
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final existing = PetProfileService.localProfile;
    if (existing != null) {
      if (_nameController.text.isEmpty && existing.name.isNotEmpty && existing.name != 'Pet') {
        _nameController.text = existing.name;
      }
      if (_breedController.text.isEmpty && existing.breed.isNotEmpty) {
        _breedController.text = existing.breed;
      }
      if (_ageController.text.isEmpty && existing.age.isNotEmpty) {
        _ageController.text = existing.age;
      }
      if (_breedImageUrl == null && existing.breedPhotoUrl.isNotEmpty) {
        _breedImageUrl = existing.breedPhotoUrl;
      }
      if (_selectedCareAreas.isEmpty && existing.careAreas.isNotEmpty) {
        _selectedCareAreas.addAll(existing.careAreas);
      }
    }
  }

  void _onProfileChanged() {
    setState(() {
      // Trigger rebuild to update profile summary
    });
  }

  void _onBreedInputChanged() {
    _onProfileChanged();
    final breed = _breedController.text.trim();
    if (breed.isEmpty) {
      _breedDebounce?.cancel();
      setState(() {
        _breedImageUrl = null;
        _isLoadingBreedImage = false;
        _breedNotFound = false;
        _lastQueriedBreed = null;
      });
      return;
    }

    if (breed == _lastQueriedBreed) return;

    _breedDebounce?.cancel();
    _breedDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchDogBreedImage(breed);
    });
  }

  Future<void> _fetchDogBreedImage(String breedInput) async {
    final clean = breedInput.toLowerCase().trim();
    if (clean.isEmpty) return;

    setState(() {
      _isLoadingBreedImage = true;
      _breedNotFound = false;
      _lastQueriedBreed = breedInput;
    });

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final candidates = <String>[];

    if (words.length >= 2) {
      // Dog CEO API uses "subbreed/masterbreed" or "masterbreed/subbreed"
      candidates.add('${words.last}/${words.first}');
      candidates.add('${words.first}/${words.last}');
      candidates.add(words.join(''));
      candidates.add(words.last);
      candidates.add(words.first);
    } else if (words.isNotEmpty) {
      candidates.add(words.first);
    }

    String? foundImageUrl;

    for (final candidate in candidates) {
      try {
        final uri = Uri.parse('https://dog.ceo/api/breed/$candidate/images/random');
        final response = await http.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['status'] == 'success' && data['message'] is String) {
            foundImageUrl = data['message'] as String;
            break;
          }
        }
      } catch (_) {
        // Fallback to next candidate
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingBreedImage = false;
        if (foundImageUrl != null) {
          _breedImageUrl = foundImageUrl;
          _breedNotFound = false;
        } else {
          _breedImageUrl = null;
          _breedNotFound = true;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty ||
          _breedController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all pet profile fields')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedCareAreas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one care area')),
        );
        return;
      }
    }
    
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _toggleCareArea(String areaId) {
    setState(() {
      if (_selectedCareAreas.contains(areaId)) {
        _selectedCareAreas.remove(areaId);
      } else {
        _selectedCareAreas.add(areaId);
      }
    });
  }

  Future<void> _createCarePlan() async {
    setState(() {
      _carePlanCreated = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_pet_parent_uid';
    final petName = _nameController.text.trim().isEmpty ? 'Milo' : _nameController.text.trim();
    final breed = _breedController.text.trim().isEmpty ? 'Golden Retriever' : _breedController.text.trim();
    final age = _ageController.text.trim().isEmpty ? '3 years old' : _ageController.text.trim();
    final photoUrl = _breedImageUrl ?? '';
    final careAreas = _selectedCareAreas.toList();

    final profile = PetProfile(
      name: petName,
      breed: breed,
      breedPhotoUrl: photoUrl,
      age: age,
      careAreas: careAreas,
      updatedAt: DateTime.now(),
    );

    final savedCloud = await PetProfileService.saveProfile(uid, profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D9488),
          content: Row(
            children: [
              Icon(savedCloud ? Icons.cloud_done : Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(savedCloud
                  ? 'Pet profile saved to Firestore & live in Pet Details!'
                  : 'Pet profile created & saved to session!'),
            ],
          ),
        ),
      );
    }
  }

  void _resetFlow() {
    setState(() {
      _currentStep = 1;
      _carePlanCreated = false;
      _selectedCareAreas.clear();
      _nameController.clear();
      _breedController.clear();
      _ageController.clear();
      _breedDebounce?.cancel();
      _breedImageUrl = null;
      _isLoadingBreedImage = false;
      _breedNotFound = false;
      _lastQueriedBreed = null;
    });
  }

  @override
  void dispose() {
    _breedDebounce?.cancel();
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title and description
                Text(
                  'Pet Care Tips',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Access daily care tips, nutrition advice, and wellness guides to keep your pet healthy and happy. Expert knowledge at your fingertips.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 24),
                
                // Profile summary bar
                _buildProfileSummaryBar(),
                
                const SizedBox(height: 24),
                
                // Progress indicator
                if (!_carePlanCreated) _buildProgressIndicator(),
                
                const SizedBox(height: 32),
                
                // Step content
                if (_carePlanCreated)
                  _buildSuccessState()
                else
                  _buildStepContent(),
                
                const SizedBox(height: 24),
                
                // Navigation buttons
                if (!_carePlanCreated) _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummaryBar() {
    final hasProfile = _nameController.text.trim().isNotEmpty && 
                       _breedController.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Paw icon avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Profile info
          Expanded(
            child: hasProfile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _breedController.text.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  )
                : Text(
                    'No profile yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (index) {
            final stepNumber = index + 1;
            final isCompleted = stepNumber < _currentStep;
            final isCurrent = stepNumber == _currentStep;
            
            return Expanded(
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 18,
                            )
                          : Text(
                              stepNumber.toString(),
                              style: TextStyle(
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (index < _totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Step $_currentStep of $_totalSteps',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildPetProfileStep();
      case 2:
        return _buildCareAreasStep();
      case 3:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPetProfileStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pet Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            
            // Pet name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Pet Name',
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Breed with dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    labelText: 'Breed',
                    prefixIcon: const Icon(Icons.pets),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String breed) {
                        _breedController.text = breed;
                      },
                      itemBuilder: (BuildContext context) {
                        return _commonBreeds.map((String breed) {
                          return PopupMenuItem<String>(
                            value: breed,
                            child: Row(
                              children: [
                                const Icon(Icons.pets, size: 20),
                                const SizedBox(width: 8),
                                Text(breed),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Common breeds: ${_commonBreeds.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                _buildBreedPreviewCard(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Age
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Age (years)',
                prefixIcon: const Icon(Icons.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareAreasStep() {
    final petName = _nameController.text.trim().isEmpty 
        ? 'your pet' 
        : _nameController.text.trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Care Focus Areas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _careAreas.length,
          itemBuilder: (context, index) {
            final area = _careAreas[index];
            final isSelected = _selectedCareAreas.contains(area.id);
            
            return _CareAreaCard(
              area: area,
              isSelected: isSelected,
              onTap: () => _toggleCareArea(area.id),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // Recommended products section
        if (_nameController.text.trim().isNotEmpty) ...[
          Text(
            'Recommended for $petName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._recommendedProducts.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendedProductCard(product: product),
          )),
        ],
      ],
    );
  }

  Widget _buildSummaryStep() {
    final selectedAreas = _careAreas
        .where((area) => _selectedCareAreas.contains(area.id))
        .toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Care Plan Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            
            // Pet info
            _SummarySection(
              title: 'Pet Information',
              children: [
                _SummaryRow(label: 'Name', value: _nameController.text),
                _SummaryRow(label: 'Breed', value: _breedController.text),
                _SummaryRow(label: 'Age', value: '${_ageController.text} years'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Care areas
            _SummarySection(
              title: 'Selected Care Areas',
              children: selectedAreas.map((area) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        area.icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(area.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Care Plan Created!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your personalized care plan for ${_nameController.text} is ready. We\'ll provide tailored tips and recommendations based on your selections.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(6);
                      }
                    },
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('View Pet Profile Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetFlow,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Create Another Plan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _currentStep == _totalSteps ? _createCarePlan : _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_currentStep == _totalSteps ? 'Create Care Plan' : 'Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildBreedPreviewCard() {
    if (_isLoadingBreedImage) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Fetching verified breed photo from Dog CEO API...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_breedImageUrl != null) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFCCFBF1),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dog CEO Verified: ${_lastQueriedBreed ?? ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_lastQueriedBreed != null) {
                        _fetchDogBreedImage(_lastQueriedBreed!);
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: Color(0xFF0F766E)),
                        SizedBox(width: 4),
                        Text(
                          'New Photo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Image.network(
              _breedImageUrl!,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 190,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                  ),
                );
              },
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: const Color(0xFFF8FAFC),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 36, color: Color(0xFF0D9488)),
                      SizedBox(height: 4),
                      Text('Preview image loaded', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_breedNotFound && (_lastQueriedBreed?.isNotEmpty ?? false)) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pets, size: 24, color: Color(0xFF0D9488)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Dog CEO photo for "$_lastQueriedBreed"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Using fallback icon. You can proceed with your custom breed care plan!',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _CareAreaCard extends StatelessWidget {
  final CareArea area;
  final bool isSelected;
  final VoidCallback onTap;

  const _CareAreaCard({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                area.icon,
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                area.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                area.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
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

class _SummarySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SummarySection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class CareArea {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  CareArea({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

class RecommendedProduct {
  final String title;
  final int matchPercentage;
  final String description;
  final IconData icon;

  RecommendedProduct({
    required this.title,
    required this.matchPercentage,
    required this.description,
    required this.icon,
  });
}

class _RecommendedProductCard extends StatelessWidget {
  final RecommendedProduct product;

  const _RecommendedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                product.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.matchPercentage}% Match',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    maxLines: 2,
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
