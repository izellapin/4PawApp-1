import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class AppointmentScreen extends StatefulWidget {
  final UserRole userRole;

  const AppointmentScreen({
    Key? key,
    required this.userRole,
  }) : super(key: key);

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  List<Pet> _pets = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _veterinarians = [];
  int? _selectedVeterinarianId; // Safe selected value for dropdown
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDate;
  Appointment? _selectedAppointment;
  DateTime? _filterDate;
  int? _currentUserId; // Koristi se za automatsko popunjavanje ID veterinara
  bool _isRefreshing = false; // Za refresh button

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadPets();
    _loadServices();
    _loadVeterinarians();
    _loadCurrentUserId();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = serviceLocator.apiClient;
      List<Appointment> appointments;

      if (widget.userRole == UserRole.admin) {
        debugPrint('📋 Loading ALL appointments for admin...');
        appointments = await apiClient.getAppointments();
      } else {
        debugPrint('📋 Loading MY appointments for veterinarian...');
        appointments = await apiClient.getMyAppointments();
      }

      debugPrint('✅ Appointments loaded: ${appointments.length} appointments');
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });

      if (_filterDate != null) {
        _filterAppointmentsByDate(_filterDate);
      } else {
        setState(() {
          _filteredAppointments = appointments;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading appointments: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is ApiError) {
        debugPrint('❌ ApiError details:');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Status Code: ${e.statusCode}');
        debugPrint('   Details: ${e.details}');
      }
      
      debugPrint('🔄 Resetting ServiceLocator and retrying...');
      try {
        await serviceLocator.reset();
        debugPrint('✅ ServiceLocator reset complete, retrying...');
        
        final apiClient = serviceLocator.apiClient;
        List<Appointment> appointments;

        if (widget.userRole == UserRole.admin) {
          appointments = await apiClient.getAppointments();
        } else {
          appointments = await apiClient.getMyAppointments();
        }

        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });

        if (_filterDate != null) {
          _filterAppointmentsByDate(_filterDate);
        } else {
          setState(() {
            _filteredAppointments = appointments;
          });
        }
        debugPrint('✅ Appointments loaded successfully after reset');
        return; // Success after retry
      } catch (retryError) {
        debugPrint('❌ Retry after reset failed: $retryError');
        setState(() {
          _error = 'Greška konekcije sa serverom. Provjerite da li je backend pokrenut.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final me = await apiClient.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUserId = me['id'] as int?;
      });
    } catch (e) {
      debugPrint('Greška pri dohvaćanju trenutnog korisnika: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await _loadAppointments();
      await _loadPets();
      await _loadServices();
      await _loadVeterinarians();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podaci su ažurirani'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri ažuriranju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadPets() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final pets = await apiClient.getAllPets();
      if (!mounted) return;
      setState(() {
        _pets = pets;
      });
    } catch (e) {
      debugPrint('Greška pri učitavanju pacijenata: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final services = await apiClient.getServices();
      if (!mounted) return;
      setState(() {
        _services = List<Map<String, dynamic>>.from(services);
      });
    } catch (e) {
      debugPrint('Greška pri učitavanju usluga: $e');
    }
  }

  Future<void> _loadVeterinarians() async {
    try {
      final apiClient = serviceLocator.apiClient;
      final veterinarians = await apiClient.getVeterinarians();
      if (!mounted) return;
      setState(() {
        _veterinarians = List<Map<String, dynamic>>.from(veterinarians);
        // Ne postavljamo vrijednost ovdje jer kontroler je lokalni u dijalogu
        // i može biti null u ovom kontekstu. Vrijednost se postavlja pri otvaranju dijaloga.
        if (_selectedVeterinarianId != null &&
            !_veterinarians.any((v) => v['id'] == _selectedVeterinarianId)) {
          _selectedVeterinarianId = null;
        }
      });
    } catch (e) {
      debugPrint('Greška pri učitavanju veterinara: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedAppointment = null;
    });
  }

  void _filterAppointmentsByDate(DateTime? date) {
    setState(() {
      _filterDate = date;
      if (date == null) {
        _filteredAppointments = _appointments;
      } else {
        _filteredAppointments = _appointments.where((appointment) {
          return appointment.appointmentDate.year == date.year &&
                 appointment.appointmentDate.month == date.month &&
                 appointment.appointmentDate.day == date.day;
        }).toList();
      }
    });
  }

  void _onAppointmentSelected(Appointment appointment) {
    setState(() {
      _selectedAppointment = appointment;
    });
    _showAppointmentDetails(appointment);
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F5E8),
                  Color(0xFFF0F8F0),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.event,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalji Termina',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              appointment.appointmentNumber,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Pacijent', appointment.petName ?? 'Nepoznato', Icons.pets),
                        _buildDetailRow('Vlasnik', appointment.ownerName ?? 'Nepoznato', Icons.person),
                        _buildDetailRow('Veterinar', appointment.veterinarianName ?? 'Nepoznato', Icons.medical_services),
                        _buildDetailRow('Tip', appointment.typeText, Icons.category),
                        _buildDetailRow('Status', appointment.statusText, Icons.info),
                        if (appointment.isPaid) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade600, width: 2),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'PLAĆENO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                if (appointment.paymentMethod != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${appointment.paymentMethod})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        _buildDetailRow('Datum', '${appointment.appointmentDate.day}.${appointment.appointmentDate.month}.${appointment.appointmentDate.year}', Icons.calendar_today),
                        _buildDetailRow('Vreme', appointment.timeRange, Icons.access_time),
                        if (appointment.reason != null)
                          _buildDetailRow('Razlog', appointment.reason!, Icons.description),
                        if (appointment.notes != null)
                          _buildDetailRow('Napomene', appointment.notes!, Icons.note),
                        if (appointment.estimatedCost != null)
                          _buildDetailRow('Procenjeni trošak', '€${appointment.estimatedCost}', Icons.euro),
                        if (appointment.actualCost != null)
                          _buildDetailRow('Stvarni trošak', '€${appointment.actualCost}', Icons.payment),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Zatvori',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditAppointmentDialog(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Uredi',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showFinishConfirmation(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Završi',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uređivanje termina će biti implementirano uskoro'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showFinishConfirmation(Appointment appointment) {
    final initialCost = appointment.actualCost ?? appointment.estimatedCost;
    final actualCostController = TextEditingController(
      text: initialCost?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: appointment.notes ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final isPaid = appointment.isPaid || (appointment.paymentMethod != null && appointment.paymentMethod!.isNotEmpty);
    
    debugPrint('🔍 Appointment payment status check:');
    debugPrint('   Appointment ID: ${appointment.id}');
    debugPrint('   Appointment Number: ${appointment.appointmentNumber}');
    debugPrint('   isPaid (flag): ${appointment.isPaid}');
    debugPrint('   paymentMethod: ${appointment.paymentMethod}');
    debugPrint('   paymentDate: ${appointment.paymentDate}');
    debugPrint('   Final isPaid check: $isPaid');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E8), Color(0xFFF0F8F0)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.green,
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
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Završi Termin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Termin: ${appointment.appointmentNumber}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPaid) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade600, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PLAĆENO',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  if (appointment.paymentMethod != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${appointment.paymentMethod})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade600, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.attach_money, color: Colors.blue.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plaćeno: ${appointment.actualCost ?? appointment.estimatedCost ?? 0} KM',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          const Text(
                            'Unesite finalne detalje termina:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: actualCostController,
                            enabled: !isPaid, // Disable if already paid
                            decoration: InputDecoration(
                              labelText: isPaid ? 'Stvarni trošak (KM) - Već plaćeno' : 'Stvarni trošak (KM)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.attach_money),
                              helperText: isPaid 
                                ? 'Plaćeno ranije, cijena je zaključana' 
                                : 'Unesite finalni trošak termina',
                              filled: isPaid,
                              fillColor: isPaid ? Colors.grey.shade100 : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (isPaid) return null;
                              
                              if (value == null || value.isEmpty) {
                                return 'Molimo unesite stvarni trošak';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Molimo unesite valjan broj';
                              }
                              if (double.parse(value) < 0) {
                                return 'Trošak ne može biti negativan';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Finalne napomene',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                              helperText: 'Dodajte napomene o završenom terminu',
                            ),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Otkaži'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (!isPaid && !formKey.currentState!.validate()) {
                            return;
                          }
                          
                          final actualCost = isPaid ? null : (double.tryParse(actualCostController.text) ?? 0.0);
                          final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                          
                          Navigator.of(context).pop();
                          await _finishAppointment(appointment.id, actualCost: actualCost, notes: notes);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Završi Termin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finishAppointment(int appointmentId, {double? actualCost, String? notes}) async {
    try {
      print('✅ Finishing appointment $appointmentId with actualCost: $actualCost, notes: $notes');
      final apiClient = serviceLocator.apiClient;
      await apiClient.completeAppointment(appointmentId, actualCost: actualCost, notes: notes);
      print('✅ Appointment finished successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin je uspešno završen'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      print('❌ Error finishing appointment: $e');
      String errorMessage = 'Greška pri završavanju termina';
      
      if (e is ApiError) {
        errorMessage = e.message;
        if (e.statusCode != null) {
          if (e.statusCode == 403) {
            errorMessage = 'Nemate dozvolu za završavanje termina';
          } else if (e.statusCode == 404) {
            errorMessage = 'Termin nije pronađen';
          } else {
            errorMessage += ' (Status: ${e.statusCode})';
          }
        }
      } else {
        errorMessage = e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      print('🆕 Creating appointment with data: $appointmentData');
      print('📋 Detailed data breakdown:');
      appointmentData.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      
      final apiClient = serviceLocator.apiClient;
      final createdAppointment = await apiClient.createAppointment(appointmentData);
      print('✅ Appointment created successfully: ${createdAppointment.appointmentNumber}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin je uspešno kreiran'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the appointments list
        _loadAppointments();
      }
    } catch (e) {
      print('❌ Error creating appointment: $e');
      print('❌ Error type: ${e.runtimeType}');
      String errorMessage = 'Greška pri kreiranju termina';
      
      if (e is ApiError) {
        errorMessage = e.message;
        print('❌ API Error details: message=${e.message}, statusCode=${e.statusCode}');
        if (e.statusCode != null && e.statusCode != 400) {
          errorMessage += ' (Status: ${e.statusCode})';
        }
      } else {
        errorMessage = e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                        : 'Izaberite datum',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null 
                          ? const Color(0xFF2E7D32) 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required TimeOfDay? selectedTime,
    required ValueChanged<TimeOfDay?> onTimeSelected,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          onTimeSelected(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedTime != null
                        ? selectedTime.format(context)
                        : 'Izaberite vreme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedTime != null 
                          ? const Color(0xFF2E7D32) 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.access_time,
              color: Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAppointmentDialog() {
    // Refresh pets so newly added patients appear in the dropdown
    _loadPets();
    final appointmentDateController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    final estimatedCostController = TextEditingController();
    final petIdController = TextEditingController();
    final veterinarianIdController = TextEditingController(text: _currentUserId?.toString() ?? '');
    
    // Postavi početni izbor za dropdown
    if (widget.userRole == UserRole.veterinarian) {
      // Za veterinare, automatski postavi trenutno ulogovanog korisnika
      _selectedVeterinarianId = _currentUserId;
    } else {
      // Za admin, koristi postojeću logiku
      _selectedVeterinarianId = int.tryParse(veterinarianIdController.text);
    }
    final serviceIdController = TextEditingController();
    
    // Tip termina i status se podrazumijevano tretiraju kao "zakazan pregled"
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8F5E8),
                      Color(0xFFF0F8F0),
                    ],
                  ),
                ),
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Color(0xFF2E7D32),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Novi Termin',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Date picker
                            _buildDatePicker(
                              label: 'Datum termina',
                              icon: Icons.calendar_today,
                              selectedDate: selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  selectedDate = date;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Time pickers
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePicker(
                                    label: 'Početak',
                                    icon: Icons.access_time,
                                    selectedTime: selectedStartTime,
                                    onTimeSelected: (time) {
                                      setState(() {
                                        selectedStartTime = time;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePicker(
                                    label: 'Kraj',
                                    icon: Icons.access_time,
                                    selectedTime: selectedEndTime,
                                    onTimeSelected: (time) {
                                      setState(() {
                                        selectedEndTime = time;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Uklonjeno: Tip termina i Status (podrazumijevano: zakazan)
                            const SizedBox(height: 16),
                            
                            // Pet (dropdown) and Veterinarian ID
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: petIdController.text.isNotEmpty
                                        ? int.tryParse(petIdController.text)
                                        : null,
                                    items: _pets.map((pet) {
                                      return DropdownMenuItem<int>(
                                        value: pet.id,
                                        child: Text('${pet.name} (${pet.species})'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      petIdController.text = value?.toString() ?? '';
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Pacijent',
                                      prefixIcon: Icon(Icons.pets, color: Color(0xFF2E7D32)),
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Molimo izaberite pacijenta';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Veterinar dropdown - samo za admin
                                if (widget.userRole == UserRole.admin) ...[
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: (_selectedVeterinarianId != null &&
                                              _veterinarians.any((v) => v['id'] == _selectedVeterinarianId))
                                          ? _selectedVeterinarianId
                                          : null,
                                      items: _veterinarians.map((v) {
                                        return DropdownMenuItem<int>(
                                          value: v['id'] as int?,
                                          child: Text('${v['firstName']} ${v['lastName']}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedVeterinarianId = value;
                                          veterinarianIdController.text = value?.toString() ?? '';
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Veterinar',
                                        prefixIcon: Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Molimo izaberite veterinara';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ] else ...[
                                  // Za veterinare - prikaži trenutno ulogovanog veterinara
                                  Expanded(
                                    child: TextFormField(
                                      controller: TextEditingController(
                                        text: _veterinarians.isNotEmpty && _currentUserId != null
                                            ? _veterinarians
                                                .firstWhere((v) => v['id'] == _currentUserId, orElse: () => {})
                                                .isNotEmpty
                                                ? '${_veterinarians.firstWhere((v) => v['id'] == _currentUserId)['firstName']} ${_veterinarians.firstWhere((v) => v['id'] == _currentUserId)['lastName']}'
                                                : 'Trenutno ulogovani veterinar'
                                            : 'Trenutno ulogovani veterinar'
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Veterinar',
                                        prefixIcon: Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                                      ),
                                      enabled: false, // Read-only
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Service (dropdown) and Estimated Cost (auto-fill)
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: serviceIdController.text.isNotEmpty
                                        ? int.tryParse(serviceIdController.text)
                                        : null,
                                    items: _services.map((s) {
                                      return DropdownMenuItem<int>(
                                        value: s['id'] as int?,
                                        child: Text(s['name']?.toString() ?? 'Usluga'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      serviceIdController.text = value?.toString() ?? '';
                                      final selected = _services.firstWhere(
                                        (s) => s['id'] == value,
                                        orElse: () => {},
                                      );
                                      final price = (selected['price']?.toString()) ?? '';
                                      estimatedCostController.text = price;
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Usluga',
                                      prefixIcon: Icon(Icons.medical_information, color: Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: estimatedCostController,
                                    label: 'Procijenjeni trošak',
                                    icon: Icons.payments,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Reason and Notes
                            _buildTextField(
                              controller: reasonController,
                              label: 'Razlog',
                              icon: Icons.description,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: notesController,
                              label: 'Napomene',
                              icon: Icons.note,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              'Otkaži',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              // Validacija obaveznih polja
                              if (selectedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Molimo izaberite datum termina'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (selectedStartTime == null || selectedEndTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Molimo izaberite vreme početka i kraja'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (petIdController.text.isEmpty || veterinarianIdController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Molimo izaberite pacijenta i unesite ID veterinara (automatski popunjeno ako ste ulogovani).'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Formatiraj vreme kao HH:mm string
                              String two(int n) => n.toString().padLeft(2, '0');
                              final startTimeStr = '${two(selectedStartTime!.hour)}:${two(selectedStartTime!.minute)}';
                              final endTimeStr = '${two(selectedEndTime!.hour)}:${two(selectedEndTime!.minute)}';
                              
                              print('🕐 Time formatting debug:');
                              print('  selectedStartTime: ${selectedStartTime!.hour}:${selectedStartTime!.minute}');
                              print('  selectedEndTime: ${selectedEndTime!.hour}:${selectedEndTime!.minute}');
                              print('  startTimeStr: "$startTimeStr"');
                              print('  endTimeStr: "$endTimeStr"');

                              // Tip termina: podrazumijevano koristimo Checkup (1)
                              int typeValue = 1;

                              await _createAppointment({
                                'appointmentDate': selectedDate!.toIso8601String(),
                                'startTime': startTimeStr,
                                'endTime': endTimeStr,
                                'type': typeValue,
                                'reason': reasonController.text.isEmpty ? null : reasonController.text,
                                'notes': notesController.text.isEmpty ? null : notesController.text,
                                'estimatedCost': estimatedCostController.text.isEmpty ? null : double.tryParse(estimatedCostController.text),
                                'petId': int.parse(petIdController.text),
                                'veterinarianId': int.parse(veterinarianIdController.text),
                                'serviceId': serviceIdController.text.isEmpty ? null : int.tryParse(serviceIdController.text),
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Kreiraj Termin',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Greška: $_error',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userRole == UserRole.admin ? 'Svi Termini' : 'Moji Termini',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
            tooltip: 'Ažuriraj podatke',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 32,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 12),
              Text(
                widget.userRole == UserRole.admin ? 'Svi Termini' : 'Moji Termini',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddAppointmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Novi Termin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadAppointments,
                icon: const Icon(Icons.refresh),
                tooltip: 'Osveži',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter controls
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      _filterAppointmentsByDate(date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Text(
                          _filterDate != null 
                              ? 'Filtrirano: ${_filterDate!.day}.${_filterDate!.month}.${_filterDate!.year}'
                              : 'Filtriraj po datumu',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        if (_filterDate != null)
                          IconButton(
                            onPressed: () => _filterAppointmentsByDate(null),
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: 'Ukloni filter',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ukupno: ${_filteredAppointments.length} termina',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar and appointments
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Smanjena visina da se izbjegne overflow
                final double computedHeight = (constraints.maxWidth / 1.2)
                    .clamp(600.0, 1000.0);
                return SizedBox(
                  height: computedHeight,
                  child: CalendarWidget(
                    appointments: _filteredAppointments,
                    userRole: widget.userRole,
                    onDateSelected: _onDateSelected,
                    onAppointmentSelected: _onAppointmentSelected,
                    initialSelectedDay: _selectedDate ?? _filterDate,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        ),
      ),
    );
  }
}



