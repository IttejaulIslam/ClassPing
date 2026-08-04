import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../routine/domain/class_entry.dart';
import '../../../routine/presentation/providers/routine_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render periodically so "in Xh Ym" stays accurate without a full
    // countdown-per-second timer.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final todays = ref.watch(todaysClassesProvider);
    final pendingTasks = ref.watch(pendingTasksProvider);
    final now = DateTime.now();

    ClassEntry? next;
    for (final entry in todays) {
      final start = DateTime(now.year, now.month, now.day, entry.startHour, entry.startMinute);
      if (start.isAfter(now)) {
        next = entry;
        break;
      }
    }

    // Keep the (optional) Android home-screen widget in sync. Safe no-op if
    // the native widget isn't installed \u2014 see HomeWidgetService for the
    // native setup this still needs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeWidgetService.instance.update(nextClass: next, pendingTasks: pendingTasks);
    });

    return AppBackground(
      bottomSafe: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(now),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fullDate(now),
              style: TextStyle(fontSize: 15, color: dark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 20),
            if (next != null) _NextClassCard(entry: next),
            const SizedBox(height: 24),
            Text(
              "Today's Classes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (todays.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No classes today \u2014 enjoy the break!',
                    style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                  ),
                ),
              )
            else
              ...todays.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ClassRow(entry: entry, isNext: identical(entry, next)),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pending Tasks (${pendingTasks.length})",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/tasks'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pendingTasks.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No pending tasks! All caught up. 🎉',
                    style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                  ),
                ),
              )
            else
              ...pendingTasks.take(3).map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => ref.read(tasksProvider.notifier).toggleTask(task),
                              icon: Icon(
                                Icons.radio_button_unchecked_rounded,
                                color: dark ? Colors.white54 : Colors.black45,
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${task.subject.isNotEmpty ? "${task.subject} \u2022 " : ""}'
                                    'Due ${DateFormat("MMM d, h:mm a").format(task.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _fullDate(DateTime now) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _NextClassCard extends StatelessWidget {
  final ClassEntry entry;
  const _NextClassCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, entry.startHour, entry.startMinute);
    final remaining = start.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderColor: secondaryColor.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UP NEXT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.subject,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.startTimeLabel} \u2013 ${entry.endTimeLabel}'
            '${entry.room.isNotEmpty ? ' \u2022 Room ${entry.room}' : ''}',
            style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 14),
          Text(
            hours > 0 ? 'in ${hours}h ${minutes}m' : 'in ${minutes}m',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final ClassEntry entry;
  final bool isNext;
  const _ClassRow({required this.entry, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return GlassContainer(
      alpha: isNext ? 0.65 : 0.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isNext ? secondaryColor : primaryColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.startTimeLabel} \u2013 ${entry.endTimeLabel}'
                  '${entry.room.isNotEmpty ? ' \u2022 Room ${entry.room}' : ''}',
                  style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
