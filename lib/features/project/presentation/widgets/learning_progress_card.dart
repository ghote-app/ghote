import 'package:flutter/material.dart';

import '../../../../models/learning_progress.dart';
import '../../../../services/learning_progress_service.dart';
import '../../../../utils/app_locale.dart';

/// Widget for displaying learning progress statistics
/// Extracted from project_details_screen.dart for Clean Architecture
class LearningProgressCard extends StatelessWidget {
  final String projectId;

  const LearningProgressCard({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final progressService = LearningProgressService();
    
    return StreamBuilder<LearningProgress?>(
      stream: progressService.watchProgress(projectId),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        
        // If no learning progress, show guide message
        if (progress == null || 
            (progress.totalFlashcards == 0 && progress.totalQuizAttempts == 0)) {
          return _buildEmptyState();
        }
        
        return _buildProgressCard(progress);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            color: Colors.white.withValues(alpha: 0.4),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('progress.startLearning'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(LearningProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.blue.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                tr('progress.title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Overall progress
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress.overallProgressPercent,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flashcard progress
          if (progress.totalFlashcards > 0) ...[
            _buildProgressItem(
              icon: Icons.quiz_outlined,
              label: tr('progress.flashcardsProgress'),
              value: '${progress.masteredFlashcards}/${progress.totalFlashcards} ${tr("progress.mastered")}',
              progressValue: progress.flashcardProgress,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
          ],
          // Quiz accuracy
          if (progress.totalQuizAttempts > 0)
            _buildProgressItem(
              icon: Icons.check_circle_outline,
              label: tr('progress.quizAccuracy'),
              value: '${progress.correctAnswers}/${progress.totalQuizAttempts} ${tr("progress.questions")}',
              progressValue: progress.quizAccuracy,
              color: Colors.purple,
            ),
          // Last study time
          if (progress.lastFlashcardStudyAt != null || progress.lastQuizAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${tr("progress.lastStudy")}: ${_formatLastStudyTime(progress)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required double progressValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatLastStudyTime(LearningProgress progress) {
    DateTime? lastTime;
    if (progress.lastFlashcardStudyAt != null && progress.lastQuizAt != null) {
      lastTime = progress.lastFlashcardStudyAt!.isAfter(progress.lastQuizAt!) 
          ? progress.lastFlashcardStudyAt 
          : progress.lastQuizAt;
    } else {
      lastTime = progress.lastFlashcardStudyAt ?? progress.lastQuizAt;
    }
    
    if (lastTime == null) return tr('time.noRecord');
    
    final now = DateTime.now();
    final diff = now.difference(lastTime);
    
    if (diff.inMinutes < 1) return tr('time.justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    return '${diff.inDays} days';
  }
}
