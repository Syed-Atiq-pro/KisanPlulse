import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/data/notification_repository.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('My Farms', Icons.landscape_rounded, 'Manage farms, fields and crops', '/farms'),
      ('AI Assistant', Icons.auto_awesome_rounded, 'Personalized farming guidance', '/assistant'),
      ('Crop Health', Icons.eco_rounded, 'AI disease detection', '/disease'),
      ('Weather', Icons.cloud_rounded, 'Forecast and alerts', '/weather'),
      ('Irrigation', Icons.water_drop_rounded, 'Weather-based water planning', '/irrigation'),
      ('Market', Icons.storefront_rounded, 'Mandi prices and alerts', '/market'),
      ('Finance', Icons.account_balance_wallet_rounded, 'Income, expenses and profit', '/finance'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSense', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          StreamBuilder(
            stream: NotificationRepository(Supabase.instance.client).watch(),
            builder: (context, snapshot) {
              final unread = (snapshot.data ?? const [])
                  .where((item) => !item.read)
                  .length;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Good morning, Farmer', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Your farm intelligence dashboard'),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.agriculture_rounded)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farm intelligence', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text('Manage your farm, monitor crop health, plan irrigation and compare market opportunities.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final item = cards[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(item.$4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$2, size: 30),
                        const SizedBox(height: 10),
                        Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
