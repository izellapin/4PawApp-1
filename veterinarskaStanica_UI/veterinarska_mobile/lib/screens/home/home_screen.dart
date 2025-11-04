import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../pets/pets_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const MobileDashboardScreen(),
    const MobilePetsListScreen(),
    const MobileAppointmentsListScreen(),
    const MobileProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Početna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Ljubimci',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Termini',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}






