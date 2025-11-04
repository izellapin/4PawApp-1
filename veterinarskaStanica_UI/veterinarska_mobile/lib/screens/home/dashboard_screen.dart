import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import '../appointments/book_appointment_screen.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('4Paw'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with dimmed background image
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(0),
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image with opacity
                  Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/images/pets_group.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay for better text contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2E7D32).withOpacity(0.75),
                          const Color(0xFF4CAF50).withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Text content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Dobrodošli u 4Paw',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vaši ljubimci zaslužuju najbolju negu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Dobrodošli, ${user?['firstName'] ?? 'Korisniče'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Action - Book Appointment
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookAppointmentScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_circle, size: 24),
                label: const Text(
                  'Zakaži termin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // Services Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Naše usluge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Services Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Manji aspect ratio => veća visina kartice (više prostora za tekst)
                    childAspectRatio: 0.9,
                    children: [
                      _buildServiceCard(
                        'Pregledi',
                        Icons.medical_services,
                        '',
                        const Color(0xFF4CAF50),
                      ),
                      _buildServiceCard(
                        'Stomatologija',
                        Icons.medical_services_outlined,
                        '',
                        const Color(0xFF2196F3),
                      ),
                      _buildServiceCard(
                        'Čišćenje',
                        Icons.content_cut,
                        '',
                        const Color(0xFFFF9800),
                      ),
                      _buildServiceCard(
                        'Hitna pomoć',
                        Icons.emergency,
                        '',
                        const Color(0xFFF44336),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Pet Gallery Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ljubimci koje liječimo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pet Gallery
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3, // 3 available images
                      itemBuilder: (context, index) {
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  // Pet image from assets
                                  Positioned.fill(
                                    child: Image.asset(
                                      _getPetImagePath(index),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Overlay with pet info
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        _getPetName(index),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Contact Info Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontakt informacije',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildContactItem(Icons.location_on, 'Sarajevo, BiH'),
                  _buildContactItem(Icons.phone, '+387 33 123 456'),
                  _buildContactItem(Icons.email, 'info@4paw.ba'),
                  _buildContactItem(Icons.access_time, 'Pon-Pet: 08:00-18:00'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiceCard(String title, IconData icon, String description, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to book appointment with service pre-selected
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookAppointmentScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
  
  String _getPetName(int index) {
    switch (index) {
      case 0:
        return 'Rex';
      case 1:
        return 'Luna';
      case 2:
        return 'Rio';
      default:
        return 'Ljubimac';
    }
  }
  
  String _getPetImagePath(int index) {
    switch (index) {
      case 0:
        return 'assets/images/rex.jpg';
      case 1:
        return 'assets/images/luna.jpg';
      case 2:
        return 'assets/images/rio.jpg';
      default:
        return 'assets/images/pets_group.jpg';
    }
  }
}






