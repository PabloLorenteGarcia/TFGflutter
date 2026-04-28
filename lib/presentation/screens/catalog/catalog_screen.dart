import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';
import 'package:plantcare/presentation/widgets/empty_state.dart';

/// Pantalla del catálogo de plantas
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadPlants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Plantas'),
      ),
      body: Consumer<CatalogProvider>(
        builder: (context, catalogProvider, child) {
          if (catalogProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Buscador
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar plantas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: catalogProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              catalogProvider.search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => catalogProvider.search(value),
                ),
              ),

              // Filtros de categoría
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip(
                      context,
                      'Todas',
                      null,
                      catalogProvider.selectedCategory == null,
                      () => catalogProvider.filterByCategory(null),
                    ),
                    ...PlantCategory.values.map((category) => _buildCategoryChip(
                      context,
                      category.label,
                      category,
                      catalogProvider.selectedCategory == category,
                      () => catalogProvider.filterByCategory(category),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Lista de plantas
              Expanded(
                child: catalogProvider.plants.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No se encontraron plantas',
                        description: 'Prueba con otros términos de búsqueda',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: catalogProvider.plants.length,
                        itemBuilder: (context, index) {
                          final plant = catalogProvider.plants[index];
                          return _buildCatalogCard(context, plant);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    PlantCategory? category,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCatalogCard(BuildContext context, dynamic plant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/catalog/${plant.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono de categoría
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(plant.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(plant.category),
                  color: _getCategoryColor(plant.category),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(plant.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plant.category.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getCategoryColor(plant.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(PlantCategory category) {
    switch (category) {
      case PlantCategory.indoor:
        return AppColors.categoryIndoor;
      case PlantCategory.outdoor:
        return AppColors.categoryOutdoor;
      case PlantCategory.succulent:
        return AppColors.categorySucculent;
      case PlantCategory.flower:
        return AppColors.categoryFlower;
      case PlantCategory.herb:
        return AppColors.categoryHerb;
      case PlantCategory.tree:
        return AppColors.categoryTree;
      case PlantCategory.cactus:
        return AppColors.categoryCactus;
    }
  }

  IconData _getCategoryIcon(PlantCategory category) {
    switch (category) {
      case PlantCategory.indoor:
        return Icons.home;
      case PlantCategory.outdoor:
        return Icons.park;
      case PlantCategory.succulent:
        return Icons.grass;
      case PlantCategory.flower:
        return Icons.local_florist;
      case PlantCategory.herb:
        return Icons.spa;
      case PlantCategory.tree:
        return Icons.park;
      case PlantCategory.cactus:
        return Icons.filter_vintage;
    }
  }
}