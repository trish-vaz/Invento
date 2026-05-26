import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/inventory_controller.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/date_utils.dart';
import '../../models/inventory_model.dart';
import '../../models/location_inventory_group.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryController = InventoryController();
    final authController = AuthController();
    final currentUser = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              currentUser?.email ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan or add batch',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/inventory'),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Inventory',
          ),
          IconButton(
            onPressed: () async {
              await authController.logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
        label: const Text('Scan or add batch'),
        icon: const Icon(Icons.add_box_outlined),
      ),
      body: StreamBuilder<List<InventoryBatchModel>>(
        stream: inventoryController.watchBatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final batches = snapshot.data!;
          final totalUnits = batches.fold<int>(
            0,
            (sum, batch) => sum + batch.remainingQuantity,
          );
          final expiringSoon = batches
              .where((batch) => batch.isExpiringSoon())
              .length;
          final uniqueLocations = batches
              .map((batch) => batch.locationLabel)
              .where((location) => location.trim().isNotEmpty)
              .toSet()
              .length;
          final suggestions = _buildSuggestions(batches);
          final locationGroups = buildLocationInventoryGroups(batches);
          final activeLocationGroups = locationGroups
              .where((group) => group.hasActiveBatches)
              .take(4)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Track batches by expiry, storage location, and the exact front/back pick order inside each location.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'Active batches',
                    value: batches.length.toString(),
                    icon: Icons.inventory,
                  ),
                  _SummaryCard(
                    title: 'Units in stock',
                    value: totalUnits.toString(),
                    icon: Icons.category_outlined,
                  ),
                  _SummaryCard(
                    title: 'Expiring soon',
                    value: expiringSoon.toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                  _SummaryCard(
                    title: 'Locations',
                    value: uniqueLocations.toString(),
                    icon: Icons.place_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location pick guidance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/inventory'),
                    child: const Text('View inventory'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activeLocationGroups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No inventory batches yet. Add your first batch to start tracking same-location FIFO picks.',
                    ),
                  ),
                ),
              for (final group in activeLocationGroups)
                _LocationGuidanceCard(group: group),
              const SizedBox(height: 28),
              Text(
                'Earliest expiry batches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (suggestions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No active batches to suggest yet. Add inventory to start smart picking.',
                    ),
                  ),
                ),
              for (final batch in suggestions) ProductCard(batch: batch),
            ],
          );
        },
      ),
    );
  }

  List<InventoryBatchModel> _buildSuggestions(
    List<InventoryBatchModel> batches,
  ) {
    final filtered =
        batches
            .where((batch) => batch.remainingQuantity > 0 && !batch.isExpired)
            .toList()
          ..sort((a, b) {
            final expiryCompare = a.effectiveExpiryDate.compareTo(
              b.effectiveExpiryDate,
            );
            if (expiryCompare != 0) {
              return expiryCompare;
            }
            return a.locationPositionRank.compareTo(b.locationPositionRank);
          });

    return filtered.take(4).toList();
  }
}

class _LocationGuidanceCard extends StatelessWidget {
  const _LocationGuidanceCard({required this.group});

  final LocationInventoryGroup group;

  @override
  Widget build(BuildContext context) {
    final nextPick = group.nextOverallPick;
    final productGuidance = group.productGuidance.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.locationLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${group.activeBatchCount} active'),
              ],
            ),
            if (nextPick != null) ...[
              const SizedBox(height: 14),
              Text(
                'Pick first: ${nextPick.productName} • Batch ${nextPick.batchNumber}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Expiry ${formatShortDate(nextPick.expiryDate)} • Position ${nextPick.locationPositionLabel} • Qty ${nextPick.remainingQuantity}',
              ),
            ],
            const SizedBox(height: 14),
            for (final guidance in productGuidance) ...[
              _ProductGuidanceRow(guidance: guidance),
              if (guidance != productGuidance.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductGuidanceRow extends StatelessWidget {
  const _ProductGuidanceRow({required this.guidance});

  final LocationProductGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final nextPick = guidance.nextPick;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guidance.productName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (nextPick != null) ...[
            const SizedBox(height: 4),
            Text(
              'FIFO pick: Batch ${nextPick.batchNumber} • Expiry ${formatShortDate(nextPick.expiryDate)} • ${nextPick.locationPositionLabel}',
            ),
          ],
          if (guidance.needsRotation) ...[
            const SizedBox(height: 8),
            Text(
              'Rotation needed: move the earliest-expiry batch to the front of this location.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
