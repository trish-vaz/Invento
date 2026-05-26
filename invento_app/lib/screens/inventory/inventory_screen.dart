import 'package:flutter/material.dart';

import '../../controllers/inventory_controller.dart';
import '../../core/utils/date_utils.dart';
import '../../models/inventory_model.dart';
import '../../models/location_inventory_group.dart';
import '../../widgets/product_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _deleteBatch(
    BuildContext context,
    InventoryController controller,
    InventoryBatchModel batch,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete batch'),
            content: Text(
              'Remove batch ${batch.batchNumber} for ${batch.productName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await controller.deleteBatch(batch.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Batch deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final controller = InventoryController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
            icon: const Icon(Icons.add),
            tooltip: 'Add batch',
          ),
        ],
      ),
      body: StreamBuilder<List<InventoryBatchModel>>(
        stream: controller.watchBatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final batches = snapshot.data!;
          if (batches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No batches found yet. Add inventory to get started.',
                ),
              ),
            );
          }

          final locations = buildLocationInventoryGroups(batches);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final group in locations)
                _LocationInventoryCard(
                  group: group,
                  onDeleteBatch: (batch) =>
                      _deleteBatch(context, controller, batch),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationInventoryCard extends StatelessWidget {
  const _LocationInventoryCard({
    required this.group,
    required this.onDeleteBatch,
  });

  final LocationInventoryGroup group;
  final Future<void> Function(InventoryBatchModel batch) onDeleteBatch;

  @override
  Widget build(BuildContext context) {
    final nextPick = group.nextOverallPick;
    final productGuidance = group.productGuidance;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${group.activeBatchCount} active'),
              ],
            ),
            if (nextPick != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick next: ${nextPick.productName} • Batch ${nextPick.batchNumber}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expiry ${formatShortDate(nextPick.expiryDate)} • Position ${nextPick.locationPositionLabel} • Qty ${nextPick.remainingQuantity}',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (final guidance in productGuidance) ...[
              _LocationProductSection(
                guidance: guidance,
                onDeleteBatch: onDeleteBatch,
              ),
              if (guidance != productGuidance.last) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationProductSection extends StatelessWidget {
  const _LocationProductSection({
    required this.guidance,
    required this.onDeleteBatch,
  });

  final LocationProductGuidance guidance;
  final Future<void> Function(InventoryBatchModel batch) onDeleteBatch;

  @override
  Widget build(BuildContext context) {
    final nextPick = guidance.nextPick;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guidance.productName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (nextPick != null) ...[
          const SizedBox(height: 4),
          Text(
            'FIFO pick: Batch ${nextPick.batchNumber} • Expiry ${formatShortDate(nextPick.expiryDate)} • ${nextPick.locationPositionLabel}',
          ),
        ],
        if (guidance.needsRotation) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Rotation needed: move the earliest-expiry batch to the front before the next pick.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final batch in guidance.sortedBatches) ...[
          ProductCard(
            batch: batch,
            trailing: IconButton(
              onPressed: () => onDeleteBatch(batch),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete batch',
            ),
          ),
        ],
      ],
    );
  }
}
