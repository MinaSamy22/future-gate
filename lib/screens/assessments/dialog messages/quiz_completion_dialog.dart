import 'package:flutter/material.dart';

class QuizCompletionDialog extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;

  const QuizCompletionDialog({
    Key? key,
    required this.correctAnswers,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percentage = (correctAnswers / totalQuestions) * 100;
    final String performance = _getPerformanceText(percentage);
    final Color performanceColor = _getPerformanceColor(percentage);
    final Color primaryColor = const Color(0xFF196AB3);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with celebration icon (now colored by performance)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(Icons.celebration, size: 60, color: performanceColor),
              ],
            ),
            const SizedBox(height: 20),

            // Performance level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: performanceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: performanceColor, width: 1.5),
              ),
              child: Text(
                performance,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Score display
            Text(
              '$correctAnswers / $totalQuestions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Percentage display
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: performanceColor,
              ),
            ),
            const SizedBox(height: 24),

            // Progress bar
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              color: performanceColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 24),

            // Feedback message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _getFeedbackMessage(percentage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action button (keeps primary color)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'RETURN TO HOME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPerformanceText(double percentage) {
    if (percentage >= 85) return 'ADVANCED';
    if (percentage >= 75) return 'INTERMEDIATE';
    if (percentage >= 50) return 'BEGINNER';
    return 'NEEDS PRACTICE';
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.blueGrey;
    return Colors.blueGrey;
  }

  String _getFeedbackMessage(double percentage) {
    if (percentage >= 85) {
      return 'Outstanding performance! You\'ve demonstrated advanced mastery of this material.';
    } else if (percentage >= 75) {
      return 'Great job! You have a strong intermediate understanding of this topic.';
    } else if (percentage >= 50) {
      return 'Good start! You\'ve reached beginner level - keep practicing to improve.';
    } else {
      return 'Keep working at it! Review the material and try again to improve your score.';
    }
  }
}