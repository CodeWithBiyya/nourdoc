// import 'package:flutter/material.dart';

// // class PlanModel {
// //   final String id;
// //   final String title;
// //   final String description;
// //   final String price;
// //   final String detailTitle; // "Who it's for" or "Recommended for"
// //   final String detailContent;
// //   final dynamic icon;
// //   final bool isActive;
// //   final String? remainingMinutes;

// //   PlanModel({
// //     required this.id,
// //     required this.title,
// //     required this.description,
// //     required this.price,
// //     required this.detailTitle,
// //     required this.detailContent,
// //     required this.icon,
// //     this.isActive = false,
// //     this.remainingMinutes,
// //   });

//   class PlanModel {
//   final String id;
//   final String title;
//   final String description;
//   final String price;
//   final String detailTitle;
//   final String detailContent;
//   final dynamic icon;
//   final bool isActive;
//   final String? remainingMinutes;

//   PlanModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.price,
//     required this.detailTitle,
//     required this.detailContent,
//     required this.icon,
//     this.isActive = false,
//     this.remainingMinutes,
//   });

//   // Convert API JSON into PlanModel
//   factory PlanModel.fromJson(Map<String, dynamic> json) {
//     return PlanModel(
//       id: json['plan_id']?.toString() ?? '',
//       title: json['name']?.toString() ?? '',
//       description: _buildDescription(json),
//       price: _buildPrice(json),
//       // API values
//     detailTitle: json['detail_title']?.toString() ?? '',
//     detailContent: json['detail_content']?.toString() ?? '',
//     icon: json['icon']?.toString() ?? '',
//     );
//   }

//   static String _buildDescription(
//     Map<String, dynamic> json,
//   ) {
//     final minutes = json['included_minutes'] ?? 0;
//     final expiryDays = json['expiry_days'] ?? 0;

//     return 'Up to $minutes AI minutes for $expiryDays days';
//   }

//   static String _buildPrice(
//     Map<String, dynamic> json,
//   ) {
//     final discounted = json['discounted_price'] ?? 0;
//     final display = json['display_price'] ?? 0;
//     final currency = json['currency'] ?? 'PKR';

//     final price = discounted != 0
//         ? discounted
//         : display;

//     return '$currency $price';
//   }

//   // static String _getIcon(String planCode) {
//   //   switch (planCode.toLowerCase()) {
//   //     case 'trial':
//   //       return 'assets/icons/clock.48 3.png';

//   //     case 'starter':
//   //       return 'assets/icons/stethoscope.48 1.png';

//   //     case 'growth':
//   //       return 'assets/icons/time-to-market 1.png';

//   //     case 'professional':
//   //       return 'assets/icons/briefcase 1.png';

//   //     case 'enterprise':
//   //       return 'assets/icons/briefcase 1.png';

//   //     default:
//   //       return 'assets/icons/clock.48 3.png';
//   //   }
//   // }
// }
class PlanModel {
  final String id;
  final String planCode;
  final String title;

  final double displayPrice;
  final double discountedPrice;

  final String currency;

  final int includedMinutes;
  final int includedSeconds;
  final int expiryDays;

  final bool isTrial;

  // UI fields
  final bool isActive;
  final String? remainingMinutes;

  PlanModel({
    required this.id,
    required this.planCode,
    required this.title,
    required this.displayPrice,
    required this.discountedPrice,
    required this.currency,
    required this.includedMinutes,
    required this.includedSeconds,
    required this.expiryDays,
    required this.isTrial,
    this.isActive = false,
    this.remainingMinutes,
  });

  // factory PlanModel.fromJson(Map<String, dynamic> json) {
  //   return PlanModel(
  //     id: json['id']?.toString() ?? '',
  //     planCode: json['plan_code']?.toString() ?? '',
  //     title: json['name']?.toString() ?? '',

  //     displayPrice:
  //         double.tryParse(
  //               json['display_price']?.toString() ?? '0',
  //             ) ??
  //             0,

