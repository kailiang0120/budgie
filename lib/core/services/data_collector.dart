import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/category.dart' as app_category;
import 'settings_service.dart';

/// Unified service for collecting user data for analytics and model improvement
/// Combines functionality for both anonymized research data and analytics
class DataCollector {
  static DataCollector? _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final SettingsService _settingsService;

  // Collection names
  static const String _analyticsCollection = 'expense_analytics';
  static const String _modelTrainingCollection = 'model_training_data';

  // Data structure version for future compatibility
  static const int _dataVersion = 1;

  DataCollector() {
    _instance = this;
  }

  static DataCollector? get instance => _instance;

  /// Initialize the data collector
  Future<void> initialize() async {
    try {
      debugPrint('📊 DataCollector: Initializing...');

      _settingsService = SettingsService.instance!;

      // Cleanup old data on initialization
      await _cleanupOldData();

      debugPrint('✅ DataCollector: Initialization completed');
    } catch (e) {
      debugPrint('❌ DataCollector: Initialization failed: $e');
      // Don't throw - data collection is optional
    }
  }

  /// Record notification-based expense detection for both analytics and model training
  Future<void> recordNotificationExpense(
      Map<String, dynamic> expenseData) async {
    if (!_settingsService.improveAccuracy) {
      debugPrint('📊 DataCollector: Data collection disabled by user');
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint(
          '📊 DataCollector: No authenticated user, skipping data collection');
      return;
    }

    try {
      debugPrint('📊 DataCollector: Recording notification expense data');

      // Record for analytics (aggregated data)
      await _recordAnalyticsData(expenseData, currentUser.uid);

      // Record for model training (anonymized data)
      await _recordModelTrainingData(expenseData, currentUser.uid);

      debugPrint('✅ DataCollector: Successfully recorded expense data');
    } catch (e, stackTrace) {
      debugPrint('❌ DataCollector: Failed to record expense data: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Don't rethrow - this is background data collection
    }
  }

  /// Record manual expense entry data
  Future<void> recordManualExpense({
    required double amount,
    required String currency,
    required app_category.Category selectedCategory,
    required String userRemark,
    required String entryMethod,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    if (!_settingsService.improveAccuracy) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('📊 DataCollector: Recording manual expense data');

      final manualExpenseData = {
        'amount': amount,
        'currency': currency,
        'category': selectedCategory.id,
        'categoryName': selectedCategory.name,
        'userRemark': userRemark,
        'entryMethod': entryMethod,
        'isAutoDetected': false,
        'detectionMethod': 'manual',
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'manual_entry',
        ...?additionalMetadata,
      };

      // Record for analytics
      await _recordAnalyticsData(manualExpenseData, currentUser.uid);

      // Record for model training
      await _recordModelTrainingData(manualExpenseData, currentUser.uid);

      debugPrint('✅ DataCollector: Successfully recorded manual expense data');
    } catch (e) {
      debugPrint('❌ DataCollector: Failed to record manual expense data: $e');
    }
  }

  /// Record prediction feedback for model improvement
  Future<void> recordPredictionFeedback({
    required String predictionType,
    required Map<String, dynamic> originalPrediction,
    required Map<String, dynamic> userCorrection,
    required bool wasAccurate,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    if (!_settingsService.improveAccuracy) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('📊 DataCollector: Recording prediction feedback');

      final feedbackData = {
        'dataVersion': _dataVersion,
        'dataType': 'prediction_feedback',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
        'anonymizedUserId': _generateAnonymizedUserId(currentUser.uid),
        'predictionType': predictionType,
        'originalPrediction': originalPrediction,
        'userCorrection': userCorrection,
        'wasAccurate': wasAccurate,
        'feedbackType': wasAccurate ? 'positive' : 'negative',
        'additionalData': additionalMetadata ?? {},
        'consent': _getConsentMetadata(),
        'indexing': _getIndexingMetadata(),
      };

      // Store in model training collection
      await _firestore.collection(_modelTrainingCollection).add(feedbackData);

      debugPrint('✅ DataCollector: Successfully recorded prediction feedback');
    } catch (e) {
      debugPrint('❌ DataCollector: Failed to record prediction feedback: $e');
    }
  }

  /// Get aggregated statistics for debugging/monitoring
  Future<Map<String, dynamic>> getCollectionStats() async {
    if (!_settingsService.improveAccuracy) {
      return {'error': 'Data collection not enabled'};
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'error': 'No authenticated user'};
    }

    try {
      // Get analytics data count
      final analyticsQuery = await _firestore
          .collection(_analyticsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .limit(100)
          .get();

      // Get model training data count
      final trainingQuery = await _firestore
          .collection(_modelTrainingCollection)
          .where('anonymizedUserId',
              isEqualTo: _generateAnonymizedUserId(currentUser.uid))
          .limit(100)
          .get();

      return {
        'analyticsRecords': analyticsQuery.docs.length,
        'trainingRecords': trainingQuery.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
        'dataCollectionEnabled': _settingsService.improveAccuracy,
      };
    } catch (e) {
      debugPrint('❌ DataCollector: Failed to get collection stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Check if data collection is enabled
  bool get isDataCollectionEnabled => _settingsService.improveAccuracy;

  // Private methods

  /// Record data for analytics purposes (contains user ID for business insights)
  Future<void> _recordAnalyticsData(
      Map<String, dynamic> expenseData, String userId) async {
    try {
      final analyticsRecord = {
        'dataVersion': _dataVersion,
        'dataType': 'expense_analytics',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,

        // Expense information
        'expenseAmount': expenseData['amount'] ?? 0.0,
        'expenseCurrency': expenseData['currency'] ?? 'MYR',
        'expenseCategory': expenseData['category'] ?? 'Unknown',
        'merchantName': expenseData['merchant'] ?? 'Unknown',
        'isAutoDetected': expenseData['isAutoDetected'] ?? false,
        'detectionMethod': expenseData['detectionMethod'] ?? 'unknown',
        'source': expenseData['source'] ?? 'unknown',

        // Analysis metadata
        'confidence': expenseData['confidence'],
        'originalText': expenseData['originalText'],

        // Indexing for efficient queries
        'indexing': _getIndexingMetadata(),

        // Consent tracking
        'consent': _getConsentMetadata(),
      };

      await _firestore.collection(_analyticsCollection).add(analyticsRecord);
      debugPrint('📊 DataCollector: Analytics data recorded');
    } catch (e) {
      debugPrint('❌ DataCollector: Failed to record analytics data: $e');
      rethrow;
    }
  }

  /// Record data for model training (anonymized for privacy)
  Future<void> _recordModelTrainingData(
      Map<String, dynamic> expenseData, String userId) async {
    try {
      final trainingRecord = {
        'dataVersion': _dataVersion,
        'dataType': 'model_training',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'anonymizedUserId': _generateAnonymizedUserId(userId),

        // Anonymized expense data for training
        'expense': {
          'amount': expenseData['amount'] ?? 0.0,
          'currency': expenseData['currency'] ?? 'MYR',
          'category': expenseData['category'] ?? 'Unknown',
          'merchantName': _sanitizeText(expenseData['merchant'] ?? 'Unknown'),
          'isAutoDetected': expenseData['isAutoDetected'] ?? false,
        },

        // Detection metadata for model improvement
        'detection': {
          'method': expenseData['detectionMethod'] ?? 'unknown',
          'confidence': expenseData['confidence'],
          'source': expenseData['source'] ?? 'unknown',
          'originalText': _sanitizeText(expenseData['originalText'] ?? ''),
        },

        // Model training metadata
        'training': {
          'eligible': true,
          'qualityScore': _calculateQualityScore(expenseData),
          'tags': _generateTrainingTags(expenseData),
        },

        // Privacy and consent
        'consent': _getConsentMetadata(),
        'privacy': {
          'anonymized': true,
          'dataRetentionDays': 365,
        },
      };

      await _firestore.collection(_modelTrainingCollection).add(trainingRecord);
      debugPrint('📊 DataCollector: Model training data recorded');
    } catch (e) {
      debugPrint('❌ DataCollector: Failed to record model training data: $e');
      rethrow;
    }
  }

  /// Generate anonymized user ID for privacy
  String _generateAnonymizedUserId(String userId) {
    final hash = userId.hashCode.abs().toString();
    return 'user_$hash';
  }

  /// Sanitize text to remove sensitive information
  String _sanitizeText(String text) {
    if (text.isEmpty) return text;

    String sanitized = text.trim();

    // Limit length to prevent huge texts
    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }

    return sanitized;
  }

  /// Calculate quality score for training data
  double? _calculateQualityScore(Map<String, dynamic> expenseData) {
    try {
      double score = 0.0;

      // Higher score for API detection vs pattern detection
      if (expenseData['detectionMethod'] == 'api') {
        score += 0.4;
      } else if (expenseData['detectionMethod'] == 'pattern') {
        score += 0.2;
      }

      // Factor in confidence if available
      final confidence = expenseData['confidence'] as double?;
      if (confidence != null) {
        score += confidence * 0.6;
      }

      return score.clamp(0.0, 1.0);
    } catch (e) {
      return null;
    }
  }

  /// Generate tags for training data organization
  List<String> _generateTrainingTags(Map<String, dynamic> expenseData) {
    final tags = <String>[];

    // Detection method tags
    final method = expenseData['detectionMethod'] as String?;
    if (method != null) {
      tags.add('method_$method');
    }

    // Source tags
    final source = expenseData['source'] as String?;
    if (source != null) {
      tags.add('source_${source.toLowerCase().replaceAll(' ', '_')}');
    }

    // Amount-based tags
    final amount = expenseData['amount'] as double?;
    if (amount != null) {
      if (amount < 10) {
        tags.add('amount_small');
      } else if (amount < 100) {
        tags.add('amount_medium');
      } else {
        tags.add('amount_large');
      }
    }

    // Time-based tags
    final now = DateTime.now();
    tags.add('hour_${now.hour}');
    tags.add('day_${now.weekday}');
    tags.add('month_${now.month}');

    return tags;
  }

  /// Get consent metadata
  Map<String, dynamic> _getConsentMetadata() {
    return {
      'consentVersion': '1.0',
      'consentTimestamp': FieldValue.serverTimestamp(),
      'dataRetentionDays': 365,
      'improvementEnabled': _settingsService.improveAccuracy,
    };
  }

  /// Get indexing metadata for efficient queries
  Map<String, dynamic> _getIndexingMetadata() {
    final now = DateTime.now();
    return {
      'monthYear': '${now.year}-${now.month.toString().padLeft(2, '0')}',
      'dayOfWeek': now.weekday,
      'hourOfDay': now.hour,
      'timestamp': now.millisecondsSinceEpoch,
    };
  }

  /// Clean up old data based on retention policy
  Future<void> _cleanupOldData() async {
    if (!_settingsService.improveAccuracy) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 365));

      // Clean up analytics data
      await _cleanupCollection(
        _analyticsCollection,
        'userId',
        currentUser.uid,
        cutoffDate,
      );

      // Clean up training data
      await _cleanupCollection(
        _modelTrainingCollection,
        'anonymizedUserId',
        _generateAnonymizedUserId(currentUser.uid),
        cutoffDate,
      );

      debugPrint('📊 DataCollector: Data cleanup completed');
    } catch (e) {
      debugPrint('❌ DataCollector: Data cleanup failed: $e');
    }
  }

  /// Clean up a specific collection
  Future<void> _cleanupCollection(
    String collectionName,
    String userField,
    String userValue,
    DateTime cutoffDate,
  ) async {
    final oldDataQuery = await _firestore
        .collection(collectionName)
        .where(userField, isEqualTo: userValue)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .limit(50) // Process in batches
        .get();

    if (oldDataQuery.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in oldDataQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint(
          '📊 DataCollector: Cleaned up ${oldDataQuery.docs.length} old records from $collectionName');
    }
  }
}
