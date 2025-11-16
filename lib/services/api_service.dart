import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';

class ApiService {
  // Get base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web (browser)
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Android physical device
      return 'http://192.168.127.186:3000';
    } else if (Platform.isIOS) {
      // iOS Simulator
      return 'http://127.0.0.1:3000';
    } else {
      // Windows
      return 'http://localhost:3000';
    }
  }

  // Health check
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get all products
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<dynamic> productsList;
        if (responseData is Map && responseData.containsKey('data')) {
          productsList = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          productsList = responseData;
        } else {
          throw Exception('Unexpected response format');
        }

        return productsList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get product by ID
  static Future<Product> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products?id=$id'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        Map<String, dynamic> productData;
        if (responseData is Map && responseData.containsKey('data')) {
          productData = Map<String, dynamic>.from(responseData['data'] as Map);
        } else if (responseData is Map) {
          productData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('Unexpected response format');
        }

        return Product.fromJson(productData);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Create product
  static Future<Product> createProduct(
    String name,
    double price,
    int stock,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productName': name,
          'price': price,
          'stock': stock,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle wrapped response: { success, message, data: {...} }
        Map<String, dynamic> productData;
        if (responseData is Map && responseData.containsKey('data')) {
          productData = Map<String, dynamic>.from(responseData['data'] as Map);
        } else if (responseData is Map) {
          productData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('Unexpected response format');
        }

        return Product.fromJson(productData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to create product: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  // Update product
  static Future<Product> updateProduct(
    String id,
    String? name,
    double? price,
    int? stock,
  ) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['productName'] = name;
      if (price != null) body['price'] = price;
      if (stock != null) body['stock'] = stock;

      final response = await http.put(
        Uri.parse('$baseUrl/products?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        Map<String, dynamic> productData;
        if (responseData is Map && responseData.containsKey('data')) {
          productData = Map<String, dynamic>.from(responseData['data'] as Map);
        } else if (responseData is Map) {
          productData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception('Unexpected response format');
        }

        return Product.fromJson(productData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to update product: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  static Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products?id=$id'));
      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to delete product: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }
}
