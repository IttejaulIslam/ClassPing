import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/class_entry.dart';
import '../providers/routine_providers.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final routineAsync = ref.watch(routineProvider);

    return AppBackground(
      bottomSafe: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(
          context,
          'Weekly Routine',
          actions: [
            IconButton(
              tooltip: 'Grid view',
              icon: Icon(Icons.grid_view_rounded, color: dark ? Colors.white : primaryColor),
              onPressed: () => context.push('/routine/grid'),
            ),
            IconButton(
              tooltip: 'Import from CSV',
              icon: Icon(Icons.file_upload_outlined, color: dark ? Colors.white : primaryColor),
              onPressed: () => context.push('/routine/import'),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 85),
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () => context.push('/routine/add'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        body: routineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your routine.\n$err',
                textAlign: TextAlign.center,
                style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
          data: (allEntries) {
            if (allEntries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your routine is empty. Tap + to add your first class, '
                          'or import one from a CSV file.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/routine/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Class'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.push('/routine/import'),
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('Import from CSV'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final entries = _query.isEmpty
                ? allEntries
                : allEntries
                    .where((e) =>
                        e.subject.toLowerCase().contains(_query.toLowerCase()) ||
                        e.room.toLowerCase().contains(_query.toLowerCase()) ||
                        e.instructor.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _RoutineSearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            'No classes match "$_query"',
                            style: TextStyle(color: dark ? Colors.white60 : Colors.black45),
                          ),
                        )
                      : _RoutineList(entries: entries),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Simple filter field that searches subject, room, and instructor across
/// the loaded routine \u2014 client-side, since the whole list is already in memory.
class _RoutineSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _RoutineSearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: dark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintText: 'Search subject, room, instructor\u2026',
          hintStyle: TextStyle(color: dark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search, color: dark ? Colors.white54 : Colors.black45),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// The day-grouped list, extracted so both the normal and search-filtered
/// views share exactly the same rendering.
class _RoutineList extends StatelessWidget {
  final List<ClassEntry> entries;
  const _RoutineList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final byDay = <int, List<ClassEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.dayOfWeek, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        for (var day = 0; day < 7; day++)
          if (byDay.containsKey(day)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                kDays[day],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : primaryColor,
                ),
              ),
            ),
            ...byDay[day]!.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoutineTile(entry: entry),
              ),
            ),
          ],
      ],
    );
  }
}

class _RoutineTile extends ConsumerWidget {
  final ClassEntry entry;
  const _RoutineTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete class?'),
            content: Text('Remove ${entry.subject} from your routine?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => ref.read(routineProvider.notifier).deleteEntry(entry),
      child: GestureDetector(
        onTap: () => context.push('/routine/edit', extra: entry),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
                      '${entry.room.isNotEmpty ? ' \u2022 Room ${entry.room}' : ''}'
                      '${entry.instructor.isNotEmpty ? ' \u2022 ${entry.instructor}' : ''}',
                      style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: dark ? Colors.white38 : Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
