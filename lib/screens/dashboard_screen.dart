import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_app/models/product.dart';
import 'package:my_app/utils/colorss.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../screens/add_screen.dart';
import '../screens/edit_screen.dart';
import '../services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      if (!productProvider.isLoading && productProvider.hasMore) {
        productProvider.loadProducts();
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).setSearchQuery(value);
    });
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sort, color: AppColors.whiteColor),
                  title: const Text(
                    'None',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () {
                    provider.setSortOption(SortOption.none);
                    Navigator.pop(context);
                  },
                  selected: provider.sortOption == SortOption.none,
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward, color: AppColors.whiteColor),
                  title: const Text(
                    'Price: Low to High',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () {
                    provider.setSortOption(SortOption.priceAsc);
                    Navigator.pop(context);
                  },
                  selected: provider.sortOption == SortOption.priceAsc,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.arrow_downward,
                    color: AppColors.whiteColor,
                  ),
                  title: const Text(
                    'Price: High to Low',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () {
                    provider.setSortOption(SortOption.priceDesc);
                    Navigator.pop(context);
                  },
                  selected: provider.sortOption == SortOption.priceDesc,
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward, color: AppColors.whiteColor),
                  title: const Text(
                    'Stock: Low to High',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () {
                    provider.setSortOption(SortOption.stockAsc);
                    Navigator.pop(context);
                  },
                  selected: provider.sortOption == SortOption.stockAsc,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.arrow_downward,
                    color: AppColors.whiteColor,
                  ),
                  title: const Text(
                    'Stock: High to Low',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () {
                    provider.setSortOption(SortOption.stockDesc);
                    Navigator.pop(context);
                  },
                  selected: provider.sortOption == SortOption.stockDesc,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A4A6F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Export Products',
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppColors.red),
                  title: const Text(
                    'Export to PDF',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    _exportProducts(
                      context,
                      provider.allFilteredProducts,
                      'PDF',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: AppColors.buttonSecondary),
                  title: const Text(
                    'Export to CSV',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    _exportProducts(
                      context,
                      provider.allFilteredProducts,
                      'CSV',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportProducts(
    BuildContext context,
    List products,
    String format,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );

      File file;
      if (format == 'PDF') {
        file = await ExportService.exportToPdf(List<Product>.from(products));
      } else {
        file = await ExportService.exportToCsv(List<Product>.from(products));
      }

      if (context.mounted) {
        Navigator.pop(context);
        final locationMessage = ExportService.getLocationMessage(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$format file $locationMessage\nPath: ${file.path}'),
            backgroundColor: AppColors.buttonSecondary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _deleteProduct(BuildContext context, String productId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A6F),
          title: const Text(
            'Delete Product',
            style: TextStyle(color: AppColors.whiteColor),
          ),
          content: Text(
            'Are you sure you want to delete "$name"?',
            style: const TextStyle(color: AppColors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).deleteProduct(productId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                        backgroundColor: AppColors.buttonSecondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: AppColors.buttonPrimary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Flutter CRUD',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: AppColors.whiteColor),
            onPressed: () => _showSortDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: AppColors.whiteColor),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.error != null &&
              productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${productProvider.error}',
                    style: const TextStyle(color: AppColors.whiteColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productProvider.refreshProducts(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: AppColors.whiteColor),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(color: AppColors.white54),
                    prefixIcon: const Icon(Icons.search, color: AppColors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.white70,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF2A4A6F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Product list
              Expanded(
                child: productProvider.products.isEmpty
                    ? Center(
                        child: productProvider.isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.buttonPrimary,
                              )
                            : const Text(
                                'No products found. Tap + to add one!',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 16,
                                ),
                              ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productProvider.refreshProducts(),
                        color: AppColors.buttonPrimary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              productProvider.products.length +
                              (productProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= productProvider.products.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.orange,
                                  ),
                                ),
                              );
                            }

                            final product = productProvider.products[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: AppColors.backgroundColor,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditScreen(productId: product.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                color: AppColors.whiteColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Price: \$${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppColors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Stock: ${product.stock}',
                                              style: const TextStyle(
                                                color: AppColors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.red,
                                        ),
                                        onPressed: () => _deleteProduct(
                                          context,
                                          product.id,
                                          product.name,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
        },
        backgroundColor: AppColors.whiteColor,
        child: const Icon(Icons.add, color: AppColors.whiteColor),
      ),
    );
  }
}
