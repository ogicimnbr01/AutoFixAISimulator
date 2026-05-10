import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/services/revenuecat_service.dart';

// Provider to fetch and cache all available Offerings
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    print('Error fetching offerings: $e');
    return null;
  }
});

// Provider to fetch the current CustomerInfo (active subscriptions, entitlements)
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  return await RevenueCatService.getCustomerInfo();
});
