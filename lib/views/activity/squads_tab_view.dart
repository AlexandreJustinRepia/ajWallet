import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../services/squad_service.dart';
import '../../models/squad.dart';
import '../../screens/squad/add_squad_screen.dart';
import '../../screens/squad/squad_detail_screen.dart';

class SquadsTabView extends StatefulWidget {
  final VoidCallback onRefresh;
  const SquadsTabView({super.key, required this.onRefresh});

  @override
  State<SquadsTabView> createState() => _SquadsTabViewState();
}

class _SquadsTabViewState extends State<SquadsTabView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountKey = SessionService.activeAccount?.key as int?;

    if (accountKey == null) {
      return const Center(child: Text('Please select an account first'));
    }

    return StreamBuilder(
      stream: DatabaseService.squadWatcher,
      builder: (context, snapshot) {
        final squads = DatabaseService.getSquads(accountKey);

        if (squads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_3_outlined,
                    size: 64, color: theme.dividerColor),
                const SizedBox(height: 16),
                Text(
                  'No squads yet',
                  style: TextStyle(color: theme.dividerColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _createNewSquad(context, accountKey),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Squad'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            // New Squad Button at the top
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: () => _createNewSquad(context, accountKey),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Create New Squad'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            ...squads.map((squad) {
              final balances = SquadService.calculateBalances(squad.key as int);
              return _SquadCard(
                squad: squad,
                balances: balances,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SquadDetailScreen(squad: squad),
                    ),
                  );
                  setState(() {});
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _createNewSquad(BuildContext context, int accountKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSquadScreen(accountKey: accountKey),
      ),
    );
    if (result == true) {
      widget.onRefresh();
      setState(() {});
    }
  }
}

class _SquadCard extends StatelessWidget {
  final Squad squad;
  final SquadBalances balances;
  final VoidCallback onTap;

  const _SquadCard({
    required this.squad,
    required this.balances,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwed = balances.net > 0;
    final isOwer = balances.net < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (squad.color != null
                              ? Color(int.parse(squad.color!))
                              : theme.primaryColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: squad.color != null
                          ? Color(int.parse(squad.color!))
                          : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          squad.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Net balance: ${balances.net >= 0 ? "+" : ""}₱${balances.net.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOwed
                                ? theme.colorScheme.tertiary
                                : (isOwer
                                    ? theme.colorScheme.error
                                    : theme.dividerColor),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                   _BalanceStat(
                    label: 'YOU ARE OWED',
                    amount: balances.youAreOwed,
                    color: theme.colorScheme.tertiary,
                  ),
                  Container(width: 1, height: 30, color: theme.dividerColor.withValues(alpha:0.2)),
                  _BalanceStat(
                    label: 'YOU OWE',
                    amount: balances.youOwe,
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
