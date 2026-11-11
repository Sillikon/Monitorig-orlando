import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/device_model.dart';
import '../screens/device_details_page.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceDetailsPage(device: device),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.memory,
                color: Colors.blueAccent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.name,
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: device.statusColor,
                        size: 9,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        device.statusLabel,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: secondaryText),
          ],
        ),
      ),
    );
  }
}
