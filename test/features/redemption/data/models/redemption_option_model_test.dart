import 'package:flutter_test/flutter_test.dart';
import 'package:ai_rewards_system/features/redemption/data/models/models.dart';
import 'package:ai_rewards_system/features/redemption/domain/entities/entities.dart';

void main() {
  group('RedemptionOptionModel', () {
    final testDateTime = DateTime.parse('2024-01-15T10:30:00Z');
    final testExpiryDateTime = DateTime.parse('2024-02-15T10:30:00Z');

    final testModel = RedemptionOptionModel(
      id: 'test_id',
      title: 'Test Option',
      description: 'Test description',
      categoryId: 'electronics',
      requiredPoints: 1000,
      isActive: true,
      createdAt: testDateTime,
      updatedAt: testDateTime,
      expiryDate: testExpiryDateTime,
      imageUrl: 'https://example.com/image.jpg',
    );

    const testJson = {
      'id': 'test_id',
      'title': 'Test Option',
      'description': 'Test description',
      'categoryId': 'electronics',
      'requiredPoints': 1000,
      'isActive': true,
      'createdAt': '2024-01-15T10:30:00Z',
      'updatedAt': '2024-01-15T10:30:00Z',
      'expiryDate': '2024-02-15T10:30:00Z',
      'imageUrl': 'https://example.com/image.jpg',
    };

    group('fromJson', () {
      test('should create model from valid JSON', () {
        // Act
        final model = RedemptionOptionModel.fromJson(testJson);

        // Assert
        expect(model.id, 'test_id');
        expect(model.title, 'Test Option');
        expect(model.description, 'Test description');
        expect(model.categoryId, 'electronics');
        expect(model.requiredPoints, 1000);
        expect(model.isActive, true);
        expect(model.createdAt, testDateTime);
        expect(model.updatedAt, testDateTime);
        expect(model.expiryDate, testExpiryDateTime);
        expect(model.imageUrl, 'https://example.com/image.jpg');
      });

      test('should handle missing optional fields', () {
        // Arrange
        final jsonWithoutOptional = {
          'id': 'test_id',
          'title': 'Test Option',
          'description': 'Test description',
          'categoryId': 'electronics',
          'requiredPoints': 1000,
          'isActive': true,
          'createdAt': '2024-01-15T10:30:00Z',
        };

        // Act
        final model = RedemptionOptionModel.fromJson(jsonWithoutOptional);

        // Assert
        expect(model.id, 'test_id');
        expect(model.updatedAt, null);
        expect(model.expiryDate, null);
        expect(model.imageUrl, null);
      });

      test('should handle null optional fields', () {
        // Arrange
        final jsonWithNulls = Map<String, dynamic>.from(testJson);
        jsonWithNulls['updatedAt'] = null;
        jsonWithNulls['expiryDate'] = null;
        jsonWithNulls['imageUrl'] = null;

        // Act
        final model = RedemptionOptionModel.fromJson(jsonWithNulls);

        // Assert
        expect(model.updatedAt, null);
        expect(model.expiryDate, null);
        expect(model.imageUrl, null);
      });
    });

    group('toJson', () {
      test('should convert model to JSON', () {
        // Act
        final json = testModel.toJson();

        // Assert
        expect(json['id'], 'test_id');
        expect(json['title'], 'Test Option');
        expect(json['description'], 'Test description');
        expect(json['categoryId'], 'electronics');
        expect(json['requiredPoints'], 1000);
        expect(json['isActive'], true);
        expect(json['createdAt'], '2024-01-15T10:30:00.000Z');
        expect(json['updatedAt'], '2024-01-15T10:30:00.000Z');
        expect(json['expiryDate'], '2024-02-15T10:30:00.000Z');
        expect(json['imageUrl'], 'https://example.com/image.jpg');
      });

      test('should handle null optional fields in JSON', () {
        // Arrange
        final modelWithNulls = RedemptionOptionModel(
          id: 'test_id',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
          updatedAt: null,
          expiryDate: null,
          imageUrl: null,
        );

        // Act
        final json = modelWithNulls.toJson();

        // Assert
        expect(json.containsKey('updatedAt'), false);
        expect(json.containsKey('expiryDate'), false);
        expect(json.containsKey('imageUrl'), false);
      });
    });

    group('toEntity', () {
      test('should convert model to domain entity', () {
        // Act
        final entity = testModel.toEntity();

        // Assert
        expect(entity, isA<RedemptionOption>());
        expect(entity.id, 'test_id');
        expect(entity.title, 'Test Option');
        expect(entity.description, 'Test description');
        expect(entity.categoryId, 'electronics');
        expect(entity.requiredPoints, 1000);
        expect(entity.isActive, true);
        expect(entity.createdAt, testDateTime);
      });

      test('should handle null optional fields when converting to entity', () {
        // Arrange
        final modelWithNulls = RedemptionOptionModel(
          id: 'test_id',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
          updatedAt: null,
          expiryDate: null,
          imageUrl: null,
        );

        // Act
        final entity = modelWithNulls.toEntity();

        // Assert
        expect(entity.updatedAt, null);
        expect(entity.expiryDate, null);
        expect(entity.imageUrl, null);
      });
    });

    group('fromEntity', () {
      test('should create model from domain entity', () {
        // Arrange
        final entity = RedemptionOption(
          id: 'test_id',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
          updatedAt: testDateTime,
          expiryDate: testExpiryDateTime,
          imageUrl: 'https://example.com/image.jpg',
        );

        // Act
        final model = RedemptionOptionModel.fromEntity(entity);

        // Assert
        expect(model.id, 'test_id');
        expect(model.title, 'Test Option');
        expect(model.description, 'Test description');
        expect(model.categoryId, 'electronics');
        expect(model.requiredPoints, 1000);
        expect(model.isActive, true);
        expect(model.createdAt, testDateTime);
        expect(model.updatedAt, testDateTime);
        expect(model.expiryDate, testExpiryDateTime);
        expect(model.imageUrl, 'https://example.com/image.jpg');
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final model1 = RedemptionOptionModel(
          id: 'test_id',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
        );

        final model2 = RedemptionOptionModel(
          id: 'test_id',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final model1 = RedemptionOptionModel(
          id: 'test_id_1',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
        );

        final model2 = RedemptionOptionModel(
          id: 'test_id_2',
          title: 'Test Option',
          description: 'Test description',
          categoryId: 'electronics',
          requiredPoints: 1000,
          isActive: true,
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(model1, isNot(equals(model2)));
        expect(model1.hashCode, isNot(equals(model2.hashCode)));
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Act
        final stringRepresentation = testModel.toString();

        // Assert
        expect(stringRepresentation, contains('RedemptionOption'));
        expect(stringRepresentation, contains('test_id'));
        expect(stringRepresentation, contains('Test Option'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final updated = testModel.copyWith(
          title: 'Updated Title',
          requiredPoints: 2000,
        );

        // Assert
        expect(updated.title, 'Updated Title');
        expect(updated.requiredPoints, 2000);
        expect(updated.id, testModel.id);
        expect(updated.description, testModel.description);
        expect(updated.categoryId, testModel.categoryId);
      });

      test('should preserve original values when no updates provided', () {
        // Act
        final copy = testModel.copyWith();

        // Assert
        expect(copy, equals(testModel));
      });
    });
  });
}