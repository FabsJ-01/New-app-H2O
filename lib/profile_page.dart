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
            const SnackBar(
              content: Text("Profile picture updated and overwritten! 🎉"),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // IMAGE CROPPING HELPER FUNCTION
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square Crop
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Colors.blue[900],
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // Naka-lock sa 1:1 ratio
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

    // 1. I-crop muna ang napiling larawan
    File? croppedFile = await _cropImage(File(pickedFile.path));
    
    // Kung kina-cancel ng user ang pag-crop, wag ituloy ang upload
    if (croppedFile == null) return;

    // 2. I-upload ang na-crop na larawan sa Cloudinary
    await _uploadDirectToCloudinary(croppedFile);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Change Profile Picture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[50],
            child: Icon(icon, color: Colors.blue[900], size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: cloudImageUrl != null && cloudImageUrl!.isNotEmpty
                                ? Image.network(
                                    cloudImageUrl!,
                                    key: ValueKey(cloudImageUrl),
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 65,
                                        color: Colors.grey,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        if (isUploadingImage)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: isUploadingImage ? null : _showImageSourceOptions,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue[900],
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "PSU ID: $psuId",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${user?.email}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      userRole.toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 10),
                  if (userRole == "Student" && userCourse != "N/A") ...[
                    _buildProfileInfoRow(Icons.school, "Course", userCourse),
                    const SizedBox(height: 15),
                    _buildProfileInfoRow(
                      Icons.layers,
                      "Year Level",
                      userYear,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileInfoRow(
                      Icons.class_,
                      "Section",
                      userSection,
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                      child: const Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                      child: Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[800], size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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