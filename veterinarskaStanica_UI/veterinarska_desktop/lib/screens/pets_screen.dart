import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'pet_card_screen.dart';


class PetsScreen extends StatefulWidget {
  final UserRole userRole;
  final VoidCallback? onPetCreated; // Callback za refresh dashboard-a

  const PetsScreen({super.key, required this.userRole, this.onPetCreated});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  String? _petImageFor(Pet pet) {
    final species = (pet.species).trim().toLowerCase();
    final name = (pet.name).trim().toLowerCase();

    // Any parrot
    if (species.contains('papag') || species.contains('parrot')) {
      return 'assets/images/rio.jpg';
    }
    // Dogs
    if (species.contains('pas') || species.contains('dog')) {
      if (name == 'rex') return 'assets/images/rex.jpg';
      return 'assets/images/luna.jpg';
    }
    return null;
  }


  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Backend već filtrira ovisno o ulozi korisnika i obrisane pacijente (IsDeleted = true)
      print('🔄 Loading pets for desktop app...');
      final pets = await serviceLocator.apiClient.getPets();
      print('✅ Desktop app loaded ${pets.length} pets (backend already filters deleted pets)');
      
      setState(() {
        _pets = pets; // Backend već filtrira obrisane pacijente, tako da ne treba dodatni filter
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading pets: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        setState(() {
          _error = 'Niste ulogovani. Molimo prijavite se ponovo.';
          _isLoading = false;
        });
        return;
      }
      
      // Check if it's a network error with wrong address
      if (e.toString().contains('10.0.2.2') || 
          e.toString().contains('semaphore timeout') ||
          e.toString().contains('connection')) {
        debugPrint('🔄 Network error detected in PetsScreen, resetting ServiceLocator...');
        try {
          // Reset ServiceLocator to recreate ApiClient with correct config
          await serviceLocator.reset();
          debugPrint('✅ ServiceLocator reset complete, retrying pets...');
          
          // Retry loading pets with new ApiClient
          final pets = await serviceLocator.apiClient.getPets();
          
          setState(() {
            _pets = pets;
            _isLoading = false;
          });
          
          return; // Success after retry
        } catch (retryError) {
          debugPrint('❌ Retry after reset failed: $retryError');
          setState(() {
            _error = 'Greška konekcije sa serverom. Provjerite da li je backend pokrenut.';
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _error = 'Greška pri učitavanju pacijenata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Pet> get _filteredPets {
    if (_searchQuery.isEmpty) return _pets;
    return _pets.where((pet) {
      return pet.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             pet.species.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (pet.breed?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
             (pet.ownerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _showPetDetails(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pet image
              if (_petImageFor(pet) != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    image: DecorationImage(
                      image: AssetImage(_petImageFor(pet)!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              const SizedBox(height: 24),
              
              // Pet details
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDetailRow('Vrsta', pet.species),
              if (pet.breed != null) _buildDetailRow('Rasa', pet.breed!),
              _buildDetailRow('Pol', pet.gender == PetGender.male ? 'Muški' : 'Ženski'),
              if (pet.weight != null) _buildDetailRow('Težina', '${pet.weight} kg'),
              if (pet.color != null) _buildDetailRow('Boja', pet.color!),
              if (pet.ownerName != null) _buildDetailRow('Vlasnik', pet.ownerName!),
              _buildDetailRow('Status', pet.status == PetStatus.active ? 'Aktivan' : 'Neaktivan'),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showEditPetDialog(pet);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Uredi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Zatvori'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePet(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi brisanje'),
        content: Text('Da li ste sigurni da želite da obrišete pacijenta "${pet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePet(pet.id);
    }
  }

  Future<void> _deletePet(int petId) async {
    // Optimistički update - odmah ukloni pacijenta iz liste
    Pet? petToRemove;
    try {
      petToRemove = _pets.firstWhere((pet) => pet.id == petId);
    } catch (e) {
      // Pacijent već nije u listi
      petToRemove = null;
    }
    
    setState(() {
      _pets.removeWhere((pet) => pet.id == petId);
    });
    
    try {
      // Zatim pozovi API za brisanje
      await serviceLocator.apiClient.deletePet(petId);
      
      // Pozovi callback za refresh dashboard-a
      if (widget.onPetCreated != null) {
        widget.onPetCreated!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pacijent je uspešno obrisan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Ako brisanje ne uspije, vrati pacijenta u listu (ako je bio uklonjen)
      if (petToRemove != null) {
        setState(() {
          _pets.add(petToRemove!);
          _pets.sort((a, b) => a.name.compareTo(b.name));
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Greška pri brisanju: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddPetDialog() {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final colorController = TextEditingController();
    final weightController = TextEditingController();
    final microchipController = TextEditingController();
    final notesController = TextEditingController();
    final ageController = TextEditingController();
    
    // Vlasnik polja
    final ownerFirstNameController = TextEditingController();
    final ownerLastNameController = TextEditingController();
    final ownerEmailController = TextEditingController();
    final ownerPhoneController = TextEditingController();
    
    PetGender selectedGender = PetGender.male;
    PetStatus selectedStatus = PetStatus.active;
    String? selectedSpecies;
    
    // Lista vrsta životinja
    final List<String> speciesList = [
      'Pas',
      'Mačka',
      'Ptica',
      'Zec',
      'Glodar'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 600,
            height: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF2E7D32), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Novi pacijent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Pacijent podaci
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Ime *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.pets),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedSpecies,
                                decoration: const InputDecoration(
                                  labelText: 'Vrsta *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: speciesList.map((species) {
                                  return DropdownMenuItem<String>(
                                    value: species,
                                    child: Text(species),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() => selectedSpecies = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Molimo izaberite vrstu';
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
                                controller: breedController,
                                decoration: const InputDecoration(
                                  labelText: 'Rasa',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.info),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<PetGender>(
                                value: selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Pol',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.wc),
                                ),
                                items: PetGender.values.map((gender) {
                                  return DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender == PetGender.male ? 'Muški' : 'Ženski'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => selectedGender = value);
                                  }
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
                                controller: weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Težina (kg)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.monitor_weight),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: colorController,
                                decoration: const InputDecoration(
                                  labelText: 'Boja',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.palette),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: microchipController,
                                decoration: const InputDecoration(
                                  labelText: 'Mikročip',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Starost (godine)',
                                  hintText: 'Unesite starost (opcionalno)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.cake),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final age = int.tryParse(value);
                                    if (age == null || age < 0 || age > 50) {
                                      return 'Unesite valjanu starost (0-50)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Vlasnik sekcija
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFF2E7D32), size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Podaci o vlasniku',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: ownerFirstNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Ime vlasnika *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: ownerLastNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prezime vlasnika *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: ownerEmailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email vlasnika *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.email),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: ownerPhoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Telefon vlasnika',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Napomene',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Otkaži'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isEmpty || 
                                    selectedSpecies == null || selectedSpecies!.isEmpty ||
                                    ownerFirstNameController.text.isEmpty ||
                                    ownerLastNameController.text.isEmpty ||
                                    ownerEmailController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Molimo unesite obavezna polja (Ime pacijenta, Vrsta, Ime vlasnika, Prezime vlasnika, Email vlasnika)'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // Izračunaj dateOfBirth iz unesene starosti
                                DateTime? dateOfBirth;
                                if (ageController.text.isNotEmpty) {
                                  final age = int.tryParse(ageController.text);
                                  if (age != null && age >= 0) {
                                    final now = DateTime.now();
                                    dateOfBirth = DateTime(now.year - age, now.month, now.day);
                                  }
                                }

                                await _createPetWithOwner({
                                  // Pacijent podaci
                                  'name': nameController.text,
                                  'species': selectedSpecies!,
                                  'breed': breedController.text.isEmpty ? null : breedController.text,
                                  'gender': selectedGender == PetGender.male ? 1 : 2,
                                  'weight': weightController.text.isEmpty ? null : double.tryParse(weightController.text),
                                  'color': colorController.text.isEmpty ? null : colorController.text,
                                  'notes': notesController.text.isEmpty ? null : notesController.text,
                                  'microchip': microchipController.text.isEmpty ? null : microchipController.text,
                                  'dateOfBirth': dateOfBirth?.toIso8601String(),
                                  // Vlasnik podaci
                                  'ownerFirstName': ownerFirstNameController.text,
                                  'ownerLastName': ownerLastNameController.text,
                                  'ownerEmail': ownerEmailController.text,
                                  'ownerPhone': ownerPhoneController.text.isEmpty ? null : ownerPhoneController.text,
                                });
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Kreiraj'),
                            ),
                          ],
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
    );
  }

  Future<void> _createPetWithOwner(Map<String, dynamic> data) async {
    try {
      
      // Prvo kreiraj vlasnika
      final ownerData = {
        'firstName': data['ownerFirstName'],
        'lastName': data['ownerLastName'],
        'email': data['ownerEmail'],
        'phoneNumber': data['ownerPhone'],
        'role': 1, // PetOwner role
        'isActive': true,
        'isEmailVerified': false,
        'clientType': 'Desktop',
      };
      
      
      // Kreiraj jedinstveni username od imena i prezimena + timestamp
      String baseUsername = '${ownerData['firstName']}${ownerData['lastName']}'.toLowerCase().replaceAll(' ', '');
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8); // Poslednje 3 cifre
      String username = '$baseUsername$timestamp';
      
      // Ograniči na 50 karaktera
      if (username.length > 50) {
        username = username.substring(0, 50);
      }
      
      print('📧 Email: ${ownerData['email']} (${ownerData['email'].length} karaktera)');
      print('👤 Username: $username (${username.length} karaktera)');
      
      final ownerResponse = await serviceLocator.apiClient.register(
        ownerData['firstName'],
        ownerData['lastName'],
        ownerData['email'],
        username,
        'TempPassword123!', // Temporary password
        phoneNumber: ownerData['phoneNumber'],
      );
      
      print('✅ Owner created successfully with ID: ${ownerResponse['id']}');
      
      // Zatim kreiraj pacijenta
      final petData = {
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'],
        'gender': data['gender'],
        'weight': data['weight'],
        'color': data['color'],
        'notes': data['notes'],
        'microchipNumber': data['microchip'],
        'dateOfBirth': data['dateOfBirth'],
        'petOwnerId': ownerResponse['id'], // ID novog vlasnika
      };
      
      await serviceLocator.apiClient.createPet(petData);
      
      await _loadPets(); // Reload pets
      
      // Pozovi callback za refresh dashboard-a
      if (widget.onPetCreated != null) {
        widget.onPetCreated!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Novi pacijent i vlasnik su uspešno kreirani'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating pet with owner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Greška pri kreiranju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Greška: $_error', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPets,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.pets, size: 32, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              const Text(
                'Pacijenti',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddPetDialog,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj pacijenta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadPets,
                icon: const Icon(Icons.refresh),
                tooltip: 'Osveži',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Pretraži pacijente...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Filter opcije (samo za veterinare)

          // Stats
          Row(
            children: [
              _buildStatCard(
                widget.userRole == UserRole.admin ? 'Svi pacijenti' : 'Moji pacijenti', 
                _pets.length, 
                Icons.pets
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pets list
          Expanded(
            child: _filteredPets.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nema pacijenata',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPets.length,
                    itemBuilder: (context, index) {
                      final pet = _filteredPets[index];
                      return _buildPetListItem(pet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetListItem(Pet pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Pet image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: _petImageFor(pet) != null
                    ? DecorationImage(
                        image: AssetImage(_petImageFor(pet)!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: _petImageFor(pet) == null 
                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                    : null,
              ),
              child: _petImageFor(pet) == null
                  ? const Icon(
                      Icons.pets,
                      size: 30,
                      color: Color(0xFF2E7D32),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.species,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (pet.breed != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      pet.breed!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (pet.ownerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Vlasnik: ${pet.ownerName!}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pet.status == PetStatus.active 
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pet.status == PetStatus.active 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                pet.status == PetStatus.active ? 'Aktivan' : 'Neaktivan',
                style: TextStyle(
                  fontSize: 11,
                  color: pet.status == PetStatus.active 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Karton button (za admin i veterinar)
                if (widget.userRole == UserRole.admin || widget.userRole == UserRole.veterinarian)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PetCardScreen(pet: pet),
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder, size: 16),
                    label: const Text('KARTON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (widget.userRole == UserRole.admin || widget.userRole == UserRole.veterinarian) const SizedBox(width: 8),
                
                // Delete button
                ElevatedButton.icon(
                  onPressed: () => _confirmDeletePet(pet),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Obriši'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPetDialog(Pet pet) {
    final nameController = TextEditingController(text: pet.name);
    final breedController = TextEditingController(text: pet.breed ?? '');
    final colorController = TextEditingController(text: pet.color ?? '');
    final weightController = TextEditingController(text: pet.weight?.toString() ?? '');
    final microchipController = TextEditingController(text: pet.microchipNumber ?? '');
    final notesController = TextEditingController(text: pet.notes ?? '');
    final ageController = TextEditingController();
    
    PetGender selectedGender = pet.gender;
    PetStatus selectedStatus = pet.status;
    String? selectedSpecies = pet.species;
    
    // Ako postoji datum rođenja, izračunaj starost
    if (pet.dateOfBirth != null) {
      final now = DateTime.now();
      final birthDate = pet.dateOfBirth!;
      final age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        ageController.text = (age - 1).toString();
      } else {
        ageController.text = age.toString();
      }
    }
    
    // Lista vrsta životinja
    final List<String> speciesList = [
      'Pas',
      'Mačka',
      'Ptica',
      'Zec',
      'Glodar'
    ];
    
    // Ako trenutna vrsta nije u listi, dodaj je
    if (selectedSpecies != null && 
        selectedSpecies!.isNotEmpty && 
        !speciesList.contains(selectedSpecies)) {
      speciesList.insert(0, selectedSpecies!);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 600,
            height: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.edit, color: Color(0xFF2E7D32), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Uredi pacijenta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Pacijent podaci
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Ime *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.pets),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedSpecies,
                                decoration: const InputDecoration(
                                  labelText: 'Vrsta *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: speciesList.map((species) {
                                  return DropdownMenuItem<String>(
                                    value: species,
                                    child: Text(species),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() => selectedSpecies = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Molimo izaberite vrstu';
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
                                controller: breedController,
                                decoration: const InputDecoration(
                                  labelText: 'Rasa',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.info),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<PetGender>(
                                value: selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Pol',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.wc),
                                ),
                                items: PetGender.values.map((gender) {
                                  return DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender == PetGender.male ? 'Muški' : 'Ženski'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => selectedGender = value);
                                  }
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
                                controller: weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Težina (kg)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.monitor_weight),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: colorController,
                                decoration: const InputDecoration(
                                  labelText: 'Boja',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.palette),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: microchipController,
                                decoration: const InputDecoration(
                                  labelText: 'Mikročip',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Starost (godine)',
                                  hintText: 'Unesite starost (opcionalno)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.cake),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final age = int.tryParse(value);
                                    if (age == null || age < 0 || age > 50) {
                                      return 'Unesite valjanu starost (0-50)';
                                    }
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
                              child: DropdownButtonFormField<PetStatus>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.info_outline),
                                ),
                                items: [
                                  // Prikaži samo Aktivan i Neaktivan (ne prikazuj deceased)
                                  DropdownMenuItem(
                                    value: PetStatus.active,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Aktivan',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: PetStatus.inactive,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Neaktivan',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => selectedStatus = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Napomene',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Otkaži'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isEmpty || 
                                    selectedSpecies == null || selectedSpecies!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Molimo unesite obavezna polja (Ime i Vrsta)'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // Izračunaj dateOfBirth iz unesene starosti
                                DateTime? dateOfBirth;
                                if (ageController.text.isNotEmpty) {
                                  final age = int.tryParse(ageController.text);
                                  if (age != null && age >= 0) {
                                    final now = DateTime.now();
                                    dateOfBirth = DateTime(now.year - age, now.month, now.day);
                                  }
                                }

                                // Optimistički update - ažuriraj pacijenta u listi odmah
                                final updatedPet = Pet(
                                  id: pet.id,
                                  name: nameController.text,
                                  species: selectedSpecies!,
                                  breed: breedController.text.isEmpty ? null : breedController.text,
                                  gender: selectedGender!,
                                  dateOfBirth: dateOfBirth,
                                  weight: weightController.text.isEmpty ? null : double.tryParse(weightController.text),
                                  color: colorController.text.isEmpty ? null : colorController.text,
                                  microchipNumber: microchipController.text.isEmpty ? null : microchipController.text,
                                  status: selectedStatus!,
                                  notes: notesController.text.isEmpty ? null : notesController.text,
                                  ownerId: pet.ownerId,
                                  ownerName: pet.ownerName,
                                  createdAt: pet.createdAt,
                                  updatedAt: DateTime.now(),
                                );
                                
                                // Ažuriraj pacijenta u listi i osvježi UI odmah
                                final index = _pets.indexWhere((p) => p.id == pet.id);
                                if (index != -1) {
                                  // Kreiraj novu listu da Flutter detektira promjenu i rebuild-uje UI
                                  setState(() {
                                    _pets = List.from(_pets)..[index] = updatedPet;
                                  });
                                }
                                
                                // Zatvori dijalog odmah
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                                
                                // Zatim pozovi API za ažuriranje u pozadini (skipReload jer smo već napravili optimistički update)
                                // Ako API uspije, ažuriraj podatke iz odgovora (osigurava da su podaci sinkronizirani)
                                _updatePet(pet.id, {
                                  'name': nameController.text,
                                  'species': selectedSpecies!,
                                  'breed': breedController.text.isEmpty ? null : breedController.text,
                                  'gender': selectedGender == PetGender.male ? 1 : 2,
                                  'weight': weightController.text.isEmpty ? null : double.tryParse(weightController.text),
                                  'color': colorController.text.isEmpty ? null : colorController.text,
                                  'notes': notesController.text.isEmpty ? null : notesController.text,
                                  'microchipNumber': microchipController.text.isEmpty ? null : microchipController.text,
                                  'status': selectedStatus == PetStatus.active 
                                      ? 1 
                                      : (selectedStatus == PetStatus.inactive ? 2 : 3),
                                  'dateOfBirth': dateOfBirth?.toIso8601String(),
                                }, skipReload: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Sačuvaj'),
                            ),
                          ],
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
    );
  }

  Future<void> _updatePet(int petId, Map<String, dynamic> data, {bool skipReload = false}) async {
    try {
      final updatedPetData = await serviceLocator.apiClient.updatePet(petId, data);
      
      // Ako nije optimistički update, reload pets
      if (!skipReload) {
        await _loadPets();
      } else {
        // Ako je optimistički update, ažuriraj podatke iz API odgovora (osigurava da su podaci sinkronizirani, posebno status)
        if (updatedPetData != null) {
          setState(() {
            final index = _pets.indexWhere((p) => p.id == petId);
            if (index != -1) {
              _pets[index] = updatedPetData; // Ažuriraj sa podacima iz API-ja (osigurava da je status pravilno postavljen)
            }
          });
        }
      }
      
      // Pozovi callback za refresh dashboard-a
      if (widget.onPetCreated != null) {
        widget.onPetCreated!();
      }
      
      if (mounted && !skipReload) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pacijent je uspešno ažuriran'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating pet: $e');
      
      // Ako je optimistički update i došlo je do greške, reload pets da vratimo originalne podatke
      if (skipReload) {
        await _loadPets();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Greška pri ažuriranju: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

}