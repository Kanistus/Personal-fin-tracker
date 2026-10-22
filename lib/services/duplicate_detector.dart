import 'dart:math';

import '../models/auto_transaction.dart';
import '../models/transaction.dart';

/// Result of a duplicate transaction detection check.
///
/// Contains information about whether an incoming transaction is a definite
/// duplicate or a possible duplicate requiring user review, along with IDs
/// of matching records, match score, and match reason.
class DuplicateCheckResult {
  /// True if the transaction is determined to be a definite duplicate.
  final bool isDuplicate;

  /// True if the transaction might be a duplicate and needs user review.
  final bool isPossibleDuplicate;

  /// ID of the matching [AutoTransaction], if detected.
  final int? existingAutoTransactionId;

  /// ID of the matching manual [Transaction], if detected.
  final int? existingTransactionId;

  /// Reason code for the detection outcome:
  /// - [DuplicateDetector.reasonExactUpiRef] ('exact_upi_ref')
  /// - [DuplicateDetector.reasonSameAmountMerchantTime] ('same_amount_merchant_time')
  /// - [DuplicateDetector.reasonPossibleMatch] ('possible_match')
  /// - [DuplicateDetector.reasonNoMatch] ('no_match')
  final String reason;

  /// Confidence score between 0.0 (no match) and 1.0 (exact match).
  final double matchScore;

  /// Creates a new [DuplicateCheckResult].
  const DuplicateCheckResult({
    required this.isDuplicate,
    required this.isPossibleDuplicate,
    this.existingAutoTransactionId,
    this.existingTransactionId,
    required this.reason,
    required this.matchScore,
  });

  /// Factory constructor representing no duplicate found.
  factory DuplicateCheckResult.noMatch() => const DuplicateCheckResult(
        isDuplicate: false,
        isPossibleDuplicate: false,
        existingAutoTransactionId: null,
        existingTransactionId: null,
        reason: DuplicateDetector.reasonNoMatch,
        matchScore: 0.0,
      );

  /// True if either a definite duplicate or a possible duplicate was found.
  bool get hasMatch => isDuplicate || isPossibleDuplicate;

  /// True if the result is a possible duplicate that requires manual user review.
  bool get needsReview => isPossibleDuplicate && !isDuplicate;

  /// Returns a copy of this result with the specified fields replaced.
  DuplicateCheckResult copyWith({
    bool? isDuplicate,
    bool? isPossibleDuplicate,
    int? existingAutoTransactionId,
    int? existingTransactionId,
    String? reason,
    double? matchScore,
  }) {
    return DuplicateCheckResult(
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isPossibleDuplicate: isPossibleDuplicate ?? this.isPossibleDuplicate,
      existingAutoTransactionId:
          existingAutoTransactionId ?? this.existingAutoTransactionId,
      existingTransactionId:
          existingTransactionId ?? this.existingTransactionId,
      reason: reason ?? this.reason,
      matchScore: matchScore ?? this.matchScore,
    );
  }

  /// Converts this result to a Map.
  Map<String, dynamic> toMap() {
    return {
      'isDuplicate': isDuplicate,
      'isPossibleDuplicate': isPossibleDuplicate,
      'existingAutoTransactionId': existingAutoTransactionId,
      'existingTransactionId': existingTransactionId,
      'reason': reason,
      'matchScore': matchScore,
    };
  }

