import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class VeterinariansScreen extends StatefulWidget {
  final UserRole userRole;

  const VeterinariansScreen({super.key, required this.userRole});

  @override
  State<VeterinariansScreen> createState() => _VeterinariansScreenState();
}

class _VeterinariansScreenState extends State<VeterinariansScreen> {
  List<Map<String, dynamic>> _veterinarians = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVeterinarians();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVeterinarians() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading veterinarians...');
      final veterinarians = await serviceLocator.apiClient.getVeterinarians();
      setState(() {
        _veterinarians = veterinarians;
        _isLoading = false;
      });
      print('✅ Loaded ${veterinarians.length} veterinarians');
    } catch (e) {
      print('❌ Error loading veterinarians: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju veterinara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredVeterinarians {
    if (_searchQuery.isEmpty) return _veterinarians;
    return _veterinarians.where((vet) {
      final firstName = (vet['firstName'] ?? '').toString().toLowerCase();
      final lastName = (vet['lastName'] ?? '').toString().toLowerCase();
      final email = (vet['email'] ?? '').toString().toLowerCase();
      final username = (vet['username'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return firstName.contains(query) || 
             lastName.contains(query) ||
             email.contains(query) || 
             username.contains(query);
    }).toList();
  }

  Future<void> _showAddVeterinarianDialog() async {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final licenseController = TextEditingController();
    final specializationController = TextEditingController();
    final biographyController = TextEditingController();
    int? yearsOfExperience;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Dodaj novog veterinara'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Ime *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ime je obavezno';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Prezime *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Prezime je obavezno';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email je obavezan';
                        }
                        if (!RegExp(r'^[\w-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Unesite valjan email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Korisničko ime *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Korisničko ime je obavezno';
                              }
                              if (value.length < 3) {
                                return 'Korisničko ime mora imati najmanje 3 karaktera';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Lozinka *',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lozinka je obavezna';
                              }
                              if (value.length < 6) {
                                return 'Lozinka mora imati najmanje 6 karaktera';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Broj telefona',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: licenseController,
                            decoration: const InputDecoration(
                              labelText: 'Broj licence',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specijalizacija',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Godine iskustva',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              yearsOfExperience = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: 'Adresa',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: biographyController,
                      decoration: const InputDecoration(
                        labelText: 'Biografija',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: _isCreating ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _isCreating = true;
                  });
                  try {
                    print('📝 Creating veterinarian...');
                    
                    final veterinarianData = {
                      'firstName': firstNameController.text.trim(),
                      'lastName': lastNameController.text.trim(),
                      'email': emailController.text.trim(),
                      'username': usernameController.text.trim(),
                      'password': passwordController.text,
                      'phoneNumber': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                      'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      'licenseNumber': licenseController.text.trim().isEmpty ? null : licenseController.text.trim(),
                      'specialization': specializationController.text.trim().isEmpty ? null : specializationController.text.trim(),
                      'yearsOfExperience': yearsOfExperience,
                      'biography': biographyController.text.trim().isEmpty ? null : biographyController.text.trim(),
                      'role': 2, // Veterinarian role
                      'isActive': true,
                      'isEmailVerified': true,
                    };

                    await serviceLocator.apiClient.register(
                      veterinarianData['firstName']!.toString(),
                      veterinarianData['lastName']!.toString(),
                      veterinarianData['email']!.toString(),
                      veterinarianData['username']!.toString(),
                      veterinarianData['password']!.toString(),
                      phoneNumber: veterinarianData['phoneNumber']?.toString(),
                      address: veterinarianData['address']?.toString(),
                      role: 2, // Veterinarian role
                    );
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veterinar je uspješno kreiran!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadVeterinarians();
                    }
                  } catch (e) {
                    print('❌ Error creating veterinarian: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Greška pri kreiranju veterinara: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isCreating = false;
                      });
                    }
                  }
                }
              },
              child: _isCreating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVeterinarianDetails(Map<String, dynamic> veterinarian) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${veterinarian['firstName']} ${veterinarian['lastName']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email:', veterinarian['email'] ?? ''),
              _buildDetailRow('Korisničko ime:', veterinarian['username'] ?? ''),
              if (veterinarian['phoneNumber'] != null)
                _buildDetailRow('Telefon:', veterinarian['phoneNumber']),
              if (veterinarian['address'] != null)
                _buildDetailRow('Adresa:', veterinarian['address']),
              if (veterinarian['licenseNumber'] != null)
                _buildDetailRow('Broj licence:', veterinarian['licenseNumber']),
              if (veterinarian['specialization'] != null)
                _buildDetailRow('Specijalizacija:', veterinarian['specialization']),
              if (veterinarian['yearsOfExperience'] != null)
                _buildDetailRow('Godine iskustva:', veterinarian['yearsOfExperience'].toString()),
              if (veterinarian['biography'] != null)
                _buildDetailRow('Biografija:', veterinarian['biography']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services,
                  size: 32,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 16),
                Text(
                  'Veterinari',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const Spacer(),
                // Search bar
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži veterinare...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Add button
                ElevatedButton.icon(
                  onPressed: _showAddVeterinarianDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj veterinara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVeterinarians.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Nema veterinara'
                                  : 'Nema rezultata pretrage',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Dodajte prvog veterinara',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _filteredVeterinarians.length,
                        itemBuilder: (context, index) {
                          final veterinarian = _filteredVeterinarians[index];
                          final firstName = veterinarian['firstName'] ?? '';
                          final lastName = veterinarian['lastName'] ?? '';
                          final email = veterinarian['email'] ?? '';
                          final specialization = veterinarian['specialization'];
                          final isActive = veterinarian['isActive'] == true;
                          final isEmailVerified = veterinarian['isEmailVerified'] == true;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              title: Text(
                                '$firstName $lastName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (specialization != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      specialization,
                                      style: TextStyle(
                                        color: Colors.green[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showVeterinarianDetails(veterinarian),
                                tooltip: 'Detalji',
                              ),
                              onTap: () => _showVeterinarianDetails(veterinarian),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
