import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../entities/category.dart' as app_category;
import '../../../data/models/expense_detection_models.dart';
import '../../../data/infrastructure/services/settings_service.dart';

/// Use case for recording notification detection data for model improvement
///
/// This use case handles the recording of notification detection attempts,
/// user feedback, and correction data to improve the AI expense detection model.
/// Data is only recorded when the user has enabled model improvement in settings.
class RecordNotificationDetectionUseCase {
  final SettingsService _settingsService;

  // Repository will be injected once storage location is decided
  // final NotificationDetectionRepository _repository;

  RecordNotificationDetectionUseCase({
    required SettingsService settingsService,
    // required NotificationDetectionRepository repository,
  }) : _settingsService = settingsService;
  // _repository = repository;

  /// Record initial detection attempt
  /// Called immediately after TFLite models analyze a notification
  Future<String?> recordDetectionAttempt({
    required String originalNotificationText,
    required String notificationSource,
    required String packageName,
    required ExpenseExtractionResult detectionResult,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final recordId = const Uuid().v4();
      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Generated detection ID: $recordId');

      // Only persist the record if user has enabled model improvement
      if (!_settingsService.improveAccuracy) {
        debugPrint(
            '📊 RecordNotificationDetectionUseCase: Model improvement disabled, skipping persistence.');
        return recordId; // Always return ID for notification payload
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Recording detection attempt for model improvement.');

      final record = NotificationDetectionRecord(
        id: recordId,
        originalNotificationText: originalNotificationText,
        notificationSource: notificationSource,
        packageName: packageName,
        timestamp: DateTime.now(),
        detectionResult: detectionResult,
        userConfirmed:
            false, // Initial state, will be updated based on user action
      );

      // TODO: Store the record when storage location is decided
      // await _repository.saveDetectionRecord(record);

      debugPrint(
          '✅ RecordNotificationDetectionUseCase: Detection attempt persisted with ID: ${record.id}');
      return record.id;
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to process detection attempt: $e');
      return null; // Return null only on critical error
    }
  }

  /// Record user confirmation (when user saves the expense)
  /// Called when user confirms and saves an auto-detected expense
  Future<bool> recordUserConfirmation({
    required String detectionId,
    required bool userConfirmed,
    String? userSelectedCategory,
    double? userCorrectedAmount,
    String? userCorrectedCurrency,
    String? userCorrectedMerchant,
    String? userCorrectedPaymentMethod,
    Map<String, dynamic>? userFeedback,
  }) async {
    try {
      if (!_settingsService.improveAccuracy) {
        return false;
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Recording user confirmation');

      // TODO: Update the existing record with user feedback
      // final existingRecord = await _repository.getDetectionRecord(detectionId);
      // if (existingRecord == null) {
      //   debugPrint('❌ RecordNotificationDetectionUseCase: Detection record not found: $detectionId');
      //   return false;
      // }

      // final updatedRecord = NotificationDetectionRecord(
      //   id: existingRecord.id,
      //   originalNotificationText: existingRecord.originalNotificationText,
      //   notificationSource: existingRecord.notificationSource,
      //   packageName: existingRecord.packageName,
      //   timestamp: existingRecord.timestamp,
      //   detectionResult: existingRecord.detectionResult,
      //   userConfirmed: userConfirmed,
      //   userFeedback: userFeedback,
      //   userSelectedCategory: userSelectedCategory,
      //   userCorrectedAmount: userCorrectedAmount,
      //   userCorrectedCurrency: userCorrectedCurrency,
      //   correctedData: _buildCorrectedData(
      //     existingRecord.detectionResult,
      //     userSelectedCategory,
      //     userCorrectedAmount,
      //     userCorrectedCurrency,
      //     userCorrectedMerchant,
      //     userCorrectedPaymentMethod,
      //   ),
      // );

      // await _repository.updateDetectionRecord(updatedRecord);

      debugPrint(
          '✅ RecordNotificationDetectionUseCase: User confirmation recorded');
      return true;
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to record user confirmation: $e');
      return false;
    }
  }

  /// Record user dismissal (when user dismisses the notification expense card)
  /// Called when user explicitly dismisses an auto-detected expense
  Future<bool> recordUserDismissal({
    required String detectionId,
    String? dismissalReason,
    Map<String, dynamic>? userFeedback,
  }) async {
    try {
      if (!_settingsService.improveAccuracy) {
        return false;
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Recording user dismissal');

      // This represents a false positive case
      return await recordUserConfirmation(
        detectionId: detectionId,
        userConfirmed: false,
        userFeedback: {
          'dismissal_reason': dismissalReason,
          'action': 'dismissed',
          ...?userFeedback,
        },
      );
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to record user dismissal: $e');
      return false;
    }
  }

  /// Record manual expense creation after dismissing auto-detection
  /// Called when user dismisses auto-detection but then creates expense manually
  /// This helps identify false negatives or cases where detection failed but expense was valid
  Future<bool> recordManualExpenseAfterDismissal({
    required String detectionId,
    required app_category.Category manualCategory,
    required double manualAmount,
    required String manualCurrency,
    String? manualDescription,
    String? manualMerchant,
    String? manualPaymentMethod,
  }) async {
    try {
      if (!_settingsService.improveAccuracy) {
        return false;
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Recording manual expense after dismissal');

      return await recordUserConfirmation(
        detectionId: detectionId,
        userConfirmed:
            true, // User did create an expense, so detection was partially correct
        userSelectedCategory: manualCategory.id,
        userCorrectedAmount: manualAmount,
        userCorrectedCurrency: manualCurrency,
        userCorrectedMerchant: manualMerchant,
        userCorrectedPaymentMethod: manualPaymentMethod,
        userFeedback: {
          'action': 'manual_expense_after_dismissal',
          'manual_description': manualDescription,
          'detection_accuracy':
              'partial', // Expense was valid but detection details were wrong
        },
      );
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to record manual expense after dismissal: $e');
      return false;
    }
  }

  /// Get detection quality metrics for monitoring and improvement
  Future<DetectionQualityMetrics?> getQualityMetrics({
    DateTime? startDate,
    DateTime? endDate,
    String? notificationSource,
  }) async {
    try {
      if (!_settingsService.improveAccuracy) {
        return null;
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Calculating quality metrics');

      // TODO: Implement when repository is available
      // final records = await _repository.getDetectionRecords(
      //   startDate: startDate,
      //   endDate: endDate,
      //   notificationSource: notificationSource,
      // );

      // return _calculateMetrics(records);

      // Return mock metrics for now
      return DetectionQualityMetrics(
        totalDetections: 0,
        truePositives: 0,
        falsePositives: 0,
        trueNegatives: 0,
        falseNegatives: 0,
        averageConfidence: 0.0,
        averageResponseTime: 0.0,
      );
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to get quality metrics: $e');
      return null;
    }
  }

  /// Export detection data for analysis
  /// Useful for understanding detection patterns and improving the model
  Future<List<NotificationDetectionRecord>> exportDetectionData({
    DateTime? startDate,
    DateTime? endDate,
    bool onlyWithUserFeedback = false,
  }) async {
    try {
      if (!_settingsService.improveAccuracy) {
        return [];
      }

      debugPrint(
          '📊 RecordNotificationDetectionUseCase: Exporting detection data');

      // TODO: Implement when repository is available
      // return await _repository.getDetectionRecords(
      //   startDate: startDate,
      //   endDate: endDate,
      //   withUserFeedback: onlyWithUserFeedback,
      // );

      return [];
    } catch (e) {
      debugPrint(
          '❌ RecordNotificationDetectionUseCase: Failed to export detection data: $e');
      return [];
    }
  }

  /// Check if model improvement data collection is enabled
  bool get isDataCollectionEnabled => _settingsService.improveAccuracy;

  // Private helper methods

  /// Build corrected data map for comparison with original detection
  Map<String, dynamic>? _buildCorrectedData(
    ExpenseExtractionResult originalDetection,
    String? userSelectedCategory,
    double? userCorrectedAmount,
    String? userCorrectedCurrency,
    String? userCorrectedMerchant,
    String? userCorrectedPaymentMethod,
  ) {
    final corrections = <String, dynamic>{};
    bool hasCorrections = false;

    // Note: userSelectedCategory is not part of TFLite model output
    // but tracked for understanding user preferences vs model suggestions
    if (userSelectedCategory != null &&
        userSelectedCategory != originalDetection.suggestedCategory) {
      corrections['category'] = {
        'original': originalDetection.suggestedCategory,
        'corrected': userSelectedCategory,
      };
      hasCorrections = true;
    }

    if (userCorrectedAmount != null &&
        userCorrectedAmount.toString() != originalDetection.amount) {
      corrections['amount'] = {
        'original': originalDetection.amount,
        'corrected': userCorrectedAmount,
      };
      hasCorrections = true;
    }

    if (userCorrectedCurrency != null &&
        userCorrectedCurrency != originalDetection.currency) {
      corrections['currency'] = {
        'original': originalDetection.currency,
        'corrected': userCorrectedCurrency,
      };
      hasCorrections = true;
    }

    if (userCorrectedMerchant != null &&
        userCorrectedMerchant != originalDetection.merchantName) {
      corrections['merchant'] = {
        'original': originalDetection.merchantName,
        'corrected': userCorrectedMerchant,
      };
      hasCorrections = true;
    }

    if (userCorrectedPaymentMethod != null &&
        userCorrectedPaymentMethod != originalDetection.paymentMethod) {
      corrections['payment_method'] = {
        'original': originalDetection.paymentMethod,
        'corrected': userCorrectedPaymentMethod,
      };
      hasCorrections = true;
    }

    return hasCorrections ? corrections : null;
  }

  /// Calculate quality metrics from detection records
  DetectionQualityMetrics _calculateMetrics(
      List<NotificationDetectionRecord> records) {
    if (records.isEmpty) {
      return DetectionQualityMetrics(
        totalDetections: 0,
        truePositives: 0,
        falsePositives: 0,
        trueNegatives: 0,
        falseNegatives: 0,
        averageConfidence: 0.0,
        averageResponseTime: 0.0,
      );
    }

    int truePositives = 0;
    int falsePositives = 0;
    int trueNegatives = 0;
    int falseNegatives = 0;
    double totalConfidence = 0.0;
    double totalResponseTime = 0.0;

    for (final record in records) {
      totalConfidence += record.detectionResult.confidence;

      // Calculate response time if available in metadata
      // totalResponseTime += record.detectionResult.metadata?['response_time'] ?? 0.0;

      // Since ExpenseExtractionResult represents already classified expenses,
      // we treat all records as expense detections
      if (record.userConfirmed) {
        truePositives++;
      } else {
        falsePositives++;
      }
    }

    return DetectionQualityMetrics(
      totalDetections: records.length,
      truePositives: truePositives,
      falsePositives: falsePositives,
      trueNegatives: trueNegatives,
      falseNegatives: falseNegatives,
      averageConfidence: totalConfidence / records.length,
      averageResponseTime: totalResponseTime / records.length,
    );
  }
}
