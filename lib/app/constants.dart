import 'package:flutter/material.dart';

import '../shared/models/models.dart';

/// Metadata for a service mode (label + icon + vocabulary hint).
class ModeMeta {
  const ModeMeta(this.label, this.icon, this.hint);

  final String label;
  final IconData icon;
  final String hint;
}

/// Display metadata for the four service modes.
const Map<ServiceMode, ModeMeta> modeMeta = {
  ServiceMode.hospital:
      ModeMeta('হাসপাতাল', Icons.local_hospital, 'ডাক্তার, ওষুধ, ব্যথা'),
  ServiceMode.emergency:
      ModeMeta('জরুরি', Icons.emergency, 'অ্যাম্বুলেন্স, পুলিশ, রক্ত'),
  ServiceMode.government:
      ModeMeta('সরকারি সেবা', Icons.account_balance, 'NID, ফর্ম, জন্ম নিবন্ধন'),
  ServiceMode.general:
      ModeMeta('সাধারণ', Icons.chat_bubble_outline, 'দৈনন্দিন কথাবার্তা'),
};
