import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import 'package:apna/features/smart_sync/presentation/providers/smart_sync_providers.dart';
import 'package:apna/features/smart_sync/data/services/sms_native_service.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../providers/calendar_providers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'ALL'; // ALL, BILL, WARRANTY, HEALTH, TASK
  static const _uuid = Uuid();

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime eventDate = _selectedDate;
    TimeOfDay eventTime = const TimeOfDay(hour: 10, minute: 0);
    String category = 'general';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Reminder / Event', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Electricity Bill Due Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description / Notes',
                      hintText: 'e.g. Meter No 558192, pay before 6 PM',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('General Reminder')),
                      DropdownMenuItem(value: 'bill', child: Text('Bill Due Date')),
                      DropdownMenuItem(value: 'warranty', child: Text('Warranty Expiry')),
                      DropdownMenuItem(value: 'health', child: Text('Doctor / Health Checkup')),
                      DropdownMenuItem(value: 'task', child: Text('Family Task')),
                    ],
                    onChanged: (val) => setDialogState(() => category = val ?? 'general'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Date: ${DateFormat('EEE, dd MMM yyyy').format(eventDate)}'),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: eventDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => eventDate = picked);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: ApnaColors.border),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final user = ref.read(authControllerProvider).valueOrNull;
                final ws = ref.read(activeWorkspaceProvider);
                if (user == null || ws == null) return;

                final startDateTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  eventTime.hour,
                  eventTime.minute,
                );

                final newEvent = CalendarEventEntity(
                  id: _uuid.v4(),
                  workspaceId: ws.id,
                  ownerId: user.id,
                  title: title,
                  description: descController.text.trim(),
                  startTime: startDateTime,
                  category: category,
                );

                await ref.read(calendarRepositoryProvider).createEvent(newEvent);
                ref.invalidate(workspaceCalendarEventsProvider);
                if (context.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'bill':
        return ApnaColors.error;
      case 'warranty':
        return ApnaColors.warning;
      case 'health':
        return Colors.purple;
      case 'task':
        return ApnaColors.blue;
      default:
        return ApnaColors.primary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'bill':
        return Icons.receipt_long_rounded;
      case 'warranty':
        return Icons.verified_user_outlined;
      case 'health':
        return Icons.local_hospital_outlined;
      case 'task':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(workspaceCalendarEventsProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: const Text('Calendar & Deadlines', style: ApnaTypography.headingSmall),
        actions: [
          IconButton(
            tooltip: 'Sync 30-Day Bills & Deadlines',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              final hasPerm = await SmsNativeService.ensureSmsPermissionOrPrompt(context);
              if (!hasPerm) return;

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scanning recent messages & statement dates...')),
                );
              }
              final res = await ref.read(smartSyncControllerProvider.notifier).runDeviceSmsSync();
              ref.invalidate(workspaceCalendarEventsProvider);
              if (context.mounted && res != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message), backgroundColor: ApnaColors.success),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event'),
        backgroundColor: ApnaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allEvents) {
          final filtered = allEvents.where((e) {
            if (_selectedFilter == 'ALL') return true;
            return e.category.toLowerCase() == _selectedFilter.toLowerCase();
          }).toList();

          return Column(
            children: [
              // Month overview card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ApnaColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: ApnaColors.primary.withOpacity(0.1),
                      child: Text(
                        DateFormat('dd').format(_selectedDate),
                        style: const TextStyle(
                          color: ApnaColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filtered.length} upcoming deadlines & reminders',
                            style: const TextStyle(color: ApnaColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['ALL', 'BILL', 'WARRANTY', 'HEALTH', 'TASK'].map((f) {
                    final isSel = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(f == 'ALL' ? 'All Deadlines' : f[0] + f.substring(1).toLowerCase()),
                        onSelected: (_) => setState(() => _selectedFilter = f),
                        selectedColor: ApnaColors.primary.withOpacity(0.15),
                        checkmarkColor: ApnaColors.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Timeline list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_available_outlined, size: 64, color: ApnaColors.border),
                            const SizedBox(height: 16),
                            const Text('No upcoming events in this view', style: ApnaTypography.headingSmall),
                            const SizedBox(height: 8),
                            const Text('Sync your recent messages or add custom reminders.', style: ApnaTypography.bodyMedium),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showAddEventDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Reminder'),
                              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final event = filtered[idx];
                          final color = _getCategoryColor(event.category);
                          final icon = _getCategoryIcon(event.category);

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: ApnaColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              title: Text(
                                event.title,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(event.description, style: const TextStyle(fontSize: 13, color: ApnaColors.textSecondary)),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: ApnaColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('EEE, dd MMM yyyy').format(event.startTime),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ApnaColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                onPressed: () async {
                                  await ref.read(calendarRepositoryProvider).deleteEvent(event.id);
                                  ref.invalidate(workspaceCalendarEventsProvider);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
