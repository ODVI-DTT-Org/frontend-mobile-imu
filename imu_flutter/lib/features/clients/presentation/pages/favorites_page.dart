import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/providers/client_favorites_provider.dart';
import '../../../../shared/widgets/client/client_list_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starredAsync = ref.watch(starredClientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Clients'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: starredAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.star, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No starred clients yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the star on any client card to add them here',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ClientListCard(
                client: client,
                onTap: () => context.push('/clients/${client.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
