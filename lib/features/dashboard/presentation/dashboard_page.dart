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
    final cards = <({String title, IconData icon, String subtitle, String route})>[
      (title: 'My Farms', icon: Icons.landscape_rounded, subtitle: 'Manage farms, fields and crops', route: '/farms'),
      (title: 'AI Assistant', icon: Icons.auto_awesome_rounded, subtitle: 'Personalized farming guidance', route: '/assistant'),
      (title: 'Crop Health', icon: Icons.eco_rounded, subtitle: 'AI disease detection', route: '/disease'),
      (title: 'Weather', icon: Icons.cloud_rounded, subtitle: 'Forecast and alerts', route: '/weather'),
      (title: 'Irrigation', icon: Icons.water_drop_rounded, subtitle: 'Weather-based water planning', route: '/irrigation'),
      (title: 'Market', icon: Icons.storefront_rounded, subtitle: 'Mandi prices and alerts', route: '/market'),
      (title: 'Finance', icon: Icons.account_balance_wallet_rounded, subtitle: 'Income, expenses and profit', route: '/finance'),
      (title: 'IoT Monitor', icon: Icons.sensors_rounded, subtitle: 'Live ESP32 farm sensors', route: '/iot'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSense', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          StreamBuilder(
            stream: NotificationRepository(Supabase.instance.client).watch(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? const [];
              final unread = notifications.where((item) => !item.read).length;
              return IconButton(
                onPressed: () => context.go('/notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Good morning, Farmer',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Your farm intelligence dashboard'),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.agriculture_rounded),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farm intelligence', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text('Manage your farm, monitor crops, plan irrigation, compare markets and connect live farm sensors.'),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(card.route),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card.icon, size: 30),
                        const SizedBox(height: 10),
                        Text(card.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          card.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
