import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('My Farms', Icons.landscape_rounded, 'Manage fields and crops'),
      ('Crop Health', Icons.eco_rounded, 'AI disease detection'),
      ('Weather', Icons.cloud_rounded, 'Forecast and alerts'),
      ('Irrigation', Icons.water_drop_rounded, 'Smart water planning'),
      ('Expenses', Icons.account_balance_wallet_rounded, 'Track farm finances'),
      ('Market', Icons.storefront_rounded, 'Prices and opportunities'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSense', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Good morning, Farmer', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Your farm intelligence dashboard', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.agriculture_rounded)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Farm health', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Add your first farm to unlock personalized insights.')]))
              ]),
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
              return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () {}, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.$2, size: 30), const SizedBox(height: 10), Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)]))));
            },
          ),
        ],
      ),
    );
  }
}
