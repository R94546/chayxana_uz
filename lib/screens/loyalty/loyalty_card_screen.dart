import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../models/loyalty_model.dart';
import '../../services/loyalty_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 🏆 Экран карты лояльности
class LoyaltyCardScreen extends StatelessWidget {
  final String userId;
  final String choyxonaId;
  final String choyxonaName;
  
  const LoyaltyCardScreen({
    super.key,
    required this.userId,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loyaltyService = LoyaltyService();

    return Scaffold(
      appBar: AppBar(
        title: Text('loyalty_card'.tr()),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: FutureBuilder<LoyaltyCard>(
          future: loyaltyService.getOrCreateCard(userId, choyxonaId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('error_loading'.tr()));
            }

            final card = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Карта лояльности
                  _LoyaltyCardWidget(card: card, choyxonaName: choyxonaName),
                  
                  const SizedBox(height: 24),
                  
                  // Награды
                  _RewardsSection(
                    choyxonaId: choyxonaId,
                    userPoints: card.points,
                    userId: userId,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // История транзакций
                  _TransactionsSection(cardId: card.id),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Виджет карты лояльности
class _LoyaltyCardWidget extends StatelessWidget {
  final LoyaltyCard card;
  final String choyxonaName;
  
  const _LoyaltyCardWidget({required this.card, required this.choyxonaName});

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(LoyaltyCard.getTierColor(card.tier));
    final tierName = LoyaltyCard.getTierName(card.tier);
    final formatter = NumberFormat('#,###');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withOpacity(0.9),
            tierColor.withOpacity(0.7),
            Colors.black.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название и уровень
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choyxonaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'loyalty_program'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      tierName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Баллы
          Center(
            child: Column(
              children: [
                Text(
                  formatter.format(card.points),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'points'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Прогресс до следующего уровня
          if (card.tier != 'platinum') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'to_next_level'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${formatter.format(card.pointsToNextTier)} ${'points'.tr()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: card.progressToNextTier.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Статистика
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.restaurant,
                value: card.totalVisits.toString(),
                label: 'visits'.tr(),
              ),
              _StatItem(
                icon: Icons.payments,
                value: formatter.format(card.totalSpent.toInt()),
                label: 'spent'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}

/// Секция наград
class _RewardsSection extends StatelessWidget {
  final String choyxonaId;
  final int userPoints;
  final String userId;
  
  const _RewardsSection({
    required this.choyxonaId,
    required this.userPoints,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loyaltyService = LoyaltyService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'available_rewards'.tr(),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        
        StreamBuilder<List<LoyaltyReward>>(
          stream: loyaltyService.getChoyxonaRewards(choyxonaId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'no_rewards'.tr(),
                    style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                  ),
                ),
              );
            }
            
            return Column(
              children: snapshot.data!.map((reward) => _RewardCard(
                reward: reward,
                canAfford: userPoints >= reward.pointsCost,
                onClaim: () => _claimReward(context, reward),
                isDark: isDark,
              )).toList(),
            );
          },
        ),
      ],
    );
  }
  
  Future<void> _claimReward(BuildContext context, LoyaltyReward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('claim_reward'.tr()),
        content: Text('claim_reward_confirm'.tr().replaceAll('{points}', reward.pointsCost.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr())),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final success = await LoyaltyService().claimReward(
      userId: userId,
      choyxonaId: choyxonaId,
      reward: reward,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'reward_claimed'.tr() : 'not_enough_points'.tr())),
      );
    }
  }
}

class _RewardCard extends StatelessWidget {
  final LoyaltyReward reward;
  final bool canAfford;
  final VoidCallback onClaim;
  final bool isDark;
  
  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.onClaim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.getCardBg(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: canAfford 
                ? AppColors.getPrimary(isDark).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: canAfford ? AppColors.getPrimary(isDark) : Colors.grey,
          ),
        ),
        title: Text(
          reward.name,
          style: TextStyle(
            color: AppColors.getTextPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${reward.pointsCost} ${'points'.tr()}',
          style: TextStyle(
            color: canAfford ? AppColors.getPrimary(isDark) : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: canAfford ? onClaim : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? AppColors.getPrimary(isDark) : Colors.grey,
          ),
          child: Text('claim'.tr()),
        ),
      ),
    );
  }
}

/// Секция транзакций
class _TransactionsSection extends StatelessWidget {
  final String cardId;
  
  const _TransactionsSection({required this.cardId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loyaltyService = LoyaltyService();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'points_history'.tr(),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        
        StreamBuilder<List<LoyaltyTransaction>>(
          stream: loyaltyService.getTransactions(cardId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'no_transactions'.tr(),
                    style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                  ),
                ),
              );
            }
            
            return Column(
              children: snapshot.data!.map((tx) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tx.type == 'earn' 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  child: Icon(
                    tx.type == 'earn' ? Icons.add : Icons.remove,
                    color: tx.type == 'earn' ? AppColors.success : AppColors.error,
                  ),
                ),
                title: Text(
                  tx.description,
                  style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                ),
                subtitle: Text(
                  dateFormat.format(tx.createdAt),
                  style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                ),
                trailing: Text(
                  '${tx.type == 'earn' ? '+' : ''}${tx.points}',
                  style: TextStyle(
                    color: tx.type == 'earn' ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
