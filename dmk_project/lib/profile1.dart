import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:dmk_project/api_config.dart';
import 'package:dmk_project/home.dart';
import 'package:dmk_project/app_theme.dart';
import 'package:dmk_project/password_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;
  final String? phone;
  final String? password;
  final bool isNewUser;

  const EditProfilePage({
    super.key,
    required this.userId,
    this.phone,
    this.password,
    this.isNewUser = false,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  String? _selectedConstituency;

  final List<String> _constituencies = [
    "Gummidipoondi",
    "Ponneri",
    "Tiruttani",
    "Tiruvallur",
    "Poonamallee",
    "Avadi",
    "Maduravoyal",
    "Ambattur",
    "Madavaram",
    "Thiruvottiyur",
    "Dr. Radhakrishnan Nagar",
    "Perambur",
    "Kolathur",
    "Villivakkam",
    "Thiru-Vi-Ka-Nagar",
    "Egmore",
    "Royapuram",
    "Harbour",
    "Chepauk-Thiruvallikeni",
    "Thousand Lights",
    "Anna Nagar",
    "Virugampakkam",
    "Saidapet",
    "T. Nagar",
    "Mylapore",
    "Velachery",
    "Sholinganallur",
    "Alandur",
    "Sriperumbudur",
    "Pallavaram",
    "Tambaram",
    "Chengalpattu",
    "Thiruporur",
    "Cheyyur",
    "Madurantakam",
    "Uthiramerur",
    "Kancheepuram",
    "Arakkonam",
    "Sholingur",
    "Katpadi",
    "Ranipet",
    "Arcot",
    "Vellore",
    "Anaikattu",
    "K. V. Kuppam",
    "Gudiyattam",
    "Vaniyambadi",
    "Ambur",
    "Jolarpet",
    "Tirupattur",
    "Uthangarai",
    "Bargur",
    "Krishnagiri",
    "Veppanahalli",
    "Hosur",
    "Thalli",
    "Palacode",
    "Pennagaram",
    "Dharmapuri",
    "Pappireddippatti",
    "Harur",
    "Chengam",
    "Tiruvannamalai",
    "Kilpennathur",
    "Kalasapakkam",
    "Polur",
    "Arani",
    "Cheyyar",
    "Vandavasi",
    "Gingee",
    "Mailam",
    "Tindivanam",
    "Vanur",
    "Villupuram",
    "Vikravandi",
    "Tirukoilur",
    "Ulundurpettai",
    "Rishivandiyam",
    "Sankarapuram",
    "Kallakurichi",
    "Gangavalli",
    "Attur",
    "Yercaud",
    "Omalur",
    "Mettur",
    "Edappadi",
    "Sankagiri",
    "Salem West",
    "Salem North",
    "Salem South",
    "Veerapandi",
    "Rasipuram",
    "Senthamangalam",
    "Namakkal",
    "Paramathi Velur",
    "Tiruchengode",
    "Kumarapalayam",
    "Erode East",
    "Erode West",
    "Modakurichi",
    "Perundurai",
    "Bhavani",
    "Anthiyur",
    "Gobichettipalayam",
    "Bhavanisagar",
    "Dharapuram",
    "Kangeyam",
    "Avinashi",
    "Tiruppur North",
    "Tiruppur South",
    "Palladam",
    "Udumalpet",
    "Madathukulam",
    "Udhagamandalam",
    "Gudalur",
    "Coonoor",
    "Mettuppalayam",
    "Sulur",
    "Kavundampalayam",
    "Coimbatore North",
    "Thondamuthur",
    "Coimbatore South",
    "Singanallur",
    "Kinathukadavu",
    "Pollachi",
    "Valparai",
    "Palani",
    "Oddanchatram",
    "Athoor",
    "Nilakkottai",
    "Natham",
    "Dindigul",
    "Vedasandur",
    "Aravakurichi",
    "Karur",
    "Krishnarayapuram",
    "Kulithalai",
    "Manapparai",
    "Srirangam",
    "Tiruchirappalli West",
    "Tiruchirappalli East",
    "Thiruverumbur",
    "Lalgudi",
    "Mannachanallur",
    "Musiri",
    "Thuraiyur",
    "Perambalur",
    "Kunnam",
    "Ariyalur",
    "Jayankondam",
    "Chidambaram",
    "Kattumannarkoil",
    "Cuddalore",
    "Panruti",
    "Kurinjipadi",
    "Bhuvanagiri",
    "Neyveli",
    "Vridhachalam",
    "Tittakudi",
    "Sirkazhi",
    "Mayiladuthurai",
    "Poompuhar",
    "Nagapattinam",
    "Kilvelur",
    "Vedaranyam",
    "Thiruthuraipoondi",
    "Mannargudi",
    "Thiruvarur",
    "Nannilam",
    "Thiruvidaimarudur",
    "Kumbakonam",
    "Papanasam",
    "Thiruvaiyaru",
    "Thanjavur",
    "Orathanadu",
    "Pattukkottai",
    "Peravurani",
    "Gandharvakottai",
    "Viralimalai",
    "Pudukkottai",
    "Thirumayam",
    "Alangudi",
    "Aranthangi",
    "Karaikudi",
    "Tiruppattur (Sivaganga)",
    "Sivaganga",
    "Manamadurai",
    "Melur",
    "Madurai East",
    "Madurai North",
    "Madurai Central",
    "Madurai West",
    "Madurai South",
    "Thirupparankundram",
    "Thirumangalam",
    "Usilampatti",
    "Andipatti",
    "Periyakulam",
    "Bodinayakanur",
    "Cumbum",
    "Theni",
    "Rajapalayam",
    "Srivilliputhur",
    "Sattur",
    "Sivakasi",
    "Virudhunagar",
    "Aruppukkottai",
    "Tiruchuli",
    "Paramakudi",
    "Tiruvadanai",
    "Ramanathapuram",
    "Mudukulathur",
    "Vilathikulam",
    "Thoothukkudi",
    "Tiruchendur",
    "Srivaikuntam",
    "Ottapidaram",
    "Kovilpatti",
    "Sankarankovil",
    "Vasudevanallur",
    "Kadayanallur",
    "Tenkasi",
    "Alangulam",
    "Tirunelveli",
    "Ambasamudram",
    "Palayamkottai",
    "Nanguneri",
    "Radhapuram",
    "Kanniyakumari",
    "Nagercoil",
    "Colachel",
    "Padmanabhapuram",
    "Vilavancode",
    "Killiyoor",
  ];

  File? _image;
  String? _networkImageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _constituencies.sort(); // 🔥 Ensure alphabetical order
    print("🔍 DEBUG: EditProfilePage init with userId: ${widget.userId}");
    _loadLocalProfile(); // 🔥 Load local data first for speed
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text =
          prefs.getString("username") ?? _nameController.text;
      _emailController.text =
          prefs.getString("user_email") ?? _emailController.text;
      _mobileController.text =
          prefs.getString("user_mobile") ?? widget.userId;
      String? localConst = prefs.getString("user_constituency");
      if (localConst != null && _constituencies.contains(localConst)) {
        _selectedConstituency = localConst;
      }
      _networkImageUrl = prefs.getString("profile_image_url");
    });
  }

  Future<void> _saveLocally(
    String username,
    File? imageFile,
    String? imageUrl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Save username and constituency
    prefs.setString("username", username);
    if (_selectedConstituency != null) {
      prefs.setString("user_constituency", _selectedConstituency!);
    }

    // Save local image path if user picked new image
    if (imageFile != null) {
      prefs.setString("profile_image_path", imageFile.path);
      prefs.remove("profile_image_url"); // remove old URL
    } else if (imageUrl != null) {
      prefs.setString("profile_image_url", imageUrl);
      prefs.remove("profile_image_path"); // remove old local path
    }
  }

  // ===============================
  // IMAGE PICKER
  // ===============================
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _image = File(picked.path));

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Image selected! Click Save to update.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFB11226),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ===============================
  // UI
  // ===============================
  Future<void> _saveProfile() async {
    final String username = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String constituency = _selectedConstituency ?? "";

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name must be at least 3 characters")),
      );
      return;
    }
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email address")),
      );
      return;
    }
    if (constituency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your constituency")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (widget.isNewUser) {
        final uri = Uri.parse("${ApiConfig.apiBaseUrl}/auth/register");
        var request = http.MultipartRequest("POST", uri);

        request.fields["mobileNumber"] = widget.phone ?? "";
        request.fields["password"] = widget.password ?? "";
        request.fields["username"] = username;
        request.fields["email"] = email;
        request.fields["constituency"] = constituency;

        if (_image != null) {
          final mimeType = lookupMimeType(_image!.path);
          final mimeSplit = mimeType?.split('/') ?? ['image', 'jpeg'];
          request.files.add(
            await http.MultipartFile.fromPath(
              "profile_image",
              _image!.path,
              contentType: MediaType(mimeSplit[0], mimeSplit[1]),
            ),
          );
        }

        var streamedResponse = await request.send().timeout(const Duration(seconds: 90));
        var response = await http.Response.fromStream(streamedResponse);

        if (!mounted) return;

        if (response.statusCode == 201 || response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true) {
            final data = decoded['data'];
            
            await prefs.setString("token", data["token"] ?? "");
            await prefs.setString("user_id", data["user_id"]?.toString() ?? "");
            await prefs.setString("user_mobile", data["user_mobile"] ?? "");
            await prefs.setString("username", data["username"] ?? "");
            await prefs.setString("user_email", data["email"] ?? "");
            await prefs.setString("user_constituency", data["constituency"] ?? "");
            if (data["profile_image"] != null) {
              await prefs.setString("profile_image_url", "${ApiConfig.baseUrl}/uploads/profile_images/${data["profile_image"]}");
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registered successfully!")),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
            return;
          }
        }
        
        final errorMsg = jsonDecode(response.body)["message"] ?? "Registration failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $errorMsg"), backgroundColor: Colors.red),
        );
      } else {
        final token = prefs.getString("token") ?? "";
        final uri = Uri.parse("${ApiConfig.apiBaseUrl}/profile/update");
        var request = http.MultipartRequest("POST", uri);

        request.headers["Authorization"] = "Bearer $token";
        request.fields["username"] = username;
        request.fields["email"] = email;
        request.fields["constituency"] = constituency;

        if (_image != null) {
          final mimeType = lookupMimeType(_image!.path);
          final mimeSplit = mimeType?.split('/') ?? ['image', 'jpeg'];
          request.files.add(
            await http.MultipartFile.fromPath(
              "profile_image",
              _image!.path,
              contentType: MediaType(mimeSplit[0], mimeSplit[1]),
            ),
          );
        }

        var streamedResponse = await request.send().timeout(const Duration(seconds: 90));
        var response = await http.Response.fromStream(streamedResponse);

        if (!mounted) return;

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true) {
            final data = decoded['data'];

            await prefs.setString("username", data["Username"] ?? username);
            await prefs.setString("user_email", data["Email"] ?? email);
            await prefs.setString("user_constituency", data["Constituency"] ?? constituency);
            if (data["ProfileImage"] != null) {
              await prefs.setString("profile_image_url", "${ApiConfig.baseUrl}/uploads/profile_images/${data["ProfileImage"]}");
              await prefs.remove("profile_image_path");
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile updated successfully!")),
            );
            Navigator.pop(context);
            return;
          }
        }

        final errorMsg = jsonDecode(response.body)["message"] ?? "Update failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $errorMsg"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            if (widget.isNewUser) {
              // If it's a new user, they haven't registered yet. Just go back to login.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PasswordLoginPage()),
                (route) => false,
              );
              return;
            }

            final prefs = await SharedPreferences.getInstance();
            if (prefs.getString("temp_token") != null) {
              await prefs.remove("temp_token");
              await prefs.remove("user_id");
              await prefs.remove("user_mobile");
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PasswordLoginPage()),
                  (route) => false,
                );
              }
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      /// Profile Avatar Section
                      Center(child: _buildProfessionalAvatar()),

                      SizedBox(height: screenHeight * 0.04),

                      /// Input Fields Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: appCardDecoration(radius: AppRadius.lg),
                        child: Column(
                          children: [
                            _buildProfessionalInput(
                              'Full Name *',
                              _nameController,
                            ),
                            const SizedBox(height: 16),
                            _buildProfessionalInput(
                              'Mobile Number *',
                              _mobileController,
                              readOnly: true,
                            ),
                            const SizedBox(height: 16),
                            _buildProfessionalInput(
                              'Email *',
                              _emailController,
                            ),
                            const SizedBox(height: 16),
                            _buildConstituencyDropdown(),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      /// Save Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB11226).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _saveProfile,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFB11226),
                                    Color(0xFF8A0C20),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white.withOpacity(0.9),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontFamily: 'Roboto',
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Professional Avatar with Enhanced Styling
  Widget _buildProfessionalAvatar() {
    ImageProvider provider;

    if (_image != null) {
      provider = FileImage(_image!);
    } else if (_networkImageUrl != null) {
      provider = NetworkImage(_networkImageUrl!);
    } else {
      provider = const NetworkImage('https://i.stack.imgur.com/l60Hf.png');
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB11226).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: provider,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showImagePickerOptions,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.4),
              highlightColor: Colors.white.withOpacity(0.2),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB11226), Color(0xFF8A0C20)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB11226).withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Professional Constituency Dropdown
  Widget _buildConstituencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Constituency *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Roboto',
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 1.3,
            ),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedConstituency,
              hint: Text(
                'Select Constituency',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                  color: Colors.grey.shade400,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
                color: Colors.black87,
              ),
              items: _constituencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) async {
                if (newValue != null) {
                  setState(() {
                    _selectedConstituency = newValue;
                  });
                  // 🔥 Save immediately to local storage so it's "sticky" even without explicit Save
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString("user_constituency", newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Professional Input Field
  Widget _buildProfessionalInput(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: 'Roboto',
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: readOnly
                  ? Colors.grey.shade300
                  : const Color(0xFF2196F3).withOpacity(0.3),
              width: 1.3,
            ),
            color: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
                color: Colors.grey.shade400,
              ),
              suffixIcon: readOnly
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Show Image Picker Options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text(
                'Gallery',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text(
                'Camera',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
