import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'package:veterinarska_shared/utils/validation_helpers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Veterinar fields
  final _licenseNumberController = TextEditingController();
  final _specializationController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _biographyController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _specializationController.dispose();
    _yearsOfExperienceController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await serviceLocator.apiClient.getCurrentUser();
      setState(() {
        _userData = userData;
        _isLoading = false;
        _populateControllers();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri učitavanju profila: $e')),
        );
      }
    }
  }

  void _populateControllers() {
    if (_userData != null) {
      _firstNameController.text = _userData!['firstName'] ?? '';
      _lastNameController.text = _userData!['lastName'] ?? '';
      _emailController.text = _userData!['email'] ?? '';
      _phoneController.text = _userData!['phoneNumber'] ?? '';
      _addressController.text = _userData!['address'] ?? '';
      _licenseNumberController.text = _userData!['licenseNumber'] ?? '';
      _specializationController.text = _userData!['specialization'] ?? '';
      _yearsOfExperienceController.text = (_userData!['yearsOfExperience'] != null) 
          ? _userData!['yearsOfExperience'].toString() 
          : '';
      _biographyController.text = _userData!['biography'] ?? '';
    }
  }

  bool _isVeterinarian() {
    final role = _userData?['role'];
    if (role == null) return false;
    
    // Convert to int if it's a string number
    int roleInt;
    if (role is int) {
      roleInt = role;
    } else if (role is String) {
      roleInt = int.tryParse(role) ?? 0;
    } else {
      return false;
    }
    
    return roleInt == 2; // Veterinarian role
  }

  String _getRoleDisplayName() {
    final role = _userData?['role'];
    if (role == null) return 'Nepoznato';
    
    // Convert to int if it's a string number
    int roleInt;
    if (role is int) {
      roleInt = role;
    } else if (role is String) {
      roleInt = int.tryParse(role) ?? 0;
    } else {
      return 'Nepoznato';
    }
    
    switch (roleInt) {
      case 1: return 'Vlasnik ljubimca';
      case 2: return 'Veterinar';
      case 3: return 'Veterinarski tehničar';
      case 4: return 'Recepcioner';
      case 5: return 'Administrator';
      default: return 'Nepoznato';
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updateData = <String, dynamic>{};
    
    // Basic fields
    if (_firstNameController.text != (_userData!['firstName'] ?? '')) {
      updateData['firstName'] = _firstNameController.text;
    }
    if (_lastNameController.text != (_userData!['lastName'] ?? '')) {
      updateData['lastName'] = _lastNameController.text;
    }
    if (_emailController.text != (_userData!['email'] ?? '')) {
      updateData['email'] = _emailController.text;
    }
    if (_phoneController.text != (_userData!['phoneNumber'] ?? '')) {
      updateData['phoneNumber'] = _phoneController.text;
    }
    if (_addressController.text != (_userData!['address'] ?? '')) {
      updateData['address'] = _addressController.text;
    }

    // Veterinar fields
    if (_isVeterinarian()) {
      if (_licenseNumberController.text != (_userData!['licenseNumber'] ?? '')) {
        updateData['licenseNumber'] = _licenseNumberController.text;
      }
      if (_specializationController.text != (_userData!['specialization'] ?? '')) {
        updateData['specialization'] = _specializationController.text;
      }
      final currentYearsString = (_userData!['yearsOfExperience'] != null) 
          ? _userData!['yearsOfExperience'].toString() 
          : '';
      if (_yearsOfExperienceController.text != currentYearsString) {
        final years = int.tryParse(_yearsOfExperienceController.text);
        if (years != null) {
          updateData['yearsOfExperience'] = years;
        } else if (_yearsOfExperienceController.text.isEmpty) {
          updateData['yearsOfExperience'] = null;
        }
      }
      if (_biographyController.text != (_userData!['biography'] ?? '')) {
        updateData['biography'] = _biographyController.text;
      }
    }

    if (updateData.isEmpty) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nema promjena za čuvanje')),
      );
      return;
    }

    try {
      print('🔄 Šalje se update sa podacima: $updateData');
      await serviceLocator.apiClient.updateCurrentUser(updateData);
      print('✅ Update uspešan, reload-uje se profil');
      await _loadUserData(); // Reload data
      setState(() => _isEditing = false);
      
      if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil je uspješno ažuriran. Sve promjene su sačuvane.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
      }
    } catch (e) {
      print('❌ Greška pri ažuriranju profila: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Greška pri ažuriranju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promijeni lozinku'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Trenutna lozinka',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => ValidationHelpers.validateRequired(value, 'trenutnu lozinku'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nova lozinka',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => ValidationHelpers.validatePassword(value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Potvrdi novu lozinku',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => ValidationHelpers.validatePasswordConfirmation(
                  value,
                  newPasswordController.text,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    print('🔄 Menja se šifra...');
                    await serviceLocator.apiClient.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    print('✅ Šifra uspešno promenjena');
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lozinka je uspješno promijenjena. Možete se prijaviti sa novom lozinkom.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    print('❌ Greška pri menjanju šifre: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Greška: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            child: const Text('Promijeni'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(
        child: Text('Greška pri učitavanju profila'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.person, size: 32, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Moj profil',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isEditing) ...[
                ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Uredi'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showChangePasswordDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lozinka'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sačuvaj'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _populateControllers(); // Reset form
                  },
                  child: const Text('Otkaži'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Basic Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Osnovne informacije',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ime',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    enabled: _isEditing,
                                    validator: (value) => ValidationHelpers.validateRequired(value, 'Ime'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Prezime',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    enabled: _isEditing,
                                    validator: (value) => ValidationHelpers.validateRequired(value, 'Prezime'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              enabled: _isEditing,
                              validator: (value) => ValidationHelpers.validateEmail(value),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Telefon',
                                prefixIcon: const Icon(Icons.phone),
                                helperText: _isEditing ? 'Format: 061 111 222' : null,
                              ),
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                              inputFormatters: _isEditing ? [
                                // Format input as user types: 061 111 222
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                              ] : null,
                              validator: _isEditing ? (value) => ValidationHelpers.validatePhoneFormat(value, required: false) : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresa',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Veterinar Info Card (only if veterinarian)
                    if (_isVeterinarian()) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veterinarske informacije',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _licenseNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'Broj licence',
                                        prefixIcon: Icon(Icons.badge),
                                      ),
                                      enabled: _isEditing,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _yearsOfExperienceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Godine iskustva',
                                        prefixIcon: Icon(Icons.timeline),
                                      ),
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _specializationController,
                                decoration: const InputDecoration(
                                  labelText: 'Specijalizacija',
                                  prefixIcon: Icon(Icons.medical_services),
                                ),
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _biographyController,
                                decoration: const InputDecoration(
                                  labelText: 'Biografija',
                                  prefixIcon: Icon(Icons.description),
                                  alignLabelWithHint: true,
                                ),
                                enabled: _isEditing,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Account Status Card
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status računa',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.badge),
                                title: const Text('Uloga'),
                                subtitle: Text(_getRoleDisplayName()),
                              ),
                            ListTile(
                              leading: Icon(
                                _userData!['isEmailVerified'] == true
                                    ? Icons.verified
                                    : Icons.warning,
                                color: _userData!['isEmailVerified'] == true
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: const Text('Email verifikovan'),
                              subtitle: Text(
                                _userData!['isEmailVerified'] == true ? 'Da' : 'Ne',
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                _userData!['isActive'] == true
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _userData!['isActive'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: const Text('Račun aktivan'),
                              subtitle: Text(
                                _userData!['isActive'] == true ? 'Da' : 'Ne',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



