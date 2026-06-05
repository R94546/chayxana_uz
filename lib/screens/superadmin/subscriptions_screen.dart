import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/subscription_model.dart';

/// Экран управления подписками (Super Admin)
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Подписки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Пробные'),
            Tab(text: 'Истёкшие'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionsList('active', isDark),
          _buildSubscriptionsList('trial', isDark),
          _buildSubscriptionsList('expired', isDark),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList(String filter, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubscriptionsStream(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(filter, isDark);
        }

        final subscriptions = snapshot.data!.docs
            .map((doc) => Subscription.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) => _buildSubscriptionCard(subscriptions[index], isDark),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getSubscriptionsStream(String filter) {
    var query = FirebaseFirestore.instance.collection('subscriptions');

    switch (filter) {
      case 'active':
        return query
            .where('isActive', isEqualTo: true)
            .where('isTrial', isEqualTo: false)
            .snapshots();
      case 'trial':
        return query
            .where('isActive', isEqualTo: true)
            .where('isTrial', isEqualTo: true)
            .snapshots();
      case 'expired':
        return query.where('isActive', isEqualTo: false).snapshots();
      default:
        return query.snapshots();
    }
  }

  Widget _buildSubscriptionCard(Subscription sub, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(sub.choyxonaId)
          .get(),
      builder: (context, choyxonaSnapshot) {
        final choyxonaName = choyxonaSnapshot.data?.get('name') ?? 'Чайхана';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sub.isTrial
                            ? AppColors.info.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        sub.isTrial ? Icons.hourglass_empty : Icons.diamond,
                        color: sub.isTrial ? AppColors.info : Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choyxonaName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            sub.isTrial ? 'Пробный период' : 'Премиум',
                            style: TextStyle(
                              fontSize: 12,
                              color: sub.isTrial ? AppColors.info : Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(sub),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Информация
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'Начало',
                      DateFormat('dd.MM.yyyy').format(sub.startDate),
                      isDark,
                    ),
                    _buildInfoColumn(
                      'Окончание',
                      DateFormat('dd.MM.yyyy').format(sub.endDate),
                      isDark,
                    ),
                    _buildInfoColumn(
                      'Осталось',
                      '${sub.daysLeft} дней',
                      isDark,
                      highlight: sub.isExpiringSoon,
                    ),
                  ],
                ),

                if (!sub.isTrial) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Стоимость: ${sub.price.toStringAsFixed(0)} сум',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sub.paymentStatus == 'paid'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub.paymentStatus == 'paid' ? 'Оплачено' : 'Ожидает оплаты',
                          style: TextStyle(
                            fontSize: 12,
                            color: sub.paymentStatus == 'paid'
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Действия
                Row(
                  children: [
                    if (sub.isTrial)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _convertToPayment(sub),
                          child: const Text('Перевести на платный'),
                        ),
                      ),
                    if (!sub.isActiveNow && !sub.isTrial) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _renewSubscription(sub),
                          child: const Text('Продлить'),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showActions(sub),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Subscription sub) {
    Color color;
    String text;

    if (!sub.isActiveNow) {
      color = AppColors.error;
      text = 'Истёкла';
    } else if (sub.isExpiringSoon) {
      color = AppColors.warning;
      text = 'Скоро истечёт';
    } else {
      color = AppColors.success;
      text = 'Активна';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlight
                ? AppColors.warning
                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String filter, bool isDark) {
    String message;
    switch (filter) {
      case 'active':
        message = 'Нет активных подписок';
        break;
      case 'trial':
        message = 'Нет пробных подписок';
        break;
      case 'expired':
        message = 'Нет истёкших подписок';
        break;
      default:
        message = 'Нет подписок';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.diamond_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  Future<void> _convertToPayment(Subscription sub) async {
    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(sub.id)
        .update({
      'isTrial': false,
      'price': 300000,
      'paymentStatus': 'pending',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Переведено на платный тариф'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _renewSubscription(Subscription sub) async {
    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(sub.id)
        .update({
      'isActive': true,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
      'paymentStatus': 'pending',
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подписка продлена'), backgroundColor: AppColors.success),
      );
    }
  }

  void _showActions(Subscription sub) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Отменить подписку'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .doc(sub.id)
                    .update({'isActive': false});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Удалить', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .doc(sub.id)
                    .delete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
