import 'package:flutter/material.dart';
import '../../models/squad.dart';
import '../../models/squad_member.dart';
import '../../services/database_service.dart';
import '../../widgets/onboarding_overlay.dart';

class AddSquadScreen extends StatefulWidget {
  final int accountKey;
  const AddSquadScreen({super.key, required this.accountKey});

  @override
  State<AddSquadScreen> createState() => _AddSquadScreenState();
}

class _AddSquadScreenState extends State<AddSquadScreen> {
  final _nameController = TextEditingController();
  final _memberController = TextEditingController();
  final List<String> _members = [];
  int _youIndex = 0; // Default first member is "You"
  bool _isTutorialActive = false;

  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _memberKey = GlobalKey();
  final GlobalKey _createKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _members.add("You"); // Pre-fill with "You"
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isNotEmpty && !_members.contains(name)) {
      setState(() {
        _members.add(name);
        _memberController.clear();
      });
    }
  }

  void _removeMember(int index) {
    if (_members.length > 1) {
      setState(() {
        _members.removeAt(index);
        if (_youIndex >= _members.length) {
          _youIndex = _members.length - 1;
        }
      });
    }
  }

  void _saveSquad() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a squad name')),
      );
      return;
    }

    if (_members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A squad needs at least 2 members')),
      );
      return;
    }

    final squad = Squad(
      name: name,
      accountKey: widget.accountKey,
      createdAt: DateTime.now(),
    );

    final squadKey = await DatabaseService.saveSquad(squad);

    for (int i = 0; i < _members.length; i++) {
      final member = SquadMember(
        name: _members[i],
        squadKey: squadKey,
        isYou: i == _youIndex,
      );
      await DatabaseService.saveSquadMember(member);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Squad'),
        actions: [
          IconButton(
            key: _helpKey,
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => setState(() => _isTutorialActive = true),
          ),
        ],
      ),
      body: OnboardingOverlay(
        visible: _isTutorialActive,
        onFinish: () => setState(() => _isTutorialActive = false),
        steps: [
          OnboardingStep(
            title: 'Start Your Squad',
            description: 'Set up a group to begin splitting bills and tracking who owes what in RootEXP.',
          ),
          OnboardingStep(
            targetKey: _helpKey,
            title: 'Help Anytime',
            description: 'You can tap this icon again if you need to replay this guide.',
          ),
          OnboardingStep(
            targetKey: _nameKey,
            title: 'Squad Identity',
            description: 'Give your squad a clear name like "Beach Trip" or "Office Lunch".',
          ),
          OnboardingStep(
            targetKey: _memberKey,
            title: 'Add Your Friends',
            description: 'Type a name and tap (+) to add members. Everyone in this list will be able to split bills.',
          ),
          OnboardingStep(
            targetKey: _createKey,
            title: 'Ready to Launch',
            description: 'Tap Create Squad when you are ready to start tracking expenses!',
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SQUAD NAME',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: _nameKey,
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Barkada Trip, Roommates',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'MEMBERS',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                key: _memberKey,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberController,
                      decoration: InputDecoration(
                        hintText: 'Member name',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _addMember,
                    icon: const Icon(Icons.person_add_rounded),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final isYou = index == _youIndex;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isYou 
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isYou ? theme.primaryColor : theme.dividerColor,
                        width: isYou ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isYou ? theme.primaryColor : theme.dividerColor,
                          child: Text(
                            _members[index][0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isYou ? Colors.white : theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _members[index],
                            style: TextStyle(
                              fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (!isYou)
                          TextButton(
                            onPressed: () => setState(() => _youIndex = index),
                            child: const Text('Mark as You', style: TextStyle(fontSize: 12)),
                          ),
                        if (isYou)
                          const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _removeMember(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          key: _createKey,
          onPressed: _saveSquad,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Create Squad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