  /// Creates a [DuplicateCheckResult] from a Map.
  factory DuplicateCheckResult.fromMap(Map<String, dynamic> map) {
    return DuplicateCheckResult(
      isDuplicate: map['isDuplicate'] as bool? ?? false,
      isPossibleDuplicate: map['isPossibleDuplicate'] as bool? ?? false,
      existingAutoTransactionId: map['existingAutoTransactionId'] as int?,
      existingTransactionId: map['existingTransactionId'] as int?,
      reason: map['reason'] as String? ?? DuplicateDetector.reasonNoMatch,
      matchScore: (map['matchScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'DuplicateCheckResult('
        'isDuplicate: $isDuplicate, '
        'isPossibleDuplicate: $isPossibleDuplicate, '
        'existingAutoTransactionId: $existingAutoTransactionId, '
        'existingTransactionId: $existingTransactionId, '
        'reason: $reason, '
        'matchScore: $matchScore)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateCheckResult &&
          runtimeType == other.runtimeType &&
          isDuplicate == other.isDuplicate &&
          isPossibleDuplicate == other.isPossibleDuplicate &&
          existingAutoTransactionId == other.existingAutoTransactionId &&
          existingTransactionId == other.existingTransactionId &&
          reason == other.reason &&
          (matchScore - other.matchScore).abs() < 0.0001;

  @override
  int get hashCode => Object.hash(
        isDuplicate,
        isPossibleDuplicate,
        existingAutoTransactionId,
        existingTransactionId,
        reason,
        matchScore,
      );
}

/// Pure Dart service that detects duplicate transactions to prevent
/// the same payment from being recorded twice.
///
/// Handles scenarios including:
/// - Same payment triggering notifications from multiple apps (e.g. SMS + UPI app)
/// - Re-posted Android notifications
/// - Bank statement imports containing transactions already captured via notifications
/// - Service restarts reprocessing recent notifications
class DuplicateDetector {
  DuplicateDetector._();

  // Reason constants
  static const String reasonExactUpiRef = 'exact_upi_ref';
  static const String reasonSameAmountMerchantTime =
      'same_amount_merchant_time';
  static const String reasonPossibleMatch = 'possible_match';
  static const String reasonNoMatch = 'no_match';

  static final Random _random = Random();

  /// Check if a new auto-transaction is a duplicate of any existing ones.
  ///
  /// Evaluates all candidates in [existing] against [newTxn] using the
  /// priority-ordered duplicate detection rules and returns the best match.
  static DuplicateCheckResult checkAgainstAutoTransactions(
    AutoTransaction newTxn,
    List<AutoTransaction> existing,
  ) {
    if (existing.isEmpty) {
      return DuplicateCheckResult.noMatch();
    }

    DuplicateCheckResult? bestResult;
    Duration? bestTimeDiff;

    for (final candidate in existing) {
      // Skip comparing an existing record to itself
      if (newTxn.id != null &&
          candidate.id != null &&
          newTxn.id == candidate.id) {
        continue;
      }
      if (identical(newTxn, candidate)) {
        continue;
      }

      final result = _evaluateAutoCandidate(newTxn, candidate);
      if (!result.hasMatch) {
        continue;
      }

      // Early exit if definite UPI match (score 1.0)
      if (result.matchScore >= 1.0) {
        return result;
      }

      final timeDiff = (newTxn.date.difference(candidate.date)).abs();
      if (bestResult == null ||
          result.matchScore > bestResult.matchScore ||
          (result.matchScore == bestResult.matchScore &&
              bestTimeDiff != null &&
              timeDiff < bestTimeDiff)) {
        bestResult = result;
        bestTimeDiff = timeDiff;
      }
    }

    return bestResult ?? DuplicateCheckResult.noMatch();
  }

  /// Check if a new auto-transaction is a duplicate of any manually-entered transactions.
  ///
  /// Evaluates all candidates in [existing] against [newTxn] and returns the best match.
  static DuplicateCheckResult checkAgainstTransactions(
    AutoTransaction newTxn,
    List<Transaction> existing,
  ) {
    if (existing.isEmpty) {
      return DuplicateCheckResult.noMatch();
    }

    DuplicateCheckResult? bestResult;
    Duration? bestTimeDiff;

    for (final candidate in existing) {
      final result = _evaluateManualCandidate(newTxn, candidate);
      if (!result.hasMatch) {
        continue;
      }

      // Early exit if definite match
      if (result.matchScore >= 1.0) {
        return result;
      }

      final timeDiff = (newTxn.date.difference(candidate.date)).abs();
      if (bestResult == null ||
          result.matchScore > bestResult.matchScore ||
          (result.matchScore == bestResult.matchScore &&
              bestTimeDiff != null &&
              timeDiff < bestTimeDiff)) {
        bestResult = result;
        bestTimeDiff = timeDiff;
      }
    }

    return bestResult ?? DuplicateCheckResult.noMatch();
  }

  /// Combined check against both auto and manual transactions.
  ///
  /// Evaluates [newTxn] against both [autoTransactions] and [manualTransactions],
  /// prioritizing the higher-confidence match and linking matching IDs from both
  /// if applicable.
  static DuplicateCheckResult checkAll({
    required AutoTransaction newTxn,
    required List<AutoTransaction> autoTransactions,
    required List<Transaction> manualTransactions,
  }) {
    final autoResult = checkAgainstAutoTransactions(newTxn, autoTransactions);
    final manualResult = checkAgainstTransactions(newTxn, manualTransactions);

    // If neither matched
    if (!autoResult.hasMatch && !manualResult.hasMatch) {
      return DuplicateCheckResult.noMatch();
    }

    // If only one matched
    if (autoResult.hasMatch && !manualResult.hasMatch) {
      return autoResult;
    }
    if (!autoResult.hasMatch && manualResult.hasMatch) {
      return manualResult;
    }

    // Both matched: pick the one with higher confidence/score
    if (autoResult.matchScore >= manualResult.matchScore) {
      return DuplicateCheckResult(
        isDuplicate: autoResult.isDuplicate,
        isPossibleDuplicate: autoResult.isPossibleDuplicate,
        existingAutoTransactionId: autoResult.existingAutoTransactionId,
        existingTransactionId: manualResult.existingTransactionId,
        reason: autoResult.reason,
        matchScore: autoResult.matchScore,
      );
    } else {
      return DuplicateCheckResult(
        isDuplicate: manualResult.isDuplicate,
        isPossibleDuplicate: manualResult.isPossibleDuplicate,
        existingAutoTransactionId: autoResult.existingAutoTransactionId,
        existingTransactionId: manualResult.existingTransactionId,
        reason: manualResult.reason,
        matchScore: manualResult.matchScore,
      );
    }
  }

  /// Generate a duplicate group ID for linking related records.
  ///
  /// Format: `dup_<microseconds>_<6-digit-random>`
  static String generateDuplicateGroupId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1000000).toString().padLeft(6, '0');
    return 'dup_${timestamp}_$randomPart';
  }

  /// Public merchant similarity calculation using normalized Levenshtein distance.
  ///
  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  static double merchantSimilarity(String a, String b) =>
      _merchantSimilarity(a, b);

  /// Public merchant normalization helper.
  static String normalizeMerchant(String name) => _normalizeMerchant(name);

  // ---------------------------------------------------------------------------
  // Evaluation Rules
  // ---------------------------------------------------------------------------

  /// Evaluates an [AutoTransaction] candidate against [newTxn].
  static DuplicateCheckResult _evaluateAutoCandidate(
    AutoTransaction newTxn,
    AutoTransaction candidate,
  ) {
    // Rule 1: UPI Reference Match (Definite duplicate)
    // If both transactions have a non-empty upiRef and they match -> isDuplicate=true, matchScore=1.0
    final newUpi = newTxn.upiRef?.trim();
    final candidateUpi = candidate.upiRef?.trim();
    if (newUpi != null &&
        newUpi.isNotEmpty &&
        candidateUpi != null &&
        candidateUpi.isNotEmpty &&
        newUpi.toLowerCase() == candidateUpi.toLowerCase()) {
      return DuplicateCheckResult(
        isDuplicate: true,
        isPossibleDuplicate: false,
        existingAutoTransactionId: candidate.id,
        reason: reasonExactUpiRef,
        matchScore: 1.0,
      );
    }

    final isSameAmount = _isSameAmount(newTxn.amount, candidate.amount);
    final timeDiff = (newTxn.date.difference(candidate.date)).abs();

    // Rule 2: Exact Match (Very likely duplicate)
    // Same amount AND same merchant (normalized) AND timestamps within 2 minutes
    // isDuplicate=true, matchScore=0.95
    final normNew = _normalizeMerchant(newTxn.merchant);
    final normCandidate = _normalizeMerchant(candidate.merchant);
    final isSameMerchant = normNew.isNotEmpty && normNew == normCandidate;

    if (isSameAmount &&
        isSameMerchant &&
        timeDiff <= const Duration(minutes: 2)) {
      return DuplicateCheckResult(
        isDuplicate: true,
        isPossibleDuplicate: false,
        existingAutoTransactionId: candidate.id,
        reason: reasonSameAmountMerchantTime,
        matchScore: 0.95,
      );
    }

    // Rule 3: Near Match (Possible duplicate)
    // Same amount AND similar merchant (fuzzy match, >70% similarity) AND timestamps within 5 minutes
    // isPossibleDuplicate=true, matchScore=0.7-0.9
    if (isSameAmount && timeDiff <= const Duration(minutes: 5)) {
      final similarity =
          _merchantSimilarity(newTxn.merchant, candidate.merchant);
      if (similarity > 0.70) {
        // Linearly map similarity from (0.7, 1.0] to [0.7, 0.9]
        final rawScore = 0.7 + ((similarity - 0.7) / 0.3) * 0.2;
        final matchScore =
            double.parse(rawScore.clamp(0.7, 0.9).toStringAsFixed(2));
        return DuplicateCheckResult(
          isDuplicate: false,
          isPossibleDuplicate: true,
          existingAutoTransactionId: candidate.id,
          reason: reasonPossibleMatch,
          matchScore: matchScore,
        );
      }
    }

    // Rule 4: Amount + Time Match (Suspicious, flag for review)
    // Same amount AND timestamps within 1 minute AND same source app
    // isPossibleDuplicate=true, matchScore=0.5
    final sameSourceApp = newTxn.sourceApp.trim().isNotEmpty &&
        candidate.sourceApp.trim().isNotEmpty &&
        newTxn.sourceApp.trim().toLowerCase() ==
            candidate.sourceApp.trim().toLowerCase();

    if (isSameAmount &&
        sameSourceApp &&
        timeDiff <= const Duration(minutes: 1)) {
      return DuplicateCheckResult(
        isDuplicate: false,
        isPossibleDuplicate: true,
        existingAutoTransactionId: candidate.id,
        reason: reasonPossibleMatch,
        matchScore: 0.5,
      );
    }

    // Rule 5: No Match
    return DuplicateCheckResult.noMatch();
  }

  /// Evaluates a manual [Transaction] candidate against [newTxn].
  static DuplicateCheckResult _evaluateManualCandidate(
    AutoTransaction newTxn,
    Transaction candidate,
  ) {
    // Check if newTxn is already explicitly linked to this manual transaction
    if (newTxn.linkedTransactionId != null &&
        candidate.id != null &&
        newTxn.linkedTransactionId == candidate.id) {
      return DuplicateCheckResult(
        isDuplicate: true,
        isPossibleDuplicate: false,
        existingTransactionId: candidate.id,
        reason: reasonSameAmountMerchantTime,
        matchScore: 1.0,
      );
    }

    // Rule 1: UPI Reference Match
    // If newTxn has a valid UPI ref and candidate title matches or contains it
    final newUpi = newTxn.upiRef?.trim();
    if (newUpi != null && newUpi.isNotEmpty && newUpi.length >= 6) {
      final candidateTitle = candidate.title.trim().toLowerCase();
      if (candidateTitle.contains(newUpi.toLowerCase())) {
        return DuplicateCheckResult(
          isDuplicate: true,
          isPossibleDuplicate: false,
          existingTransactionId: candidate.id,
          reason: reasonExactUpiRef,
          matchScore: 1.0,
        );
      }
    }

    final isSameAmount = _isSameAmount(newTxn.amount, candidate.amount);
    final timeDiff = (newTxn.date.difference(candidate.date)).abs();

    // Rule 2: Exact Match
    // Same amount AND same merchant/title (normalized) AND timestamps within 2 minutes
    final normNew = _normalizeMerchant(newTxn.merchant);
    final normCandidate = _normalizeMerchant(candidate.title);
    final isSameMerchant = normNew.isNotEmpty && normNew == normCandidate;

    if (isSameAmount &&
        isSameMerchant &&
        timeDiff <= const Duration(minutes: 2)) {
      return DuplicateCheckResult(
        isDuplicate: true,
        isPossibleDuplicate: false,
        existingTransactionId: candidate.id,
        reason: reasonSameAmountMerchantTime,
        matchScore: 0.95,
      );
    }

    // Rule 3: Near Match
    // Same amount AND similar merchant/title (fuzzy match, >70% similarity) AND timestamps within 5 minutes
    if (isSameAmount && timeDiff <= const Duration(minutes: 5)) {
      final similarity = _merchantSimilarity(newTxn.merchant, candidate.title);
      if (similarity > 0.70) {
        final rawScore = 0.7 + ((similarity - 0.7) / 0.3) * 0.2;
        final matchScore =
            double.parse(rawScore.clamp(0.7, 0.9).toStringAsFixed(2));
        return DuplicateCheckResult(
          isDuplicate: false,
          isPossibleDuplicate: true,
          existingTransactionId: candidate.id,
          reason: reasonPossibleMatch,
          matchScore: matchScore,
        );
      }
    }

    // Rule 4 does not apply to manual transactions because they lack sourceApp metadata.

    // Rule 5: No Match
    return DuplicateCheckResult.noMatch();
  }

  // ---------------------------------------------------------------------------
  // Normalization and Similarity Helpers
  // ---------------------------------------------------------------------------

  /// Normalizes merchant names by lowercasing, stripping punctuation,
  /// removing extra whitespace, and filtering standard corporate suffixes.
  static String _normalizeMerchant(String name) {
    if (name.isEmpty) return '';

    String s = name.toLowerCase().trim();

    // Remove quotes, apostrophes, and periods (e.g. McDonald's -> mcdonalds, Inc. -> inc)
    s = s.replaceAll(RegExp(r"['`\.]"), '');

    // Replace non-alphanumeric characters with space
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // Normalize multiple spaces into a single space
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Filter out common corporate noise suffixes if present as separate words
    const noiseWords = {
      'pvt',
      'private',
      'ltd',
      'limited',
      'inc',
      'corp',
      'corporation',
      'llc',
      'llp',
      'co',
    };

    final words = s.split(' ');
    final filtered =
        words.where((w) => w.isNotEmpty && !noiseWords.contains(w)).toList();

    if (filtered.isEmpty) {
      return s;
    }

    return filtered.join(' ');
  }

  /// Calculates merchant similarity using normalized Levenshtein distance.
  ///
  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  static double _merchantSimilarity(String a, String b) {
    if (a.trim() == b.trim()) {
      return 1.0;
    }

    final normA = _normalizeMerchant(a);
    final normB = _normalizeMerchant(b);

    if (normA == normB) {
      return 1.0;
    }

    if (normA.isEmpty || normB.isEmpty) {
      return 0.0;
    }

    final distance = _levenshteinDistance(normA, normB);
    final maxLength = max(normA.length, normB.length);

    if (maxLength == 0) return 1.0;

    final similarity = (maxLength - distance) / maxLength;
    return similarity.clamp(0.0, 1.0);
  }

  /// Computes the Levenshtein distance between two strings using O(min(m, n)) space.
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final m = s1.length;
    final n = s2.length;

    List<int> previousRow = List<int>.generate(n + 1, (i) => i);
    List<int> currentRow = List<int>.filled(n + 1, 0);

    for (int i = 0; i < m; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < n; j++) {
        final cost = s1.codeUnitAt(i) == s2.codeUnitAt(j) ? 0 : 1;
        currentRow[j + 1] = min(
          currentRow[j] + 1, // insertion
          min(
            previousRow[j + 1] + 1, // deletion
            previousRow[j] + cost, // substitution
          ),
        );
      }

      for (int j = 0; j <= n; j++) {
        previousRow[j] = currentRow[j];
      }
    }

    return currentRow[n];
  }

  /// Helper to compare amounts allowing for floating-point imprecision.
  static bool _isSameAmount(double a, double b) => (a - b).abs() < 0.01;
}
