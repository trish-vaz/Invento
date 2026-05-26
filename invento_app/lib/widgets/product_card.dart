import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/inventory_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.batch, this.trailing});

  final InventoryBatchModel batch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final expiringSoon = batch.isExpiringSoon();
    final statusColor = batch.isExpired
        ? Colors.red.shade100
        : expiringSoon
        ? Colors.orange.shade100
        : Colors.green.shade100;

    final statusLabel = batch.isExpired
        ? 'Expired'
        : expiringSoon
        ? 'Expiring soon'
        : batch.computedStatus[0].toUpperCase() +
              batch.computedStatus.substring(1);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(batch.productName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch ${batch.batchNumber} • Qty '
                '${batch.remainingQuantity}/${batch.quantity}',
              ),
              const SizedBox(height: 4),
              Text(
                'Expiry ${formatShortDate(batch.expiryDate)} • '
                '${batch.warehouseName} / ${batch.locationCode}',
              ),
              const SizedBox(height: 4),
              Text('Position ${batch.locationPositionLabel}'),
              if (batch.sku.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('SKU ${batch.sku}'),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusLabel),
              ),
            ],
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
