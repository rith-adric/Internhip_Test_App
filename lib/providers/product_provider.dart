import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum SortOption { none, priceAsc, priceDesc, stockAsc, stockDesc }

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.none;
  int _currentPage = 1;
  final int _pageSize = 10;

  List<Product> get products {
    // Client-side pagination
    final startIndex = 0;
    final endIndex = (_currentPage * _pageSize).clamp(
      0,
      _filteredProducts.length,
    );
    return _filteredProducts.sublist(startIndex, endIndex);
  }

  List<Product> get allFilteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => (_currentPage * _pageSize) < _filteredProducts.length;
  SortOption get sortOption => _sortOption;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    // Don't block initial load or refresh
    if (_isLoading && !refresh && _products.isNotEmpty) return;
    if (!hasMore && !refresh && _products.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (refresh || _products.isEmpty) {
        final fetchedProducts = await ApiService.getAllProducts();
        _products = fetchedProducts;
        _applyFilters();
      } else {
        // Load more for pagination
        _currentPage++;
        _applyFilters(); // Reapply filters to show more items
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  void _applyFilters() {
    _filteredProducts = List.from(_products);
    _currentPage = 1; // Reset pagination when filters change

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.priceAsc:
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.stockAsc:
        _filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case SortOption.stockDesc:
        _filteredProducts.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case SortOption.none:
        break;
    }

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
  }

  Future<void> addProduct(String name, double price, int stock) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await ApiService.createProduct(name, price, stock);
      _products.insert(0, product);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(
    String id,
    String? name,
    double? price,
    int? stock,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProduct = await ApiService.updateProduct(
        id,
        name,
        price,
        stock,
      );
      final index = _products.indexWhere((product) => product.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _applyFilters();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Product> fetchProductById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await ApiService.getProductById(id);
      _error = null;
      return product;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
