import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/skill_model.dart';
import '../providers/auth_providers.dart';
import '../providers/skill_providers.dart';

class AddSkillBottomSheet extends ConsumerStatefulWidget {
  const AddSkillBottomSheet({super.key});

  @override
  ConsumerState<AddSkillBottomSheet> createState() => _AddSkillBottomSheetState();
}

class _AddSkillBottomSheetState extends ConsumerState<AddSkillBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Tech';
  int _timeValue = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataAsync = ref.watch(userDataProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (rest of the widget)
            Text(
              'Offer a New Skill',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Skill Title',
                hintText: 'e.g. Guitar Lessons',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Tech', 'Repair', 'Cooking', 'Music', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Time Value (Crono Units):'),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _timeValue = (_timeValue > 1) ? _timeValue - 1 : 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_timeValue', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _timeValue++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            userDataAsync.when(
              data: (user) => ElevatedButton(
                onPressed: user == null ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    final newSkill = SkillModel(
                      id: const Uuid().v4(),
                      title: _titleController.text,
                      description: _descController.text,
                      category: _category,
                      providerId: user.id,
                      providerName: user.name,
                      timeValue: _timeValue,
                    );
                    await ref.read(skillRepositoryProvider).addSkill(newSkill);
                    ref.invalidate(skillListProvider);
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Skill offered successfully!')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Post Skill Offer'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Error loading user')),
            ),
          ],
        ),
      ),
    );
  }
}
