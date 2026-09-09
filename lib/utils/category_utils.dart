import 'package:flutter/material.dart';

class CategoryUtils {
  const CategoryUtils._();

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Rent',
    'Entertainment',
    'University',
    'Bills',
    'Other',
  ];

  static const List<String> filterOptions = ['All', ...categories];

  static IconData iconFor(String category) {
    return switch (category) {
      'Food' => Icons.restaurant_outlined,
      'Transport' => Icons.directions_bus_outlined,
      'Shopping' => Icons.shopping_bag_outlined,
      'Rent' => Icons.home_outlined,
      'Entertainment' => Icons.movie_outlined,
      'University' => Icons.school_outlined,
      'Bills' => Icons.receipt_long_outlined,
      _ => Icons.category_outlined,
    };
  }
}
