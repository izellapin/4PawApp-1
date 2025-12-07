import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_appointment_screen.dart';

class MobileAppointmentsListScreen extends StatefulWidget {
  const MobileAppointmentsListScreen({super.key});

  @override
  State<MobileAppointmentsListScreen> createState() => _MobileAppointmentsListScreenState();
}

class _MobileAppointmentsListScreenState extends State<MobileAppointmentsListScreen> with WidgetsBindingObserver {
  Future<List<Appointment>>? _appointmentsFuture;
  Key _futureBuilderKey = UniqueKey(); // Key za FutureBuilder refresh
  Set<int> _reviewedAppointments = {}; // Track appointments that have been reviewed
  Set<int> _reviewedVeterinarians = {}; // Track veterinarians that have been reviewed
  Set<int> _reviewedVeterinariansLocal = {}; // Local state for immediate UI update after review

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReviewedAppointments();
    _loadReviewedVeterinarians();
    _appointmentsFuture = _loadMyAppointments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatski refresh kada se aplikacija vrati u foreground
    if (state == AppLifecycleState.resumed) {
      print('🔄 [LIFECYCLE] App resumed, refreshing appointments...');
      _refreshAppointments();
    }
  }

  Future<void> _loadReviewedAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewedIds = prefs.getStringList('reviewed_appointments') ?? [];
      setState(() {
        _reviewedAppointments = reviewedIds.map((id) => int.parse(id)).toSet();
      });
    } catch (e) {
      print('❌ Error loading reviewed appointments: $e');
    }
  }

  Future<void> _saveReviewedAppointment(int appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reviewedAppointments.add(appointmentId);
      final reviewedIds = _reviewedAppointments.map((id) => id.toString()).toList();
      await prefs.setStringList('reviewed_appointments', reviewedIds);
    } catch (e) {
      print('❌ Error saving reviewed appointment: $e');
    }
  }

  Future<void> _loadReviewedVeterinarians() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewedVetIds = prefs.getStringList('reviewed_veterinarians') ?? [];
      setState(() {
        _reviewedVeterinarians = reviewedVetIds.map((id) => int.parse(id)).toSet();
      });
    } catch (e) {
      print('❌ Error loading reviewed veterinarians: $e');
    }
  }

  Future<void> _saveReviewedVeterinarian(int veterinarianId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reviewedVeterinarians.add(veterinarianId);
      final reviewedIds = _reviewedVeterinarians.map((id) => id.toString()).toList();
      await prefs.setStringList('reviewed_veterinarians', reviewedIds);
    } catch (e) {
      print('❌ Error saving reviewed veterinarian: $e');
    }
  }

  Future<void> _refreshAppointments() async {
    print('🔄 [REFRESH] Refreshing appointments list...');
    final newFuture = _loadMyAppointments();
    setState(() {
      // Kreiraj novi Future da bi FutureBuilder osvežio
      _appointmentsFuture = newFuture;
      // Promeni key da bi FutureBuilder osvežio
      _futureBuilderKey = UniqueKey();
    });
    // Sačekaj da se podaci učitaju
    await newFuture;
    print('✅ [REFRESH] Appointments refreshed successfully');
  }

  // Public metoda za refresh koja se može pozvati iz parent widget-a
  void refreshAppointments() {
    _refreshAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji termini'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookAppointmentScreen(onAppointmentBooked: _refreshAppointments),
                ),
              );
              // Refresh nakon vraćanja sa BookAppointmentScreen (ako je termin kreiran)
              if (result == true) {
                print('🔄 [APPOINTMENTS LIST] Appointment was created, refreshing list');
                _refreshAppointments();
              } else {
                print('🔄 [APPOINTMENTS LIST] No appointment created, refreshing anyway');
                _refreshAppointments();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Appointment>>(
        key: _futureBuilderKey, // Koristi key za refresh
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Greška: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAppointments,
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }
          
          final appointments = snapshot.data ?? [];
          
          // Check for recently completed appointments and show review dialog
          if (appointments.isNotEmpty && snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndShowReviewDialog(appointments);
            });
          }
          
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nemate zakazane termine',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zakažite svoj prvi termin za pregled vašeg ljubimca',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentScreen(onAppointmentBooked: _refreshAppointments),
                        ),
                      );
                      // Refresh nakon vraćanja sa BookAppointmentScreen
                      _refreshAppointments();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Zakaži termin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Group appointments by status
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Historija: SVI otkazani i završeni termini (bez obzira na datum)
          final pastAppointments = appointments.where((apt) {
            final isCompletedOrCancelled = apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.cancelled;
            // Uklonjena provera datuma - completed/cancelled termini idu u historiju bez obzira na datum
            if (isCompletedOrCancelled) {
              print('📅 [HISTORIJA] Appointment ${apt.id}: ${apt.appointmentDate} - Status: ${apt.status}');
            }
            return isCompletedOrCancelled;
          }).toList()..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
          
          // Rezervisani termini dolazeći: budući termini koji NISU completed i NISU cancelled
          final upcomingAppointments = appointments.where((apt) {
            final appointmentDateOnly = DateTime(apt.appointmentDate.year, apt.appointmentDate.month, apt.appointmentDate.day);
            final isFuture = appointmentDateOnly.isAfter(today);
            final isNotCancelled = apt.status != AppointmentStatus.cancelled;
            final isNotCompleted = apt.status != AppointmentStatus.completed;
            final shouldInclude = isFuture && isNotCancelled && isNotCompleted;
            if (shouldInclude) {
              print('📅 [REZERVISANI] Appointment ${apt.id}: ${apt.appointmentDate} - Status: ${apt.status}');
            } else if (!isFuture) {
              print('📅 [FILTERED OUT] Appointment ${apt.id}: ${apt.appointmentDate} - Status: ${apt.status} (past date)');
            } else if (apt.status == AppointmentStatus.cancelled) {
              print('📅 [FILTERED OUT] Appointment ${apt.id}: ${apt.appointmentDate} - Status: ${apt.status} (cancelled)');
            } else if (apt.status == AppointmentStatus.completed) {
              print('📅 [FILTERED OUT] Appointment ${apt.id}: ${apt.appointmentDate} - Status: ${apt.status} (completed)');
            }
            return shouldInclude;
          }).toList()..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
          
          print('📊 [SUMMARY] Total appointments: ${appointments.length}');
          print('📊 [SUMMARY] Historija (completed/cancelled, bez obzira na datum): ${pastAppointments.length}');
          print('📊 [SUMMARY] Rezervisani dolazeći (future, not completed, not cancelled): ${upcomingAppointments.length}');
          
          return RefreshIndicator(
            onRefresh: _refreshAppointments,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              // Historija termina sekcija
              if (pastAppointments.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Historija vaših termina',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...pastAppointments.take(3).map((appointment) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(appointment.appointmentDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${appointment.startTime} - ${appointment.endTime}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.pets, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(appointment.petName ?? 'Nepoznato'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(appointment.veterinarianName ?? 'Nepoznato'),
                                ],
                              ),
                              if (appointment.serviceName != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.medical_services, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(appointment.serviceName!),
                                  ],
                                ),
                              ],
                              if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        appointment.reason!,
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (appointment.estimatedCost != null && appointment.estimatedCost! > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${appointment.estimatedCost!.toStringAsFixed(2)} KM',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: appointment.status != AppointmentStatus.cancelled
                                    ? (_reviewedVeterinariansLocal.contains(appointment.veterinarianId)
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 18),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ocjenjeno',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          )
                                        : FutureBuilder<bool>(
                                            future: serviceLocator.apiClient.hasReviewForVeterinarian(appointment.veterinarianId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox.shrink();
                                              }
                                              final hasReview = snapshot.data ?? false;
                                              
                                              // Ako postoji review u bazi, dodaj u lokalni state
                                              if (hasReview && !_reviewedVeterinariansLocal.contains(appointment.veterinarianId)) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _reviewedVeterinariansLocal.add(appointment.veterinarianId);
                                                    });
                                                  }
                                                });
                                              }
                                              
                                              return hasReview
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.star, color: Colors.amber, size: 18),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Ocjenjeno',
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : TextButton.icon(
                                                      onPressed: () => _showRateVeterinarianDialog(appointment),
                                                      icon: const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                                      label: const Text('Ocijeni'),
                                                    );
                                            },
                                          ))
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                      if (pastAppointments.length > 3) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAllPastAppointments(pastAppointments),
                            icon: const Icon(Icons.history, size: 18),
                            label: Text('Prikaži sve termine (${pastAppointments.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Rezervisani termini dolazeći sekcija
              if (upcomingAppointments.isNotEmpty) ...[
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
                          Icon(Icons.calendar_today, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Rezervisani termini dolazeći',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...upcomingAppointments.map((appointment) => 
                        _buildAppointmentCard(appointment, isUpcoming: true)
                      ),
                    ],
                  ),
                ),
              ],
            ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAppointmentCard(Appointment appointment, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(appointment.status),
                    child: Icon(
                      _getStatusIcon(appointment.status),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.typeText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text('${appointment.formattedDate} - ${appointment.timeRange}'),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                appointment.statusText,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
                            ),
                            if (appointment.isPaid) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade600, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PLAĆENO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isUpcoming && appointment.status == AppointmentStatus.scheduled)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'cancel':
                                  _showCancelConfirmation(appointment);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'cancel',
                                child: ListTile(
                                  leading: Icon(Icons.cancel, color: Colors.red),
                                  title: Text('Otkaži termin', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                            child: const Icon(Icons.more_vert),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (appointment.petName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Pacijent: ${appointment.petName}'),
                ),
              if (appointment.veterinarianName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Veterinar: ${appointment.veterinarianName}'),
                ),
              if (appointment.reason != null && appointment.reason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Razlog: ${appointment.reason}'),
                ),
              if (appointment.estimatedCost != null && appointment.estimatedCost! > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Cijena: ${appointment.estimatedCost!.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (!isUpcoming && appointment.status != AppointmentStatus.cancelled) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _reviewedVeterinariansLocal.contains(appointment.veterinarianId)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Ocjenjeno',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : FutureBuilder<bool>(
                          future: serviceLocator.apiClient.hasReviewForVeterinarian(appointment.veterinarianId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            final hasReview = snapshot.data ?? false;
                            
                            // Ako postoji review u bazi, dodaj u lokalni state
                            if (hasReview && !_reviewedVeterinariansLocal.contains(appointment.veterinarianId)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _reviewedVeterinariansLocal.add(appointment.veterinarianId);
                                  });
                                }
                              });
                            }
                            
                            return hasReview
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ocjenjeno',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton.icon(
                                    onPressed: () => _showRateVeterinarianDialog(appointment),
                                    icon: const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                    label: const Text('Ocijeni'),
                                  );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.hourglass_empty;
      case AppointmentStatus.completed:
        return Icons.done;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  
  Future<List<Appointment>> _loadMyAppointments() async {
    try {
      final authService = serviceLocator.authService;
      if (authService.currentUser == null) {
        print('❌ No current user found');
        return [];
      }
      
      final apiClient = serviceLocator.apiClient;
      final userRole = authService.currentUser!['role'] as int?;
      
      print('🔍 User role: $userRole (type: ${userRole.runtimeType})');
      print('🔍 Current user data: ${authService.currentUser}');
      
      if (userRole == 2) { // UserRole.Veterinarian = 2
        // Za veterinare koristi endpoint koji vraća njihove termine
        print('🔄 Loading appointments for veterinarian');
        final appointments = await apiClient.getMyAppointments();
        print('✅ Loaded ${appointments.length} appointments');
        return appointments;
      } else {
        // Za vlasnike ljubimaca koristi endpoint koji vraća njihove termine
        final userId = authService.currentUser!['id'] as int?;
        if (userId == null) {
          print('❌ User ID is null');
          return [];
        }
        
        print('🔄 Loading appointments for user ID: $userId');
        final appointments = await apiClient.getUserAppointments(userId);
        print('✅ Loaded ${appointments.length} appointments');
        return appointments;
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      throw e;
    }
  }
  
  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.typeText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Datum', appointment.formattedDate),
            _buildDetailRow('Vreme', appointment.timeRange),
            _buildDetailRow('Status', appointment.statusText),
            if (appointment.petName != null)
              _buildDetailRow('Pacijent', appointment.petName!),
            if (appointment.veterinarianName != null)
              _buildDetailRow('Veterinar', appointment.veterinarianName!),
            if (appointment.reason != null && appointment.reason!.isNotEmpty)
              _buildDetailRow('Razlog', appointment.reason!),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow('Napomene', appointment.notes!),
            if (appointment.estimatedCost != null)
              _buildDetailRow('Procenjena cena', '${appointment.estimatedCost} KM'),
            if (appointment.actualCost != null)
              _buildDetailRow('Finalna cena', '${appointment.actualCost} KM'),
          ],
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  void _showCancelConfirmation(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži termin'),
        content: Text('Da li ste sigurni da želite da otkažete termin za ${appointment.formattedDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ne'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelAppointment(appointment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Da, otkaži'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      final apiClient = serviceLocator.apiClient;
      await apiClient.cancelAppointment(appointmentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin je uspešno otkazan'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshAppointments(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri otkazivanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _checkAndShowReviewDialog(List<Appointment> appointments) async {
    // Find recently completed appointments (completed in the last 7 days)
    final now = DateTime.now();
    final recentlyCompleted = appointments.where((apt) {
      if (apt.status != AppointmentStatus.completed) return false;
      // Check if dialog was already shown for this appointment (to avoid showing multiple times)
      if (_reviewedAppointments.contains(apt.id)) return false;
      
      // Check if appointment was completed recently (within last 7 days)
      // Calculate appointment end time
      final timeParts = apt.endTime.split(':');
      final endHour = timeParts.length >= 1 ? int.tryParse(timeParts[0]) ?? 0 : 0;
      final endMinute = timeParts.length >= 2 ? int.tryParse(timeParts[1]) ?? 0 : 0;
      
      final appointmentEndTime = DateTime(
        apt.appointmentDate.year,
        apt.appointmentDate.month,
        apt.appointmentDate.day,
        endHour,
        endMinute,
      );
      
      // Check if appointment ended in the last 7 days
      final daysSinceCompletion = now.difference(appointmentEndTime).inDays;
      return daysSinceCompletion >= 0 && daysSinceCompletion <= 7;
    }).toList();
    
    // Show review dialog for the most recent completed appointment
    if (recentlyCompleted.isNotEmpty) {
      // Sort by date (most recent first)
      recentlyCompleted.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      final appointmentToReview = recentlyCompleted.first;
      
      // Check if user already has review in database for this veterinarian
      try {
        final hasReview = await serviceLocator.apiClient.hasReviewForVeterinarian(appointmentToReview.veterinarianId);
        if (hasReview) {
          // User already reviewed this veterinarian, don't show dialog
          return;
        }
      } catch (e) {
        print('❌ [REVIEW DIALOG] Error checking review: $e');
        // Continue to show dialog if check fails
      }
      
      // Mark that dialog was shown for this appointment (to avoid showing it again)
      await _saveReviewedAppointment(appointmentToReview.id);
      
      // Show dialog after a short delay to avoid showing it immediately on screen load
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showRateVeterinarianDialog(appointmentToReview);
        }
      });
    }
  }

  Future<void> _showRateVeterinarianDialog(Appointment appointment) async {
    int selectedRating = 5;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Ocijenite veterinara'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appointment.veterinarianName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(appointment.veterinarianName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filled = index < selectedRating;
                      return IconButton(
                        icon: Icon(filled ? Icons.star : Icons.star_border, color: filled ? const Color(0xFFFFC107) : Colors.grey),
                        onPressed: () => setStateDialog(() => selectedRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text('Ocjena: $selectedRating/5'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // NE dodavati u _reviewedAppointments - samo zatvori dialog
                    // Dialog će se ponovo prikazati kada korisnik uđe u listu termina
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Kasnije'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final api = serviceLocator.apiClient;
                      print('📤 [REVIEW] Creating review for veterinarian: ${appointment.veterinarianId}');
                      print('📤 [REVIEW] Rating: $selectedRating, Title: ${appointment.serviceName}, Comment: Ocjena nakon završenog termina');
                      
                      await api.createVeterinarianReview(
                        veterinarianId: appointment.veterinarianId,
                        rating: selectedRating,
                        petName: appointment.petName,
                        title: appointment.serviceName,
                        comment: 'Ocjena nakon završenog termina',
                        appointmentId: appointment.id,
                      );
                      
                      print('✅ [REVIEW] Review created successfully');
                      
                      if (mounted) {
                        // Odmah ažuriraj lokalni state da se prikaže "Ocjenjeno"
                        setState(() {
                          _reviewedVeterinariansLocal.add(appointment.veterinarianId);
                        });
                        
                        Navigator.of(ctx).pop();
                        // Refresh appointments to update UI
                        _refreshAppointments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hvala na ocjeni!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ [REVIEW ERROR] Full error: $e');
                      print('❌ [REVIEW ERROR] Error type: ${e.runtimeType}');
                      
                      if (mounted) {
                        final errorMessage = e.toString();
                        print('❌ [REVIEW ERROR] Error message: $errorMessage');
                        
                        // If user already reviewed this veterinarian
                        if (errorMessage.contains('Već ste ocjenili') || 
                            errorMessage.contains('already reviewed') ||
                            errorMessage.contains('Već ste ocjenili ovog veterinara')) {
                          Navigator.of(ctx).pop();
                          // Osvežiti listu da se prikaže "Ocjenjeno" (ako već postoji review u bazi)
                          _refreshAppointments();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Već ste ocjenili ovog veterinara'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          // Prikaži detaljnu grešku
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Greška pri ocjenjivanju: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  child: const Text('Pošalji'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showAllPastAppointments(List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Svi termini (${appointments.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAppointmentDetails(appointment);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: _getStatusColor(appointment.status),
                          radius: 20,
                          child: Icon(
                            _getStatusIcon(appointment.status),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.typeText,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${appointment.formattedDate} - ${appointment.timeRange}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (appointment.petName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Pacijent: ${appointment.petName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              if (appointment.veterinarianName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Veterinar: ${appointment.veterinarianName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              if (appointment.estimatedCost != null && appointment.estimatedCost! > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Cijena: ${appointment.estimatedCost!.toStringAsFixed(2)} KM',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Chip(
                              label: Text(
                                appointment.statusText,
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            if (appointment.status != AppointmentStatus.cancelled) ...[
                              const SizedBox(height: 4),
                              _reviewedVeterinariansLocal.contains(appointment.veterinarianId)
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'Ocjenjeno',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : FutureBuilder<bool>(
                                      future: serviceLocator.apiClient.hasReviewForVeterinarian(appointment.veterinarianId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox.shrink();
                                        }
                                        final hasReview = snapshot.data ?? false;
                                        
                                        // Ako postoji review u bazi, dodaj u lokalni state
                                        if (hasReview && !_reviewedVeterinariansLocal.contains(appointment.veterinarianId)) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (mounted) {
                                              setState(() {
                                                _reviewedVeterinariansLocal.add(appointment.veterinarianId);
                                              });
                                            }
                                          });
                                        }
                                        
                                        return hasReview
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 2),
                                                  const Text(
                                                    'Ocjenjeno',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _showRateVeterinarianDialog(appointment);
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.star, size: 14, color: const Color(0xFFFFC107)),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Ocijeni',
                                                      style: TextStyle(fontSize: 10),
                                                    ),
                                                  ],
                                                ),
                                              );
                                      },
                                    ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
}






