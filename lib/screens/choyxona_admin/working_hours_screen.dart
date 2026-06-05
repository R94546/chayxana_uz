import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/choyxona_model.dart';

/// Экран настройки рабочих часов чайханы
class WorkingHoursScreen extends StatefulWidget {
  final String choyxonaId;
  final Map<String, dynamic> choyxonaData;

  const WorkingHoursScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaData,
  });

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  Map<String, WorkingHours> _workingHours = {};
  bool _isLoading = false;

  final List<Map<String, String>> _days = [
    {'key': 'monday', 'label': 'day_monday'},
    {'key': 'tuesday', 'label': 'day_tuesday'},
    {'key': 'wednesday', 'label': 'day_wednesday'},
    {'key': 'thursday', 'label': 'day_thursday'},
    {'key': 'friday', 'label': 'day_friday'},
    {'key': 'saturday', 'label': 'day_saturday'},
    {'key': 'sunday', 'label': 'day_sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  void _loadWorkingHours() {
    if (widget.choyxonaData['workingHours'] != null) {
      final hoursMap = widget.choyxonaData['workingHours'] as Map<String, dynamic>;
      _workingHours = hoursMap.map((key, value) => MapEntry(key, WorkingHours.fromMap(value)));
    } else {
      // Дефолтные значения: Пн-Вс 09:00 - 23:00
      for (var day in _days) {
        _workingHours[day['key']!] = WorkingHours(open: '09:00', close: '23:00', isOpen: true);
      }
    }
    setState(() {});
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(widget.choyxonaId)
          .update({
        'workingHours': _workingHours.map((key, value) => MapEntry(key, value.toMap())),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('working_hours_saved'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime(String dayKey, bool isOpenTime) async {
    final hours = _workingHours[dayKey]!;
    final currentTimeStr = isOpenTime ? hours.open : hours.close;
    final parts = currentTimeStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? AppColors.darkCardBg : AppColors.surface,
              dialHandColor: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _workingHours[dayKey] = WorkingHours(
          open: isOpenTime ? formatted : hours.open,
          close: isOpenTime ? hours.close : formatted,
          isOpen: hours.isOpen,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('working_hours'.tr()),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveWorkingHours,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _days.length,
          itemBuilder: (context, index) {
            final day = _days[index];
            final key = day['key']!;
            final label = day['label']!.tr();
            final hours = _workingHours[key] ?? WorkingHours(open: '09:00', close: '23:00', isOpen: true);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.getCardBg(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.darkCardBorder : Colors.transparent),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // День и переключатель
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.getTextPrimary(isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: hours.isOpen,
                          onChanged: (val) {
                            setState(() {
                              _workingHours[key] = WorkingHours(
                                open: hours.open,
                                close: hours.close,
                                isOpen: val,
                              );
                            });
                          },
                          activeColor: AppColors.getPrimary(isDark),
                        ),
                      ],
                    ),

                    // Время работы (если открыто)
                    if (hours.isOpen) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeButton(
                              context,
                              icon: Icons.access_time,
                              label: 'open_time'.tr(),
                              time: hours.open,
                              onTap: () => _pickTime(key, true),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeButton(
                              context,
                              icon: Icons.access_time_filled,
                              label: 'close_time'.tr(),
                              time: hours.close,
                              onTap: () => _pickTime(key, false),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'closed'.tr(),
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgBottom : AppColors.lightBgBottom,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
