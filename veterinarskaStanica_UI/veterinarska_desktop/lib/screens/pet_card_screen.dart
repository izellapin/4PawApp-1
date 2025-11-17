import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class PetCardScreen extends StatefulWidget {
  final Pet pet;

  const PetCardScreen({super.key, required this.pet});

  @override
  State<PetCardScreen> createState() => _PetCardScreenState();
}

class _PetCardScreenState extends State<PetCardScreen> {
  late Pet _pet;
  List<Appointment> _appointments = [];
  bool _isLoadingAppointments = true;
  bool _isEditing = false;

  // Controllers za edit
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _weightController;
  late TextEditingController _microchipController;
  late TextEditingController _notesController;
  late TextEditingController _ageController;

  PetGender _selectedGender = PetGender.male;
  PetStatus _selectedStatus = PetStatus.active;
  String? _selectedSpecies;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _initializeControllers();
    _loadAppointments();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _pet.name);
    _breedController = TextEditingController(text: _pet.breed ?? '');
    _colorController = TextEditingController(text: _pet.color ?? '');
    _weightController = TextEditingController(text: _pet.weight?.toString() ?? '');
    _microchipController = TextEditingController(text: _pet.microchipNumber ?? '');
    _notesController = TextEditingController(text: _pet.notes ?? '');
    _ageController = TextEditingController();
    
    _selectedGender = _pet.gender;
    _selectedStatus = _pet.status;
    _selectedSpecies = _pet.species;

    // Ako postoji datum rođenja, izračunaj starost
    if (_pet.dateOfBirth != null) {
      final now = DateTime.now();
      final birthDate = _pet.dateOfBirth!;
      final age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        _ageController.text = (age - 1).toString();
      } else {
        _ageController.text = age.toString();
      }
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      print('📅 [PET CARD] Loading appointments for pet ID: ${_pet.id}');
      final allAppointments = await serviceLocator.apiClient.getAppointments();
      print('📅 [PET CARD] Loaded ${allAppointments.length} total appointments');
      
          // Filtriraj appointments po petId ili petName (fallback ako petId nije dostupan)
          print('📅 [PET CARD] Pet ID type: ${_pet.id.runtimeType}, value: ${_pet.id}');
          print('📅 [PET CARD] Pet Name: ${_pet.name}');
          print('📅 [PET CARD] Checking ${allAppointments.length} appointments...');
          
          final petAppointments = <Appointment>[];
          for (final apt in allAppointments) {
            // Prvo pokušaj sa petId, ako nije dostupan koristi petName
            bool matches = false;
            if (apt.petId > 0 && apt.petId == _pet.id) {
              matches = true;
              print('✅ [PET CARD] MATCH by petId! Appointment ${apt.id}: petId=${apt.petId} == pet.id=${_pet.id}');
            } else if (apt.petName != null && apt.petName!.trim().toLowerCase() == _pet.name.trim().toLowerCase()) {
              matches = true;
              print('✅ [PET CARD] MATCH by petName! Appointment ${apt.id}: petName="${apt.petName}" == pet.name="${_pet.name}"');
            } else {
              print('❌ [PET CARD] NO MATCH: Appointment ${apt.id}: petId=${apt.petId}, petName="${apt.petName}" vs pet.id=${_pet.id}, pet.name="${_pet.name}"');
            }
            
            if (matches) {
              print('✅ [PET CARD] Found appointment: ID=${apt.id}, Date=${apt.appointmentDate}, Service=${apt.serviceName ?? apt.reason}');
              petAppointments.add(apt);
            }
          }
      
      // Sortiraj po datumu (najnoviji prvo)
      petAppointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      print('📅 [PET CARD] Found ${petAppointments.length} appointments for pet ${_pet.id} (${_pet.name})');
      
      if (petAppointments.isEmpty && allAppointments.isNotEmpty) {
        print('⚠️ [PET CARD] No appointments found for pet ${_pet.id}, but total appointments: ${allAppointments.length}');
        print('⚠️ [PET CARD] All appointment petIds: ${allAppointments.map((a) => 'Appt${a.id}:petId=${a.petId}').join(', ')}');
        print('⚠️ [PET CARD] Looking for pet ID: ${_pet.id}');
      }

      setState(() {
        _appointments = petAppointments;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      print('❌ [PET CARD] Error loading appointments: $e');
      print('❌ [PET CARD] Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingAppointments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju pregleda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePetChanges() async {
    if (_nameController.text.isEmpty || _selectedSpecies == null || _selectedSpecies!.isEmpty) {
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
    if (_ageController.text.isNotEmpty) {
      final age = int.tryParse(_ageController.text);
      if (age != null && age >= 0) {
        final now = DateTime.now();
        dateOfBirth = DateTime(now.year - age, now.month, now.day);
      }
    }

    try {
      await serviceLocator.apiClient.updatePet(_pet.id, {
        'name': _nameController.text,
        'species': _selectedSpecies!,
        'breed': _breedController.text.isEmpty ? null : _breedController.text,
        'gender': _selectedGender == PetGender.male ? 1 : 2,
        'weight': _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
        'color': _colorController.text.isEmpty ? null : _colorController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'microchipNumber': _microchipController.text.isEmpty ? null : _microchipController.text,
        'status': _selectedStatus == PetStatus.active
            ? 1
            : (_selectedStatus == PetStatus.inactive ? 2 : 3),
        'dateOfBirth': dateOfBirth?.toIso8601String(),
      });

      // Reload pet data
      final updatedPets = await serviceLocator.apiClient.getPets();
      final updatedPet = updatedPets.firstWhere((p) => p.id == _pet.id);
      
      setState(() {
        _pet = updatedPet;
        _isEditing = false;
      });

      _initializeControllers(); // Reset controllers sa novim podacima

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pacijent je uspešno ažuriran'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating pet: $e');
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

  void _cancelEdit() {
    _initializeControllers(); // Reset na originalne vrijednosti
    setState(() {
      _isEditing = false;
    });
  }

  String? _petImageFor(Pet pet) {
    final species = (pet.species).trim().toLowerCase();
    final name = (pet.name).trim().toLowerCase();

    if (species.contains('papag') || species.contains('parrot')) {
      return 'assets/images/rio.jpg';
    }
    if (species.contains('pas') || species.contains('dog')) {
      if (name == 'rex') return 'assets/images/rex.jpg';
      return 'assets/images/luna.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> speciesList = [
      'Pas',
      'Mačka',
      'Ptica',
      'Zec',
      'Glodar'
    ];

    // Ako trenutna vrsta nije u listi, dodaj je
    if (_selectedSpecies != null &&
        _selectedSpecies!.isNotEmpty &&
        !speciesList.contains(_selectedSpecies)) {
      speciesList.insert(0, _selectedSpecies!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Karton: ${_pet.name}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Uredi',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _cancelEdit,
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text('Otkaži', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _savePetChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Sačuvaj'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
        ],
      ),
      body: Row(
        children: [
          // Leva strana - Detalji pacijenta
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet image
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(75),
                          image: _petImageFor(_pet) != null
                              ? DecorationImage(
                                  image: AssetImage(_petImageFor(_pet)!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: _petImageFor(_pet) == null
                              ? const Color(0xFF2E7D32).withOpacity(0.1)
                              : null,
                        ),
                        child: _petImageFor(_pet) == null
                            ? const Icon(
                                Icons.pets,
                                size: 75,
                                color: Color(0xFF2E7D32),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pet details form
                    if (_isEditing) ...[
                      // Edit mode
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ime *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pets),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSpecies,
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
                          setState(() {
                            _selectedSpecies = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _breedController,
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
                              value: _selectedGender,
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
                                  setState(() {
                                    _selectedGender = value;
                                  });
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
                              controller: _weightController,
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
                              controller: _colorController,
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
                              controller: _microchipController,
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
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Starost (godine)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.cake),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PetStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: PetStatus.active,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
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
                                  decoration: const BoxDecoration(
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
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Napomene',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ] else ...[
                      // View mode
                      _buildDetailRow('Ime', _pet.name),
                      _buildDetailRow('Vrsta', _pet.species),
                      if (_pet.breed != null) _buildDetailRow('Rasa', _pet.breed!),
                      _buildDetailRow('Pol', _pet.gender == PetGender.male ? 'Muški' : 'Ženski'),
                      if (_pet.weight != null) _buildDetailRow('Težina', '${_pet.weight} kg'),
                      if (_pet.color != null) _buildDetailRow('Boja', _pet.color!),
                      if (_pet.microchipNumber != null) _buildDetailRow('Mikročip', _pet.microchipNumber!),
                      if (_pet.dateOfBirth != null) ...[
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final birthDate = _pet.dateOfBirth!;
                            final age = now.year - birthDate.year;
                            final ageText = (now.month < birthDate.month ||
                                    (now.month == birthDate.month && now.day < birthDate.day))
                                ? (age - 1).toString()
                                : age.toString();
                            return _buildDetailRow('Starost', '$ageText godina');
                          },
                        ),
                      ],
                      if (_pet.ownerName != null) _buildDetailRow('Vlasnik', _pet.ownerName!),
                      _buildDetailRow('Status', _pet.status == PetStatus.active ? 'Aktivan' : 'Neaktivan'),
                      if (_pet.notes != null && _pet.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Napomene:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pet.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Desna strana - Historija pregleda
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 28, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 12),
                      const Text(
                        'Historija pregleda',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Osveži',
                        onPressed: _loadAppointments,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingAppointments
                        ? const Center(child: CircularProgressIndicator())
                        : _appointments.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Nema pregleda',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _appointments.length,
                                itemBuilder: (context, index) {
                                  final appointment = _appointments[index];
                                  return _buildAppointmentCard(appointment);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    Color statusTextColor;
    String statusText;
    switch (appointment.status) {
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        statusTextColor = Colors.green.shade700;
        statusText = 'Završen';
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusTextColor = Colors.red.shade700;
        statusText = 'Otkazan';
        break;
      case AppointmentStatus.inProgress:
        statusColor = Colors.blue;
        statusTextColor = Colors.blue.shade700;
        statusText = 'U toku';
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.orange;
        statusTextColor = Colors.orange.shade700;
        statusText = 'Potvrđen';
        break;
      default:
        statusColor = Colors.grey;
        statusTextColor = Colors.grey.shade700;
        statusText = 'Zakazan';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceName ?? appointment.reason ?? 'Pregled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  appointment.formattedDate,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  appointment.timeRange,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (appointment.veterinarianName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Veterinar: ${appointment.veterinarianName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (appointment.actualCost != null || appointment.estimatedCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Cijena: ${appointment.actualCost ?? appointment.estimatedCost} KM',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (appointment.isPaid) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Plaćeno',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appointment.notes!,
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

