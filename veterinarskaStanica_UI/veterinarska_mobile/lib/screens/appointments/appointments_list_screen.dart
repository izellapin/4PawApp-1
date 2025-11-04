import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'book_appointment_screen.dart';

class MobileAppointmentsListScreen extends StatefulWidget {
  const MobileAppointmentsListScreen({super.key});

  @override
  State<MobileAppointmentsListScreen> createState() => _MobileAppointmentsListScreenState();
}

class _MobileAppointmentsListScreenState extends State<MobileAppointmentsListScreen> {
  Future<List<Appointment>>? _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _loadMyAppointments();
  }

  Future<void> _refreshAppointments() async {
    setState(() {
      _appointmentsFuture = _loadMyAppointments();
    });
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
          ),
        ],
      ),
      body: FutureBuilder<List<Appointment>>(
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
          final upcomingAppointments = appointments.where((apt) => 
            apt.appointmentDate.isAfter(DateTime.now()) &&
            apt.status != AppointmentStatus.cancelled &&
            apt.status != AppointmentStatus.completed
          ).toList()..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
          
          final pastAppointments = appointments.where((apt) => 
            apt.appointmentDate.isBefore(DateTime.now()) ||
            apt.status == AppointmentStatus.completed ||
            apt.status == AppointmentStatus.cancelled
          ).toList()..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
          
          return ListView(
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
                                    ? TextButton.icon(
                                        onPressed: () => _showRateVeterinarianDialog(appointment),
                                        icon: const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                        label: const Text('Ocijeni'),
                                      )
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
              
              // Nadolazeći termini sekcija
              if (upcomingAppointments.isNotEmpty) ...[
                const Text(
                  'Nadolazeći termini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...upcomingAppointments.map((appointment) => 
                  _buildAppointmentCard(appointment, isUpcoming: true)
                ),
                const SizedBox(height: 24),
              ],
            ],
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
                  Column(
                    children: [
                      Row(
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
                      if (!isUpcoming && appointment.status != AppointmentStatus.cancelled)
                        TextButton.icon(
                          onPressed: () => _showRateVeterinarianDialog(appointment),
                          icon: const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                          label: const Text('Ocijeni'),
                        ),
                    ],
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zatvori'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final api = serviceLocator.apiClient;
                      await api.createVeterinarianReview(
                        veterinarianId: appointment.veterinarianId,
                        rating: selectedRating,
                        petName: appointment.petName,
                        title: appointment.serviceName,
                        comment: 'Ocjena nakon završenog termina',
                      );
                      if (mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hvala na ocjeni!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Greška pri ocjenjivanju: $e'), backgroundColor: Colors.red),
                        );
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(appointment.status),
                    child: Icon(
                      _getStatusIcon(appointment.status),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    appointment.typeText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${appointment.formattedDate} - ${appointment.timeRange}'),
                      if (appointment.petName != null)
                        Text('Pacijent: ${appointment.petName}'),
                      if (appointment.veterinarianName != null)
                        Text('Veterinar: ${appointment.veterinarianName}'),
                      if (appointment.estimatedCost != null && appointment.estimatedCost! > 0)
                        Text(
                          'Cijena: ${appointment.estimatedCost!.toStringAsFixed(2)} KM',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          appointment.statusText,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
                      ),
                      if (appointment.status != AppointmentStatus.cancelled)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showRateVeterinarianDialog(appointment);
                          },
                          icon: const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                          label: const Text('Ocijeni'),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAppointmentDetails(appointment);
                  },
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






