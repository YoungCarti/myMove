import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _VehicleEditState {
  final TextEditingController makeController;
  final TextEditingController plateController;
  bool isPrimary;

  _VehicleEditState({
    required String make,
    required String plate,
    this.isPrimary = false,
  })  : makeController = TextEditingController(text: make),
        plateController = TextEditingController(text: plate);

  void dispose() {
    makeController.dispose();
    plateController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'make': makeController.text.trim(),
      'plate': plateController.text.trim(),
      'isPrimary': isPrimary,
    };
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  final List<_VehicleEditState> _vehicles = [];

  late String _initialName;
  late String _initialBio;
  late String _initialVehiclesJson;

  bool _isSaving = false;
  bool _hasChanges = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    _initialName = authProvider.displayName;
    _initialBio = authProvider.bio;

    _nameController = TextEditingController(text: _initialName);
    _bioController = TextEditingController(text: _initialBio);

    final authVehicles = authProvider.vehicles;
    if (authVehicles.isEmpty) {
      _vehicles.add(_VehicleEditState(make: '', plate: '', isPrimary: true));
    } else {
      for (var v in authVehicles) {
        _vehicles.add(_VehicleEditState(
          make: v['make'] ?? '',
          plate: v['plate'] ?? '',
          isPrimary: v['isPrimary'] == true,
        ));
      }
    }
    _initialVehiclesJson = jsonEncode(_vehicles.map((e) => e.toMap()).toList());

    _nameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
    for (var v in _vehicles) {
      v.makeController.addListener(_checkForChanges);
      v.plateController.addListener(_checkForChanges);
    }
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != _initialName ||
        _bioController.text != _initialBio ||
        jsonEncode(_vehicles.map((e) => e.toMap()).toList()) != _initialVehiclesJson ||
        _pickedImage != null;

    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      _checkForChanges();
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _bioController.removeListener(_checkForChanges);

    _nameController.dispose();
    _bioController.dispose();
    for (var v in _vehicles) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        vehicles: _vehicles.map((v) => v.toMap()).toList(),
        profileImage: _pickedImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFFF453A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profilePic = authProvider.profileImageUrl;
    final userName = authProvider.displayName.isNotEmpty ? authProvider.displayName : 'M';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isSaving 
                  ? () {} 
                  : (_hasChanges ? _saveProfile : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: FileImage(_pickedImage!),
                                  fit: BoxFit.cover,
                                )
                              : (profilePic.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(profilePic),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: (_pickedImage != null || profilePic.isNotEmpty)
                            ? null
                            : Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF121212),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Name Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Name',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bio Section
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'Bio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    hintText: 'Tell us about yourself...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _bioController,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0, top: 8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${value.text.length} / 150',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Vehicles Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Vehicles',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  if (_vehicles.length < 5)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          final newVehicle = _VehicleEditState(make: '', plate: '', isPrimary: _vehicles.isEmpty);
                          newVehicle.makeController.addListener(_checkForChanges);
                          newVehicle.plateController.addListener(_checkForChanges);
                          _vehicles.add(newVehicle);
                        });
                        _checkForChanges();
                      },
                      icon: const Icon(Icons.add, size: 16, color: Colors.blueAccent),
                      label: const Text('Add Vehicle', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              
              ...List.generate(_vehicles.length, (index) {
                final vehicle = _vehicles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: vehicle.isPrimary ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5) : null,
                  ),
                  child: Column(
                    children: [
                      // Header for Vehicle Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(vehicle.isPrimary ? Icons.star : Icons.directions_car, 
                                  color: vehicle.isPrimary ? Colors.blueAccent : Colors.white54, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  vehicle.isPrimary ? 'Primary Vehicle' : 'Secondary Vehicle',
                                  style: TextStyle(
                                    color: vehicle.isPrimary ? Colors.blueAccent : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (!vehicle.isPrimary)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        for (var v in _vehicles) {
                                          v.isPrimary = false;
                                        }
                                        vehicle.isPrimary = true;
                                      });
                                      _checkForChanges();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Make Primary', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                                  ),
                                if (_vehicles.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        vehicle.dispose();
                                        _vehicles.removeAt(index);
                                        // If we removed the primary, make the first one primary
                                        if (vehicle.isPrimary && _vehicles.isNotEmpty) {
                                          _vehicles.first.isPrimary = true;
                                        }
                                      });
                                      _checkForChanges();
                                    },
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                      _buildVehicleField(
                        icon: Icons.directions_car_rounded,
                        label: 'Car Model',
                        controller: vehicle.makeController,
                        hint: 'Tesla',
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                        indent: 52,
                      ),
                      _buildVehicleField(
                        icon: Icons.pin_rounded,
                        label: 'Number Plate',
                        controller: vehicle.plateController,
                        hint: 'ABC 1234',
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              
              // Footer text
              const Center(
                child: Text(
                  'You can edit your username in Account Settings.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
