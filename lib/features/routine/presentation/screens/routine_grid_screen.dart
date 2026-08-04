import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../domain/class_entry.dart';
import '../providers/routine_providers.dart';

/// A visual day x time grid of the whole week's routine, instead of the
/// plain scrolling list in RoutineScreen. Built directly from the same
/// ClassEntry data (dayOfWeek/startHour/endHour) — no new fields needed.
class RoutineGridScreen extends ConsumerWidget {
  const RoutineGridScreen({super.key});

  static const _dayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _gridStartHour = 8; // 8 AM
  static const _gridEndHour = 20; // 8 PM
  static const _hourHeight = 56.0;
  static const _dayColWidth = 96.0;
  static const _timeColWidth = 44.0;

  // A small fixed palette so each subject gets a consistent, distinguishable
  // color across the grid without needing a new "color" field on ClassEntry.
  static const _palette = [
    Color(0xFF6B0032),
    Color(0xFFD13D59),
    Color(0xFF3B1F8F),
    Color(0xFF1F6F8F),
    Color(0xFF2E8F5B),
    Color(0xFFB8720C),
  ];

  Color _colorFor(String subject) {
    final hash = subject.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final routineAsync = ref.watch(routineProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Weekly Grid'),
        body: routineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load routine.\n$e')),
          data: (entries) {
            final totalHours = _gridEndHour - _gridStartHour;
            final gridHeight = totalHours * _hourHeight;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: _timeColWidth + _dayColWidth * 7,
                  child: Column(
                    children: [
                      // Day header row
                      Row(
                        children: [
                          SizedBox(width: _timeColWidth),
                          for (final d in _dayShort)
                            SizedBox(
                              width: _dayColWidth,
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: dark ? Colors.white : primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Grid body: time labels + 7 day columns with positioned class blocks
                      SizedBox(
                        height: gridHeight,
                        child: Stack(
                          children: [
                            // Hour gridlines + labels
                            Column(
                              children: [
                                for (var h = _gridStartHour; h < _gridEndHour; h++)
                                  SizedBox(
                                    height: _hourHeight,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: _timeColWidth,
                                          child: Text(
                                            format12Hour('${h.toString().padLeft(2, '0')}:00'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: dark ? Colors.white38 : Colors.black38,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: dark
                                                      ? Colors.white.withValues(alpha: 0.06)
                                                      : Colors.black.withValues(alpha: 0.06),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            // Class blocks, one Positioned per entry
                            for (final entry in entries)
                              if (entry.startHour >= _gridStartHour && entry.startHour < _gridEndHour)
                                Positioned(
                                  left: _timeColWidth + entry.dayOfWeek * _dayColWidth + 2,
                                  top: (entry.startHour - _gridStartHour) * _hourHeight +
                                      (entry.startMinute / 60.0) * _hourHeight,
                                  width: _dayColWidth - 4,
                                  height: _blockHeight(entry),
                                  child: _ClassBlock(entry: entry, color: _colorFor(entry.subject)),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _blockHeight(ClassEntry e) {
    final startMinutes = e.startHour * 60 + e.startMinute;
    final endMinutes = e.endHour * 60 + e.endMinute;
    final durationMinutes = (endMinutes - startMinutes).clamp(30, 24 * 60);
    return (durationMinutes / 60.0) * _hourHeight - 2;
  }
}

class _ClassBlock extends StatelessWidget {
  final ClassEntry entry;
  final Color color;
  const _ClassBlock({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/routine/edit', extra: entry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10.5),
            ),
            if (entry.room.isNotEmpty)
              Text(
                entry.room,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}
