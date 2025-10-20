// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ---------------- BASE URL ----------------
  static const String baseApiUrl = "http://127.0.0.1:8000/api/";
  // For Android Emulator: use "http://10.0.2.2:8000/api/";

  // ============================================================
  // ---------------- AUTHENTICATION ----------------------------
  // ============================================================

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
    if (email != null && email.isNotEmpty) body["email"] = email;

    final response = await http.post(
      Uri.parse("${baseApiUrl}employees/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      print("✅ Registered successfully: $username");
      return true;
    } else {
      print("❌ Register failed (${response.statusCode}): ${response.body}");
      return false;
    }
  }

  static Future<bool> registerDriver(
    String username,
    String password, {
    String? email,
  }) async {
    final body = {"username": username, "password": password};
    if (email != null && email.isNotEmpty) body["email"] = email;

    final response = await http.post(
      Uri.parse("${baseApiUrl}employees/register/driver/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      print("✅ Driver registered successfully: $username");
      return true;
    } else {
      print("❌ Driver register failed (${response.statusCode}): ${response.body}");
      return false;
    }
  }

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("${baseApiUrl}token/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("access", data["access"]);
      await prefs.setString("refresh", data["refresh"]);

      // Fetch user info
      final userResponse = await http.get(
        Uri.parse("${baseApiUrl}employees/me/"),
        headers: {"Authorization": "Bearer ${data["access"]}"},
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final role = (userData["role"] ?? "unknown").toString().toLowerCase();

        await prefs.setString("role", role);
        await prefs.setString("username", userData["username"] ?? "");
        await prefs.setString("restaurant_name", userData["restaurant_name"] ?? "");
        print("✅ Login success ($role) - ${userData["username"]}");
      } else {
        print("⚠️ Login succeeded but failed fetching user info");
      }
      return true;
    } else {
      print("❌ Login failed (${response.statusCode}): ${response.body}");
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
      print("🔄 Token refreshed successfully");
      return true;
    } else {
      print("❌ Token refresh failed (${response.statusCode}): ${response.body}");
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("✅ Logged out successfully");
      return true;
    } catch (e) {
      print("❌ Logout error: $e");
      return false;
    }
  }

  // ============================================================
  // ---------------- PASSWORD RESET ----------------------------
  // ============================================================

  static Future<bool> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse("${baseApiUrl}password-reset/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      print("✅ Password reset email sent to $email");
      return true;
    } else {
      print("❌ Password reset failed (${response.statusCode}): ${response.body}");
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
      print("✅ Password successfully reset!");
      return true;
    } else {
      print("❌ Password reset confirm failed: ${response.body}");
      return false;
    }
  }

  // ============================================================
  // ---------------- HELPERS -----------------------------------
  // ============================================================

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
      if (refreshed) response = await requestFn();
    }
    return response;
  }

  // ============================================================
  // ---------------- USER INFO ---------------------------------
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}employees/me/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ User info fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch user info (${response.statusCode})");
      return null;
    }
  }

   // ============================================================
  // ---------------- EMPLOYEES CRUD ----------------------------
  // ============================================================

  static Future<List<dynamic>> getEmployees() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}employees/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Employees fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to load employees: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  static Future<bool> addEmployee(String name, String position, String contact) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}employees/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
          "contact": contact,
        }),
      );
    });

    if (response.statusCode == 201) {
      print("✅ Employee added successfully");
      return true;
    } else {
      print("❌ Failed to add employee: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  static Future<bool> updateEmployee(int id, String name, String position, String contact) async {
    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}employees/$id/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
          "contact": contact,
        }),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Employee updated successfully");
      return true;
    } else {
      print("❌ Failed to update employee: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  static Future<bool> deleteEmployee(int id) async {
    final response = await _retryRequest(() async {
      return http.delete(
        Uri.parse("${baseApiUrl}employees/$id/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 204) {
      print("✅ Employee deleted successfully");
      return true;
    } else {
      print("❌ Failed to delete employee: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // ============================================================
  // ---------------- STAFF (SAME AS EMPLOYEES) -----------------
  // ============================================================

  static Future<List<dynamic>> getStaff() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}staff/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Staff list fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to load staff: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  static Future<bool> addStaff(String name, String position, String contact) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}staff/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
          "contact": contact,
        }),
      );
    });

    if (response.statusCode == 201) {
      print("✅ Staff added successfully");
      return true;
    } else {
      print("❌ Failed to add staff: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  static Future<bool> updateStaff(int id, String name, String position, String contact) async {
    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}staff/$id/"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "name": name,
          "position": position,
          "contact": contact,
        }),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Staff updated successfully");
      return true;
    } else {
      print("❌ Failed to update staff: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  static Future<bool> deleteStaff(int id) async {
    final response = await _retryRequest(() async {
      return http.delete(
        Uri.parse("${baseApiUrl}staff/$id/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 204) {
      print("✅ Staff deleted successfully");
      return true;
    } else {
      print("❌ Failed to delete staff: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // ============================================================
  // ---------------- DRIVER LOCATION ---------------------------
  // ============================================================

  static Future<void> updateDriverLocation(double lat, double lng) async {
    final response = await _retryRequest(() async {
      return http.patch(
        Uri.parse("${baseApiUrl}drivers/locations/me/"),
        headers: await _getHeaders(),
        body: jsonEncode({"latitude": lat, "longitude": lng}),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Driver location updated");
    } else {
      print("❌ Failed to update location: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> getDriverLocation(int driverId) async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}drivers/locations/$driverId/"),
        headers: await _getHeaders(),
      );
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch driver location: ${response.statusCode}");
      throw Exception("Driver location fetch failed");
    }
  }

  // ============================================================
  // ---------------- REWARDS -----------------------------------
  // ============================================================

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
      print("❌ Failed to fetch user points");
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
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  // ============================================================
  // ---------------- TRASH PICKUPS -----------------------------
  // ============================================================

  static Future<List<dynamic>> getTrashPickups() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}trash_pickups/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Trash pickups fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch pickups: ${response.statusCode}");
      return [];
    }
  }

  static Future<bool> addTrashPickup(Map<String, dynamic> body) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash_pickups/"),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });

    print(response.statusCode == 201
        ? "✅ Pickup added successfully"
        : "❌ Failed to add pickup: ${response.statusCode}");
    return response.statusCode == 201;
  }

  static Future<bool> updateTrashPickup(int id, Map<String, dynamic> body) async {
    final response = await _retryRequest(() async {
      return http.put(
        Uri.parse("${baseApiUrl}trash_pickups/$id/"),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });

    print(response.statusCode == 200
        ? "✅ Pickup updated"
        : "❌ Failed to update pickup: ${response.statusCode}");
    return response.statusCode == 200;
  }

  static Future<bool> deleteTrashPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.delete(
        Uri.parse("${baseApiUrl}trash_pickups/$id/"),
        headers: await _getHeaders(),
      );  
    });

    print(response.statusCode == 204
        ? "✅ Pickup deleted"
        : "❌ Failed to delete pickup: ${response.statusCode}");
    return response.statusCode == 204;
  }

  static Future<Map<String, dynamic>> cancelPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash_pickups/$id/cancel/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Pickup cancelled successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to cancel pickup: ${response.statusCode}");
      throw Exception("Failed to cancel pickup");
    }
  }
  
  // ============================================================
