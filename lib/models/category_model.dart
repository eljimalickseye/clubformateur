import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final int count;
  final IconData icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.count,
    required this.icon,
  });

  static List<CategoryModel> get defaultCategories => [
    CategoryModel(
      id: 'informatique',
      name: 'Informatique',
      description: 'Développement, bureautique...',
      count: 120,
      icon: Icons.computer_rounded,
    ),
    CategoryModel(
      id: 'marketing',
      name: 'Marketing',
      description: 'Digital, réseaux sociaux...',
      count: 80,
      icon: Icons.campaign_rounded,
    ),
    CategoryModel(
      id: 'business',
      name: 'Business',
      description: 'Entrepreneuriat, gestion...',
      count: 90,
      icon: Icons.bar_chart_rounded,
    ),
    CategoryModel(
      id: 'design',
      name: 'Design',
      description: 'Graphisme, UI/UX...',
      count: 60,
      icon: Icons.palette_rounded,
    ),
    CategoryModel(
      id: 'dev_perso',
      name: 'Développement personnel',
      description: 'Confiance, productivité...',
      count: 50,
      icon: Icons.groups_rounded,
    ),
    CategoryModel(
      id: 'autres',
      name: 'Autres domaines',
      description: 'Langues, sciences...',
      count: 40,
      icon: Icons.more_horiz_rounded,
    ),
  ];
}
