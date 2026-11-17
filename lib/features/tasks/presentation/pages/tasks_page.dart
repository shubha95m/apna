import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String _filter = 'ALL'; // ALL, PENDING, COMPLETED, HIGH

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Family Task', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'e.g. Schedule Water Purifier Service',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add notes or instructions...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Priority:', style: ApnaTypography.bodyMedium),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: priority,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => priority = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: ApnaColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                        style: ApnaTypography.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final workspaceId = ref.read(activeWorkspaceIdProvider);
                final currentUserId = Supabase.instance.client.auth.currentUser?.id ??
                    ref.read(authControllerProvider).valueOrNull?.id ??
                    'user-anonymous';
                final newTask = TaskEntity(
                  id: const Uuid().v4(),
                  workspaceId: workspaceId,
                  creatorId: currentUserId,
                  title: title,
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                  priority: priority,
                  status: 'pending',
                  dueDate: selectedDate,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                ref.read(taskListNotifierProvider.notifier).addTask(newTask);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListNotifierProvider);
    final canWrite = ref.watch(canWriteCurrentWorkspaceProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ApnaColors.error),
              const SizedBox(height: 12),
              Text('Failed to load tasks: $err', style: ApnaTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(taskListNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tasks) {
          final pendingCount = tasks.where((t) => !t.isCompleted).length;
          final completedCount = tasks.where((t) => t.isCompleted).length;

          final filteredTasks = tasks.where((t) {
            if (_filter == 'PENDING') return !t.isCompleted;
            if (_filter == 'COMPLETED') return t.isCompleted;
            if (_filter == 'HIGH') return t.priority == 'high' || t.priority == 'urgent';
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tasks & Family Chores', style: ApnaTypography.headingLarge),
                              const SizedBox(height: 4),
                              Text(
                                '$pendingCount pending • $completedCount completed • Live Supabase Sync',
                                style: ApnaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          if (canWrite)
                            FilledButton.icon(
                              onPressed: () => _showAddTaskDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Task'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ApnaColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: ApnaColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ApnaColors.border),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 14, color: ApnaColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('Read Only', style: TextStyle(fontSize: 12, color: ApnaColors.textSecondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All Tasks (${tasks.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('PENDING', 'Pending ($pendingCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('COMPLETED', 'Completed ($completedCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('HIGH', 'High Priority'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Task List
              if (filteredTasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 56, color: ApnaColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No tasks in this view', style: ApnaTypography.headingSmall),
                        SizedBox(height: 4),
                        Text('All caught up or try switching filters.', style: ApnaTypography.bodySmall),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskCard(task);
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = filterKey);
      },
      selectedColor: ApnaColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : ApnaColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTaskCard(TaskEntity task) {
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        priorityColor = ApnaColors.error;
        break;
      case 'medium':
        priorityColor = ApnaColors.warning;
        break;
      default:
        priorityColor = ApnaColors.accentDark;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isCompleted ? ApnaColors.border.withOpacity(0.5) : ApnaColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: task.isCompleted,
              activeColor: ApnaColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: ref.watch(canWriteCurrentWorkspaceProvider)
                  ? (_) {
                      ref.read(taskListNotifierProvider.notifier).toggleTaskStatus(task);
                    }
                  : null,
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? ApnaColors.textSecondary : ApnaColors.textPrimary,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      style: ApnaTypography.bodySmall.copyWith(
                        color: ApnaColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority.toUpperCase(),
                          style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.schedule_rounded, size: 14, color: ApnaColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Due ${DateFormat('dd MMM').format(task.dueDate!)}',
                          style: const TextStyle(fontSize: 11.5, color: ApnaColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete action
            if (ref.watch(canWriteCurrentWorkspaceProvider))
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ApnaColors.textSecondary),
                tooltip: 'Delete Task',
                onPressed: () {
                  ref.read(taskListNotifierProvider.notifier).deleteTask(task.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}
