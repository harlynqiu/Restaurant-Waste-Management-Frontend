// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base API URL
  static const String baseApiUrl = "http://127.0.0.1:8000/api/";
  // For Android Emulator: use -> "http://10.0.2.2:8000/api/";

  // ---------------- AUTH ----------------

  static Future<bool> register(
    String username,
    String password, {
    String? email,
    required String restaurantName,
  }) async {
    final body = {
      "username": username,
      "password": password,
      "restaurant_name": restaurantName,
    };

    if (email != null && email.isNotEmpty) {
      body["email"] = email;
    }

    final response = await http.post(
      Uri.parse("${baseApiUrl}employees/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      print("Register failed: ${response.statusCode} -> ${response.body}");
    }

    return response.statusCode == 201;
  }

  static Future<bool> registerDriver(
    String username,
    String password, {
    String? email,
  }) async {
    final body = {
      "username": username,
      "password": password,
    };

    if (email != null && email.isNotEmpty) {
      body["email"] = email;
    }

    final response = await http.post(
      Uri.parse("${baseApiUrl}employees/register/driver/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      print("Driver register failed: ${response.statusCode} -> ${response.body}");
    }

    return response.statusCode == 201;
  }

  // ---------------- LOGIN / TOKENS ----------------

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("${baseApiUrl}token/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("access", data["access"]);
      await prefs.setString("refresh", data["refresh"]);

      // ✅ Store restaurant name (returned by backend)
      if (data["restaurant_name"] != null) {
        await prefs.setString("restaurant_name", data["restaurant_name"]);
      }

      // Optional: store username & email for convenience
      await prefs.setString("username", data["username"] ?? "");
      await prefs.setString("email", data["email"] ?? "");

      return true;
    } else {
      print("Login failed: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString("refresh");

    if (refresh == null) return false;

    final response = await http.post(
      Uri.parse("${baseApiUrl}token/refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString("access", data["access"]);
      return true;
    } else {
      print("Refresh token failed: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("access");
      await prefs.remove("refresh");
      await prefs.remove("restaurant_name");
      await prefs.remove("username");
      await prefs.remove("email");
      return true;
    } catch (e) {
      print("Logout error: $e");
      return false;
    }
  }

  // ---------------- PASSWORD RESET ----------------

  static Future<bool> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse("${baseApiUrl}password-reset/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Password reset failed: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }

  static Future<bool> confirmResetPassword(
      String uid, String token, String newPassword) async {
    final response = await http.post(
      Uri.parse("${baseApiUrl}password-reset/confirm/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uid": uid,
        "token": token,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Password reset confirm failed: ${response.statusCode} -> ${response.body}");
      return false;
    }
  }

  // ---------------- HELPERS ----------------

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> _retryRequest(
      Future<http.Response> Function() requestFn) async {
    var response = await requestFn();

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await requestFn();
      }
    }

    return response;
  }

  // ---------------- USER INFO ----------------

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRestaurant = prefs.getString("restaurant_name");
    final storedUsername = prefs.getString("username");
    final storedEmail = prefs.getString("email");

    if (storedUsername != null && storedRestaurant != null) {
      // ✅ Return locally stored info if available
      return {
        "username": storedUsername,
        "email": storedEmail ?? "",
        "restaurant_name": storedRestaurant,
      };
    }

    // Otherwise fetch from API (optional fallback)
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}employees/me/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return {
          "username": data["username"] ?? "",
          "email": data["email"] ?? "",
          "restaurant_name": data["restaurant_name"] ?? "",
        };
      }
      return null;
    } else {
      print("Failed to fetch current user: ${response.statusCode} -> ${response.body}");
      return null;
    }
  }

  // ---------------- EMPLOYEES ----------------

  static Future<List<dynamic>> getEmployees() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}employees/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employees (${response.statusCode})");
    }
  }

  static Future<bool> addEmployee(String name, String position) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}employees/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
        }),
      );
    });

    return response.statusCode == 201;
  }

  static Future<bool> updateEmployee(int id, String name, String position) async {
    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}employees/$id/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
        }),
      );
    });

    return response.statusCode == 200 || response.statusCode == 202;
  }

  static Future<bool> deleteEmployee(int id) async {
    final response = await _retryRequest(() async {
      return http.delete(
        Uri.parse("${baseApiUrl}employees/$id/"),
        headers: await _getHeaders(),
      );
    });

    return response.statusCode == 204;
  }

  // ---------------- TRASH PICKUPS ----------------

  static Future<List<dynamic>> getTrashPickups() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}trash-pickups/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load trash pickups (${response.statusCode})");
    }
  }

  static Future<Map<String, dynamic>> addTrashPickup(
    DateTime scheduledDate,
    double trashWeight,
    String address, {
    required String wasteType,
  }) async {
    final body = {
      "scheduled_date": scheduledDate.toIso8601String(),
      "trash_weight": trashWeight,
      "address": address,
      "waste_type": wasteType,
    };

    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash-pickups/"),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        "success": true,
        "data": data,
        "message": data["message"] ?? "Pickup created successfully",
        "points": data["points"] ?? 0,
        "driver": data["driver_username"] ?? "Unassigned",
      };
    } else {
      print("Add trash pickup failed: ${response.statusCode} -> ${response.body}");
      return {
        "success": false,
        "data": null,
        "message": "Failed to create pickup",
        "points": 0,
        "driver": "Unassigned",
      };
    }
  }

  static Future<bool> updateTrashPickup(
    int id,
    DateTime scheduledDate,
    double trashWeight,
    String address, {
    required String wasteType,
  }) async {
    final body = {
      "scheduled_date": scheduledDate.toIso8601String(),
      "trash_weight": trashWeight,
      "address": address,
      "waste_type": wasteType,
    };

    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}trash-pickups/$id/"),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });

    return response.statusCode == 200 || response.statusCode == 202;
  }

  static Future<bool> deleteTrashPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.delete(
        Uri.parse("${baseApiUrl}trash-pickups/$id/"),
        headers: await _getHeaders(),
      );
    });

    return response.statusCode == 204;
  }

  // ---------------- DRIVER ENDPOINTS ----------------

  static Future<List<dynamic>> getDriverPickups({bool includeHistory = false}) async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}trash-pickups/assigned/?include_history=${includeHistory ? 1 : 0}"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load driver pickups (${response.statusCode})");
    }
  }

  static Future<List<dynamic>> getAvailablePickups() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}trash-pickups/available/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load available pickups (${response.statusCode})");
    }
  }

  static Future<Map<String, dynamic>> claimPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash-pickups/$id/claim/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to claim pickup (${response.statusCode}) -> ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> startPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash-pickups/$id/start/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to start pickup (${response.statusCode}) -> ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> completePickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash-pickups/$id/complete/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to complete pickup (${response.statusCode}) -> ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> cancelPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash-pickups/$id/cancel/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to cancel pickup (${response.statusCode}) -> ${response.body}");
    }
  }

  // ---------------- DRIVER PROFILE ----------------

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}employees/driver/profile/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to load driver profile: ${response.statusCode} -> ${response.body}");
      return null;
    }
  }

  static Future<bool> updateDriverProfile(Map<String, dynamic> profileData) async {
    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}employees/driver/profile/"),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      );
    });

    return response.statusCode == 200;
  }

  // ---------------- REWARDS ----------------

  static Future<int> getUserPoints() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}rewards/points/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["points"] ?? 0;
    } else {
      return 0;
    }
  }

  static Future<List<dynamic>> getUserTransactions() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}rewards/transactions/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
}