// ---------------- SINGLE PICKUP DETAILS ---------------------
// ============================================================

  /// Fetch a single pickup by its ID (used by WaitingForDriverScreen)
  static Future<Map<String, dynamic>?> getPickupById(int id) async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}trash_pickups/$id/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Pickup details fetched (ID: $id)");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch pickup details: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  // ============================================================
  // ---------------- PICKUP STATUS UPDATES ---------------------
  // ============================================================

  /// Start a pickup (mark as in_progress)
  static Future<Map<String, dynamic>> startPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash_pickups/$id/start/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Pickup started successfully (ID: $id)");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to start pickup: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to start pickup");
    }
  }

  /// Complete a pickup (mark as completed and award points)
    static Future<Map<String, dynamic>> completePickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}trash_pickups/$id/complete/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Pickup completed successfully (ID: $id)");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to complete pickup: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to complete pickup");
    }
  }

  

    // ============================================================
  // ---------------- DRIVER PICKUPS ----------------------------
  // ============================================================

  /// Fetch pickups assigned to the logged-in driver.
  /// If [includeHistory] is true, both completed and cancelled pickups are returned.
  static Future<List<dynamic>> getDriverPickups({bool includeHistory = false}) async {
    final response = await _retryRequest(() async {
      final uri = includeHistory
          ? Uri.parse("${baseApiUrl}drivers/pickups/?include_history=true")
          : Uri.parse("${baseApiUrl}drivers/pickups/");
      return http.get(uri, headers: await _getHeaders());
    });

    if (response.statusCode == 200) {
      print("✅ Driver pickups fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch driver pickups: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

    // ============================================================
  // ---------------- AVAILABLE PICKUPS -------------------------
  // ============================================================

  /// Fetch all pickups that are currently unassigned and available for drivers to claim.
  static Future<List<dynamic>> getAvailablePickups() async {
    final response = await _retryRequest(() async {
      return http.get(
        Uri.parse("${baseApiUrl}drivers/pickups/available/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Available pickups fetched successfully");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to fetch available pickups: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to fetch available pickups");
    }
  }

  /// Claim a specific pickup (assign it to the logged-in driver)
  static Future<Map<String, dynamic>> claimPickup(int id) async {
    final response = await _retryRequest(() async {
      return http.post(
        Uri.parse("${baseApiUrl}drivers/pickups/$id/claim/"),
        headers: await _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      print("✅ Pickup claimed successfully (ID: $id)");
      return jsonDecode(response.body);
    } else {
      print("❌ Failed to claim pickup: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to claim pickup");
    }
  }


}