  //     discountedPrice:
  //         double.tryParse(
  //               json['discounted_price']?.toString() ?? '0',
  //             ) ??
  //             0,

  //     currency: json['currency']?.toString() ?? 'PKR',

  //     includedMinutes:
  //         int.tryParse(
  //               json['included_minutes']?.toString() ?? '0',
  //             ) ??
  //             0,

  //     includedSeconds:
  //         int.tryParse(
  //               json['included_seconds']?.toString() ?? '0',
  //             ) ??
  //             0,

  //     expiryDays:
  //         int.tryParse(
  //               json['expiry_days']?.toString() ?? '0',
  //             ) ??
  //             0,

  //     isTrial: json['is_trial'] == true,
  //   );
  // }

factory PlanModel.fromJson(Map<String, dynamic> json) {
  return PlanModel(
    id: json['id']?.toString() ?? '',

    // API has "name", e.g. TRIAL / STARTER
    planCode: json['name']?.toString() ?? '',

    title: json['name']?.toString() ?? '',

    // API has "price"
    displayPrice:
        double.tryParse(
              json['price']?.toString() ?? '0',
            ) ??
            0,

    discountedPrice:
        double.tryParse(
              json['price']?.toString() ?? '0',
            ) ??
            0,

    currency: json['currency']?.toString() ?? 'PKR',

    // Convert seconds from API to minutes for UI
    includedMinutes:
        ((int.tryParse(
                  json['included_seconds']?.toString() ?? '0',
                ) ??
                0) /
            60)
            .floor(),

    includedSeconds:
        int.tryParse(
              json['included_seconds']?.toString() ?? '0',
            ) ??
            0,

    // API has "validity_days"
    expiryDays:
        int.tryParse(
              json['validity_days']?.toString() ?? '0',
            ) ??
            0,

    // API doesn't provide is_trial, so determine it from name
    isTrial:
        json['name']?.toString().toLowerCase() == 'trial',
  );
}
  // ---------------------------------------------------------
  // Actual price to display
  // ---------------------------------------------------------

  double get effectivePrice {
    if (discountedPrice > 0) {
      return discountedPrice;
    }

    return displayPrice;
  }

  // ---------------------------------------------------------
  // Formatted price
  // ---------------------------------------------------------

  String get formattedPrice {
    if (effectivePrice == 0) {
      return '$currency 0';
    }

    if (effectivePrice % 1 == 0) {
      return '$currency ${effectivePrice.toInt()}';
    }

    return '$currency ${effectivePrice.toStringAsFixed(2)}';
  }

  // ---------------------------------------------------------
  // Description
  // ---------------------------------------------------------

  String get description {
    if (includedMinutes > 0 && expiryDays > 0) {
      return 'Up to $includedMinutes AI minutes for $expiryDays days';
    }

    if (includedMinutes > 0) {
      return 'Up to $includedMinutes AI minutes';
    }

    return 'Subscription plan';
  }

  // ---------------------------------------------------------
  // Display title
  // ---------------------------------------------------------

  String get displayTitle {
   final cleanTitle = title.trim();

  // If API already returns "Trial Plan", "Starter Plan", etc.
  // don't add another "Plan".
  if (cleanTitle.toLowerCase().endsWith(' plan')) {
    return cleanTitle;
  }

  // If API returns only "Trial", "Starter", etc.
  // add "Plan" once.
  return '$cleanTitle Plan';
  }

  // ---------------------------------------------------------
  // Icon
  // ---------------------------------------------------------

  String get icon {
    switch (planCode.toLowerCase()) {
      case 'trial':
        return 'assets/icons/clock.48 3.png';

      case 'starter':
        return 'assets/icons/stethoscope.48 1.png';

      case 'growth':
        return 'assets/icons/time-to-market 1.png';

      case 'professional':
        return 'assets/icons/briefcase 1.png';

      case 'enterprise':
        return 'assets/icons/briefcase 1.png';

      default:
        return 'assets/icons/clock.48 3.png';
    }
  }
}