import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import '../models/user.dart';

class CalendarWidget extends StatefulWidget {
  final List<Appointment> appointments;
  final UserRole userRole;
  final Function(DateTime)? onDateSelected;
  final Function(Appointment)? onAppointmentSelected;
  final DateTime? initialSelectedDay;

  const CalendarWidget({
    Key? key,
    required this.appointments,
    required this.userRole,
    this.onDateSelected,
    this.onAppointmentSelected,
    this.initialSelectedDay,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late final ValueNotifier<List<Appointment>> _selectedAppointments;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialSelectedDay ?? DateTime.now();
    _focusedDay = _selectedDay!;
    _selectedAppointments = ValueNotifier(_getAppointmentsForDay(_selectedDay!));
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update appointments when the widget is rebuilt
    _selectedAppointments.value = _getAppointmentsForDay(_selectedDay!);
  }

  @override
  void dispose() {
    _selectedAppointments.dispose();
    super.dispose();
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return widget.appointments.where((appointment) {
      return isSameDay(appointment.appointmentDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedAppointments.value = _getAppointmentsForDay(selectedDay);
      
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(selectedDay);
      }
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.yellow.shade600; // Nadolazeci - žuta
      case AppointmentStatus.confirmed:
        return Colors.yellow.shade600; // Nadolazeci - žuta
      case AppointmentStatus.inProgress:
        return Colors.orange.shade600; // U toku - narandžasta
      case AppointmentStatus.completed:
        return Colors.red.shade600; // Završeni - crvena
      case AppointmentStatus.cancelled:
        return Colors.red.shade600; // Otkazani - crvena
      case AppointmentStatus.noShow:
        return Colors.red.shade600; // Nije se pojavio - crvena
      case AppointmentStatus.rescheduled:
        return Colors.yellow.shade600; // Prebačeni - žuta
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Zakazan';
      case AppointmentStatus.confirmed:
        return 'Potvrđen';
      case AppointmentStatus.inProgress:
        return 'U toku';
      case AppointmentStatus.completed:
        return 'Završen';
      case AppointmentStatus.cancelled:
        return 'Otkazan';
      case AppointmentStatus.noShow:
        return 'Nije se pojavio';
      case AppointmentStatus.rescheduled:
        return 'Prebačen';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Juni',
      'Juli', 'August', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.white,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Calendar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                ),
                Column(
                  children: [
                    Text(
                      _getMonthName(_focusedDay.month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_focusedDay.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // Modern Calendar Body
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: TableCalendar<Appointment>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                eventLoader: _getAppointmentsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerVisible: false, // We have our own header
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                  defaultTextStyle: const TextStyle(
                    fontSize: 12, // Još manji font size
                    fontWeight: FontWeight.w500,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange.shade400.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                  markersMaxCount: 3,
                  cellMargin: const EdgeInsets.all(0.2), // MINIMALNI margin
                  cellPadding: const EdgeInsets.all(0.5), // MINIMALNI padding
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, day, focusedDay) {
                    final appointments = _getAppointmentsForDay(day);
                    Color backgroundColor = const Color(0xFF2E7D32);
                    
                    if (appointments.isNotEmpty) {
                      // Prioritet boja: crvena > narandžasta > žuta > zelena
                      bool hasCompleted = appointments.any((a) => 
                        a.status == AppointmentStatus.completed ||
                        a.status == AppointmentStatus.cancelled ||
                        a.status == AppointmentStatus.noShow);
                      bool hasInProgress = appointments.any((a) => 
                        a.status == AppointmentStatus.inProgress);
                      bool hasScheduled = appointments.any((a) => 
                        a.status == AppointmentStatus.scheduled ||
                        a.status == AppointmentStatus.confirmed ||
                        a.status == AppointmentStatus.rescheduled);
                      
                      if (hasCompleted) {
                        backgroundColor = Colors.red.shade600;
                      } else if (hasInProgress) {
                        backgroundColor = Colors.orange.shade600;
                      } else if (hasScheduled) {
                        backgroundColor = Colors.yellow.shade600;
                      }
                    }
                    
                    return Container(
                      margin: const EdgeInsets.fromLTRB(0, 1, 0, 1), // MINIMALNI margin
                      width: 40, // MANJI prikaz
                      height: 40, // MANJA visina
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8), // ✅ kockasto sa zaobljenim uglovima
                        border: Border.all(
                          color: backgroundColor.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, day, appointments) {
                    if (appointments.isEmpty) return null;
                    
                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: appointments.take(3).map((appointment) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Appointments List for Selected Day
          Expanded(
            flex: 2,
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Selected Date Header
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDay != null
                            ? '${_selectedDay!.day}. ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}'
                            : 'Izaberite datum',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<List<Appointment>>(
                        valueListenable: _selectedAppointments,
                        builder: (context, appointments, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${appointments.length} termina',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Appointments List
                Expanded(
                  child: ValueListenableBuilder<List<Appointment>>(
                    valueListenable: _selectedAppointments,
                    builder: (context, appointments, _) {
                      if (appointments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nema termina za ovaj datum',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(appointment.status).withOpacity(0.1),
                                  _getStatusColor(appointment.status).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getStatusColor(appointment.status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                '${appointment.startTime} - ${appointment.endTime}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment.petName ?? 'Nepoznat pacijent',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    appointment.typeText,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(appointment.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                if (widget.onAppointmentSelected != null) {
                                  widget.onAppointmentSelected!(appointment);
                                }
                              },
                            ),
                          );
                        },
                      );
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
}