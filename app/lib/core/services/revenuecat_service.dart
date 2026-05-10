import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // TODO: Replace with your actual RevenueCat Public API Keys
  static const String _appleApiKey =
      'appl_YOUR_IOS_KEY'; // TODO: Update when iOS is ready
  static const String _googleApiKey = 'goog_HawCCKZNzvDgOAsgFcklTVNRrlS';

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else {
      configuration = PurchasesConfiguration(_appleApiKey);
    }

    await Purchases.configure(configuration);
  }

  static Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } on PlatformException catch (e) {
      print('RevenueCat logIn failed: ${e.message}');
    }
  }

  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } on PlatformException catch (e) {
      print('RevenueCat logOut failed: ${e.message}');
    }
  }

  static Future<List<Offering>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return [offerings.current!];
      }
      return [];
    } on PlatformException catch (e) {
      print('Failed to get offerings: ${e.message}');
      return [];
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      final customerInfo = purchaseResult.customerInfo;
      // For subscriptions, check if 'pro' entitlement is active
      final isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;

      // For consumable purchases (hints), the transaction completes successfully,
      // and our backend webhook will add the hint credits via DynamoDB.
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Purchase failed: ${e.message}');
      }
      return false;
    }
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      print('Failed to get customer info: ${e.message}');
      return null;
    }
  }
}
