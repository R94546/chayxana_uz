import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';

/// ⭐ Admin — choyxona sharhlari (redizayn + lokalizatsiya, Faza 4/5).
class ChoyxonaReviewsScreen extends StatelessWidget {
  final String choyxonaId;

  const ChoyxonaReviewsScreen({super.key, required this.choyxonaId});

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text('reviews'.tr())),
      body: StreamBuilder<QuerySnapshot>(
        // orderBy убран (составной индекс) — сортируем на клиенте
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('choyxonaId', isEqualTo: choyxonaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ChoyEmptyState(
              icon: Icons.star_border_rounded,
              title: 'no_reviews'.tr(),
              message: 'reviews_after_visits'.tr(),
            );
          }

          final reviews = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'] as Timestamp?;
              final bt = (b.data() as Map)['createdAt'] as Timestamp?;
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });

          double avgRating = 0;
          for (final doc in reviews) {
            avgRating += ((doc.data() as Map)['rating'] ?? 0).toDouble();
          }
          avgRating = avgRating / reviews.length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(ChoySpace.lg),
                padding: const EdgeInsets.all(ChoySpace.xl),
                decoration: BoxDecoration(
                  gradient: ChoyPalette.teaGradient,
                  borderRadius: ChoyRadius.all(ChoyRadius.xl),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${avgRating.toStringAsFixed(1)} ★',
                        'avg_rating'.tr()),
                    Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withValues(alpha: 0.25)),
                    _stat('${reviews.length}', 'total_reviews'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: ChoySpace.lg),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) => _ReviewCard(
                    reviewId: reviews[index].id,
                    data: reviews[index].data() as Map<String, dynamic>,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.reviewId, required this.data});
  final String reviewId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final comment = (data['comment'] ?? '').toString();
    final userId = (data['userId'] ?? '').toString();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final reply = data['reply'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: ChoySpace.md),
      child: ChoyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: userId.isEmpty
                  ? null
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
              builder: (context, snapshot) {
                String name = 'guest'.tr();
                if (snapshot.hasData && snapshot.data!.exists) {
                  final d = snapshot.data!.data() as Map<String, dynamic>?;
                  final full =
                      '${d?['firstName'] ?? ''} ${d?['lastName'] ?? ''}'.trim();
                  if (full.isNotEmpty) name = full;
                }
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: c.primaryContainer,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: c.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: ChoySpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          if (createdAt != null)
                            Text(
                              DateFormat('dd.MM.yyyy').format(createdAt),
                              style: TextStyle(
                                  fontSize: 12, color: c.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: ChoyPalette.star,
                                size: 18,
                              )),
                    ),
                  ],
                );
              },
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: ChoySpace.md),
              Text(comment, style: TextStyle(color: c.textPrimary)),
            ],
            if (reply != null && reply.isNotEmpty) ...[
              const SizedBox(height: ChoySpace.md),
              Container(
                padding: const EdgeInsets.all(ChoySpace.md),
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: ChoyRadius.all(ChoyRadius.md),
                  border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply_rounded, size: 16, color: c.primary),
                        const SizedBox(width: 6),
                        Text('choyxona_reply'.tr(),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: c.primary,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(reply, style: TextStyle(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
            if (reply == null || reply.isEmpty) ...[
              const SizedBox(height: ChoySpace.sm),
              TextButton.icon(
                onPressed: () => _showReplyDialog(context),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: Text('reply'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('reply_to_review'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'write_reply'.tr()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(reviewId)
                  .update({'reply': controller.text.trim()});
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('reply_added'.tr()),
                  backgroundColor: ChoyPalette.success,
                ),
              );
            },
            child: Text('send'.tr()),
          ),
        ],
      ),
    );
  }
}
