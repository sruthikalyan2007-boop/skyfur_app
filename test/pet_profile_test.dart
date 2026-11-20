import 'package:flutter_test/flutter_test.dart';
import 'package:skyfur_app/services/pet_profile_service.dart';

void main() {
  group('PetProfile Model & Null Fallbacks', () {
    test('PetProfile parses complete valid map', () {
      final map = {
        'name': 'Bella',
        'breed': 'Golden Retriever',
        'breedPhotoUrl': 'https://images.dog.ceo/breeds/retriever-golden/n02099601_100.jpg',
        'age': '2 years old',
        'careAreas': ['skin_coat', 'joints'],
        'gender': 'Female',
        'microchip': '985141009988776',
      };

      final profile = PetProfile.fromMap(map);

      expect(profile.name, 'Bella');
      expect(profile.breed, 'Golden Retriever');
      expect(profile.breedPhotoUrl, 'https://images.dog.ceo/breeds/retriever-golden/n02099601_100.jpg');
      expect(profile.age, '2 years old');
      expect(profile.careAreas, ['skin_coat', 'joints']);
      expect(profile.gender, 'Female');
      expect(profile.microchip, '985141009988776');
    });

    test('PetProfile safely handles empty/null map with defaults', () {
      final emptyMap = <String, dynamic>{};

      final profile = PetProfile.fromMap(emptyMap);

      expect(profile.name, 'Pet');
      expect(profile.breed, 'Golden Retriever');
      expect(profile.breedPhotoUrl, '');
      expect(profile.age, '3 years old');
      expect(profile.careAreas, isEmpty);
      expect(profile.gender, isNull);
      expect(profile.microchip, isNull);
    });

    test('PetProfile toMap produces serializable structure', () {
      const profile = PetProfile(
        name: 'Charlie',
        breed: 'Labrador',
        breedPhotoUrl: 'https://example.com/dog.jpg',
        age: '1 year old',
        careAreas: ['weight', 'dental'],
      );

      final map = profile.toMap();

      expect(map['name'], 'Charlie');
      expect(map['breed'], 'Labrador');
      expect(map['breedPhotoUrl'], 'https://example.com/dog.jpg');
      expect(map['age'], '1 year old');
      expect(map['careAreas'], ['weight', 'dental']);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('PetProfileService handles local cache seamlessly', () {
      const profile = PetProfile(
        name: 'Luna',
        breed: 'Beagle',
        breedPhotoUrl: '',
        age: '4 years old',
        careAreas: ['skin_coat'],
      );

      PetProfileService.setLocalProfile(profile);
      expect(PetProfileService.localProfile, isNotNull);
      expect(PetProfileService.localProfile!.name, 'Luna');
    });
  });
}
