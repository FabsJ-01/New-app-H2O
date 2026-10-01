import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:crypto/crypto.dart';

import 'change_password_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();

  // CLOUDINARY CONFIGURATION
  final String _cloudName = "rtjw8uhb";
  final String _uploadPreset = "h2o_images_user";

  final String _apiKey = "167467569169441";
  final String _apiSecret = "epkfJWd2oCExcBs3nobqjeuuVxI";

  String userRole = "";
  String userCourse = "";
  String userYear = "";
  String userSection = "";
  String userGender = "";
  String? cloudImageUrl;
  bool isLoading = true;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndSetupImage();
  }

  Map<String, String> _generateSignedParams(String publicId) {
    final String timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final Map<String, String> paramsToSign = {
      "public_id": publicId,
      "timestamp": timestamp,
      "upload_preset": _uploadPreset,
    };

    final List<String> sortedKeys = paramsToSign.keys.toList()..sort();
    final String paramString = sortedKeys.map((key) => "$key=${paramsToSign[key]}").join("&");
    final String stringToSign = "$paramString$_apiSecret";

    final List<int> bytes = utf8.encode(stringToSign);
    final Digest digest = sha1.convert(bytes);

    final String signature = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return {
      ...paramsToSign,
      "signature": signature,
      "api_key": _apiKey,
    };
  }

  Future<void> _fetchUserDataAndSetupImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _dbRef.child('users').child(user.uid).get();

        if (snapshot.exists && snapshot.value != null) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          if (mounted) {
            setState(() {
              userRole = data['role']?.toString() ?? 'Student';
              userCourse = data['course']?.toString() ?? 'N/A';
              userYear = data['year']?.toString() ?? 'N/A';
              userSection = data['section']?.toString() ?? 'N/A';
              userGender = data['gender']?.toString() ?? 'N/A';
              cloudImageUrl = data['profileImageUrl']?.toString();
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching profile data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _uploadDirectToCloudinary(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isUploadingImage = true);

    String psuId = user.email?.split('@')[0] ?? user.uid;
    final String targetPublicId = "user_profiles/$psuId";
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    try {
      final Map<String, String> signedParams = _generateSignedParams(targetPublicId);

      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      request.fields.addAll(signedParams);

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        final String newSecureUrl = jsonMap['secure_url'];

        final String updatedUrl = "$newSecureUrl?v=${DateTime.now().millisecondsSinceEpoch}";

        await _dbRef.child('users').child(user.uid).update({
          'profileImageUrl': updatedUrl,
        });

        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (mounted) {
          setState(() {
            cloudImageUrl = updatedUrl;
            isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile picture updated successfully! 🎉"),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception("Cloudinary error ${response.statusCode}: $errorBody");
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      if (mounted) {
        setState(() => isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload image: $e"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Colors.blue[900],
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    File? croppedFile = await _cropImage(File(pickedFile.path));
    if (croppedFile == null) return;

    await _uploadDirectToCloudinary(croppedFile);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Change Profile Picture",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade100, width: 1.5),
            ),
            child: Icon(icon, color: Colors.blue.shade800, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    String psuId = "Guest";
    if (user?.email != null) {
      psuId = user!.email!.split('@')[0];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.blue.shade700],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.blue.shade800),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Header Profile Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar Stack with Camera Button
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.shade100.withOpacity(0.6),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 54,
                                      backgroundColor: Colors.blue.shade50,
                                      child: ClipOval(
                                        child: cloudImageUrl != null && cloudImageUrl!.isNotEmpty
                                            ? Image.network(
                                                cloudImageUrl!,
                                                key: ValueKey(cloudImageUrl),
                                                width: 108,
                                                height: 108,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 65,
                                                    color: Colors.blue.shade300,
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.blue.shade800,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 65,
                                                color: Colors.blue.shade300,
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: isUploadingImage ? null : _showImageSourceOptions,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade900,
                                              Colors.blue.shade600,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "PSU ID: $psuId",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${user?.email}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  userRole.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Information Details Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Personal Details",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildProfileInfoRow(Icons.wc_rounded, "Gender", userGender),

                              if (userRole == "Student" && userCourse != "N/A") ...[
                                const Divider(height: 24),
                                _buildProfileInfoRow(Icons.school_rounded, "Course", userCourse),
                                const Divider(height: 24),
                                _buildProfileInfoRow(Icons.layers_rounded, "Year Level", userYear),
                                const Divider(height: 24),
                                _buildProfileInfoRow(Icons.class_rounded, "Section", userSection),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Change Password Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade900,
                                  Colors.blue.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade300.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordPage(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Change Password",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade400, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: Colors.red.shade50.withOpacity(0.3),
                            ),
                            onPressed: () async {
                              await _auth.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Logout",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade800, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}