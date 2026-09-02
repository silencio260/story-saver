import 'package:equatable/equatable.dart';

/// Represents a purchasable product/subscription
class Product extends Equatable {
  final String id;
  final String title;
  final String description;
  final String price;
  final double priceAmount;
  final String currencyCode;
  final ProductType type;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmount,
    required this.currencyCode,
    required this.type,
  });

  @override
  List<Object?> get props => [id, title, price, type];
}

enum ProductType { subscription, nonConsumable, consumable }
