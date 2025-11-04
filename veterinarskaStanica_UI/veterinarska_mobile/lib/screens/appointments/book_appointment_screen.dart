import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../payments/stripe_payment_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final VoidCallback? onAppointmentBooked; // Callback za refresh liste
  
  const BookAppointmentScreen({super.key, this.onAppointmentBooked});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  Pet? _selectedPet;
  Map<String, dynamic>? _selectedService;
  Map<String, dynamic>? _selectedVeterinarian;
  Map<String, dynamic>? _currentVeterinarian;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  List<Pet> _userPets = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _veterinarians = [];
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadUserPets();
    _loadServices();
    _loadVeterinarians();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPets() async {
    try {
      final authService = serviceLocator.authService;
      if (authService.currentUser == null) return;
      
      final apiClient = serviceLocator.apiClient;
      final userId = authService.currentUser!['id'] as int?;
      if (userId == null) return;
      final pets = await apiClient.getUserPets(userId);
      
      if (mounted) {
        setState(() {
          _userPets = pets;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final services = await apiClient.getServices();
      
      if (mounted) {
        setState(() {
          _services = services;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadVeterinarians() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final veterinarians = await apiClient.getVeterinarians();
      
      if (mounted) {
        setState(() {
          _veterinarians = veterinarians;
        });
      }
    } catch (e) {
      print('Error loading veterinarians: $e');
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedVeterinarian == null || _selectedDate == null) return;
    
    try {
      final apiClient = serviceLocator.apiClient;
      final dateString = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeSlots = await apiClient.getAvailableTimeSlots(
        _selectedVeterinarian!['id'], 
        dateString
      );
      
      if (mounted) {
        setState(() {
          _availableTimeSlots = timeSlots;
        });
      }
    } catch (e) {
      print('Error loading time slots: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite ljubimca'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite uslugu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedVeterinarian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite veterinara'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite datum'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite vreme'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = serviceLocator.apiClient;
      
      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      final appointmentData = {
        'petId': _selectedPet!.id,
        'serviceId': _selectedService!['id'],
        'veterinarianId': _selectedVeterinarian!['id'],
        'appointmentDate': appointmentDateTime.toIso8601String(),
        'startTime': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        'endTime': '${(_selectedTime!.hour + 1).toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00', // Default 1 hour duration
        'reason': _reasonController.text.isEmpty ? _selectedService!['name'] : _reasonController.text,
        'notes': _reasonController.text,
      };
      
      final createdAppointment = await apiClient.bookAppointment(appointmentData);
      
      if (mounted) {
        // Pozovi callback za refresh liste
        widget.onAppointmentBooked?.call();
        
        // Ask user if they want to pay now
        final shouldPay = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Uspešno rezervisan termin!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Termin je uspešno zakazan.\nCena usluge: ${_selectedService!['price']?.toString() ?? '0'} KM',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Želite li da platite sada?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Plati kasnije'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  child: const Text('Plati sada'),
                ),
              ],
            );
          },
        );

        if (shouldPay == true && createdAppointment != null) {
          // Navigate to payment screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StripePaymentScreen(
                appointment: createdAppointment,
                amount: (_selectedService!['price'] as num?)?.toDouble() ?? 0.0,
                service: _selectedService,
              ),
            ),
          );
        }
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri zakazivanju termina: $e'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zakaži termin'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _userPets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nemate registrovane ljubimce',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Prvo dodajte ljubimca da biste mogli zakazati termin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // New Appointment Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add_circle, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Zakazivanje novog termina',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                    // Odabir ljubimca
                    const Text(
                      'Odaberite ljubimca',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Pet>(
                      value: _selectedPet,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Odaberite ljubimca',
                        prefixIcon: const Icon(Icons.pets),
                      ),
                      items: _userPets.map((pet) => DropdownMenuItem(
                        value: pet,
                        child: Text('${pet.name} (${pet.species})'),
                      )).toList(),
                      onChanged: (pet) => setState(() => _selectedPet = pet),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Odabir usluge
                    const Text(
                      'Usluga *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedService,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Odaberite uslugu',
                        prefixIcon: const Icon(Icons.medical_services),
                      ),
                      items: _services.map((service) => DropdownMenuItem(
                        value: service,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service['name'] ?? 'Nepoznata usluga',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${service['price']?.toString() ?? '0'} KM',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      onChanged: (service) => setState(() => _selectedService = service),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Odabir veterinara
                    const Text(
                      'Veterinar *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedVeterinarian,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Odaberite veterinara',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: _veterinarians.map((vet) => DropdownMenuItem(
                        value: vet,
                        child: Text(
                          '${vet['firstName'] ?? ''} ${vet['lastName'] ?? ''}'.trim(),
                        ),
                      )).toList(),
                      onChanged: (vet) => setState(() {
                        _selectedVeterinarian = vet;
                        _loadAvailableTimeSlots();
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Datum
                    const Text(
                      'Datum',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                          _loadAvailableTimeSlots();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                  : 'Odaberite datum',
                              style: TextStyle(
                                color: _selectedDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vreme
                    const Text(
                      'Vreme',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_availableTimeSlots.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedTime != null 
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Odaberite vreme',
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        items: _availableTimeSlots.map((timeSlot) => DropdownMenuItem(
                          value: timeSlot,
                          child: Text(timeSlot),
                        )).toList(),
                        onChanged: (timeSlot) {
                          if (timeSlot != null) {
                            final parts = timeSlot.split(':');
                            setState(() {
                              _selectedTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              );
                            });
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _selectedVeterinarian == null || _selectedDate == null
                                  ? 'Prvo odaberite veterinara i datum'
                                  : 'Nema dostupnih termina',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Napomene (opcionalno)
                    const Text(
                      'Napomene (opcionalno)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Dodatne napomene o terminu...',
                        prefixIcon: const Icon(Icons.note),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Dugme za zakazivanje
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Zakaži termin',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info text
                    Text(
                      'Termin će biti potvrđen od strane veterinarske ambulante',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  
}






