import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

import '../helpers/fake_storage_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Categories Persistence & Backup', () {
    test('Categories are saved to storage on initialization and retrieved correctly', () async {
      final storage = FakeStorageService();
      final repo = HabitsRepository.test(storage);
      await repo.initialize();

      // Ensure storage has saved categories
      final categoriesJson = await storage.getString(HabitsRepository.categoriesKey);
      expect(categoriesJson, isNotNull);
      expect(categoriesJson, isNotEmpty);

      final categories = repo.getCategories();
      expect(categories, isNotEmpty);
      expect(categories.length, greaterThanOrEqualTo(3));

      // Add a new custom category
      const customCategory = Category(
        id: 'fitness',
        name: 'Fitness Custom',
        color: Colors.red,
        icon: Icons.fitness_center,
      );
      await repo.addCategory(customCategory);

      // Verify it is in storage
      final updatedJson = await storage.getString(HabitsRepository.categoriesKey);
      expect(updatedJson, contains('Fitness Custom'));

      // Create a fresh repo instance on same storage and initialize
      final repo2 = HabitsRepository.test(storage);
      await repo2.initialize();

      expect(repo2.getCategories().any((c) => c.id == 'fitness'), isTrue);
      final found = repo2.getCategoryById('fitness');
      expect(found, isNotNull);
      expect(found!.name, 'Fitness Custom');
    });

    test('Full export and restore payload preserves custom categories and habits', () async {
      final sourceStorage = FakeStorageService();
      final sourceRepo = HabitsRepository.test(sourceStorage);
      await sourceRepo.initialize();

      const customCat = Category(
        id: 'guitar',
        name: 'Guitarra',
        color: Colors.amber,
        icon: Icons.music_note,
      );
      await sourceRepo.addCategory(customCat);

      // Export payload
      final habitsJson = await sourceStorage.getString(HabitsRepository.habitsKey) ?? '[]';
      final categoriesJson = await sourceStorage.getString(HabitsRepository.categoriesKey) ?? '[]';
      final logsJson = await sourceStorage.getString(HabitsRepository.logsKey) ?? '[]';

      // Import to a new target storage
      final targetStorage = FakeStorageService();
      await targetStorage.setString(HabitsRepository.habitsKey, habitsJson);
      await targetStorage.setString(HabitsRepository.categoriesKey, categoriesJson);
      await targetStorage.setString(HabitsRepository.logsKey, logsJson);

      final targetRepo = HabitsRepository.test(targetStorage);
      await targetRepo.initialize();

      expect(targetRepo.getCategories().any((c) => c.id == 'guitar'), isTrue);
      final guitarCategory = targetRepo.getCategoryById('guitar');
      expect(guitarCategory, isNotNull);
      expect(guitarCategory!.name, 'Guitarra');
    });
  });
}
