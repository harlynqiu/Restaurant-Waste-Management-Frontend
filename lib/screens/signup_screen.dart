// lib/screens/signup_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  List<dynamic> _searchResults = [];

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 Get current location safely
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please enable location services on your device.")));
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Location permission denied. Please enable it.")));
        return;
      }

      Position pos =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
      });

      await _updateAddressFromLatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // 🌍 Reverse-geocode coordinates → address
  Future<void> _updateAddressFromLatLng(double lat, double lng) async {
    try {
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng";
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "DARWCOSApp/1.0 (support@darwcos.com)" // required by OSM
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data["display_name"] ?? "Unknown location";
        setState(() {
          _addressController.text = displayName;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
  }

  // 🔍 Search address via OSM
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    try {
      final url =
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5";
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "DARWCOSApp/1.0 (support@darwcos.com)"
      });
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  // 🗺️ Map picker modal
  Future<void> _openMapPicker() async {
    if (_selectedLocation == null) {
      await _getCurrentLocation();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        LatLng tempLocation = _selectedLocation!;
        TextEditingController searchCtrl =
            TextEditingController(text: _addressController.text);

        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 10),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: const Icon(Icons.search, color: darwcosGreen),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setModalState(() {
                            _searchResults.clear();
                            searchCtrl.clear();
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (query) async {
                      await _searchAddress(query);
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Search Results
                if (_searchResults.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, i) {
                        final r = _searchResults[i];
                        return ListTile(
                          leading: const Icon(Icons.place, color: darwcosGreen),
                          title: Text(
                            r["display_name"] ?? "",
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            final lat = double.parse(r["lat"].toString());
                            final lon = double.parse(r["lon"].toString());
                            setModalState(() {
                              tempLocation = LatLng(lat, lon);
                              _mapController.move(tempLocation, 16);
                              _searchResults.clear();
                            });
                          },
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    flex: 3,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: tempLocation,
                        initialZoom: 16,
                        onTap: (tapPosition, point) {
                          setModalState(() {
                            tempLocation = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.darwcos.app', // ✅ polite header per OSM rules
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: tempLocation,
                              width: 60,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_pin,
                                color: darwcosGreen,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Confirm Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darwcosGreen,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedLocation = tempLocation;
                      });
                      _updateAddressFromLatLng(
                        tempLocation.latitude,
                        tempLocation.longitude,
                      );
                    },
                    label: const Text(
                      "Confirm Location",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🧾 Registration
  Future<void> _register() async {
    if (_restaurantController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter restaurant name and confirm address.")));
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please set your restaurant location.")));
      return;
    }

    setState(() => _isLoading = true);

    bool success = await ApiService.register(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      restaurantName: _restaurantController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Registration successful! Please login.")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DARWCOS",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Register Your Restaurant",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField("Full Name / Username", _usernameController,
                        Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(
                        "Email (optional)", _emailController, Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField("Password", _passwordController, Icons.lock,
                        obscure: true),
                    const SizedBox(height: 16),
                    _buildTextField("Restaurant Name", _restaurantController,
                        Icons.store),
                    const SizedBox(height: 16),

                    // Address field
                    TextField(
                      controller: _addressController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Restaurant Address",
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: darwcosGreen),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.push_pin,
                              color: darwcosGreen, size: 26),
                          onPressed: _openMapPicker,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: darwcosGreen)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _register,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an Account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: darwcosGreen),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darwcosGreen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for consistent fields
  Widget _buildTextField(String label, TextEditingController controller,
      IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darwcosGreen),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
