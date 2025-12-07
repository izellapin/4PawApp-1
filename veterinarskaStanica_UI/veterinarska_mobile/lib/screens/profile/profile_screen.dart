import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'package:veterinarska_shared/utils/validation_helpers.dart';
import '../auth/login_screen.dart';
import 'my_reviews_screen.dart';

class MobileProfileScreen extends StatefulWidget {
  const MobileProfileScreen({super.key});

  @override
  State<MobileProfileScreen> createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moj profil'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF2E7D32),
                            child: Text(
                              '${user['firstName']?[0] ?? ''}${user['lastName']?[0] ?? ''}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user['firstName'] != null && user['lastName'] != null
                                ? '${user['firstName']} ${user['lastName']}'
                                : 'Korisnik',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              _getRoleText(UserRole.values.firstWhere(
                                (role) => role.toString().split('.').last == user['role'],
                                orElse: () => UserRole.petOwner,
                              )),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Profile information
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Korisničko ime'),
                          subtitle: Text(user['username'] ?? ''),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: (user['isEmailVerified'] == true)
                              ? const Icon(Icons.verified, color: Colors.green)
                              : const Icon(Icons.warning, color: Colors.orange),
                        ),
                        if (user['phoneNumber'] != null) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Telefon'),
                            subtitle: Text(user['phoneNumber']!),
                          ),
                        ],
                        if (user['address'] != null) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Adresa'),
                            subtitle: Text(user['address']!),
                          ),
                        ],
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Član od'),
                          subtitle: Text(
                            user['dateCreated'] != null
                                ? _formatDate(user['dateCreated'])
                                : 'Nepoznato',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Uredi profil'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showEditProfileDialog();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.rate_review),
                          title: const Text('Moje recenzije'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyReviewsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifikacije'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showNotificationsSettings();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Pomoć i podrška'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showHelpAndSupport();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('O aplikaciji'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showAboutDialog(),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Odjavi se',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _showLogoutConfirmation(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
  
  
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Nepoznato';
    
    DateTime date;
    if (dateValue is String) {
      date = DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      return 'Nepoznato';
    }
    
    return '${date.day}.${date.month}.${date.year}';
  }
  
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.petOwner:
        return 'Vlasnik ljubimca';
      case UserRole.veterinarian:
        return 'Veterinar';
      case UserRole.veterinaryTechnician:
        return 'Veterinarski tehničar';
      case UserRole.receptionist:
        return 'Recepcioner';
      case UserRole.admin:
        return 'Administrator';
    }
  }
  
  
  void _showEditProfileDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) return;
    
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: user['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user['lastName'] ?? '');
    final phoneController = TextEditingController(text: user['phoneNumber'] ?? '');
    final addressController = TextEditingController(text: user['address'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi profil'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ime',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => ValidationHelpers.validateRequired(value, 'ime'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Prezime',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => ValidationHelpers.validateRequired(value, 'prezime'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                  helperText: 'Format: +387 33 123 456 ili 061 123 456',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => ValidationHelpers.validatePhone(value, required: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresa',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final authService = Provider.of<AuthService>(context, listen: false);
              try {
                await authService.updateProfile(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil je uspješno ažuriran. Sve promjene su sačuvane.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Greška pri ažuriranju profila: $e'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Email notifikacije'),
              subtitle: const Text('Primaj notifikacije na email'),
              value: true,
              onChanged: (value) {
                // TODO: Implement email notifications toggle
              },
            ),
            SwitchListTile(
              title: const Text('Push notifikacije'),
              subtitle: const Text('Primaj push notifikacije'),
              value: true,
              onChanged: (value) {
                // TODO: Implement push notifications toggle
              },
            ),
            SwitchListTile(
              title: const Text('Termini'),
              subtitle: const Text('Notifikacije o terminima'),
              value: true,
              onChanged: (value) {
                // TODO: Implement appointment notifications toggle
              },
            ),
            SwitchListTile(
              title: const Text('Ljubimci'),
              subtitle: const Text('Notifikacije o ljubimcima'),
              value: true,
              onChanged: (value) {
                // TODO: Implement pet notifications toggle
              },
            ),
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

  void _showHelpAndSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomoć i podrška'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontakt informacije:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('📞 Telefon: +387 33 123 456'),
            const SizedBox(height: 8),
            const Text('📧 Email: info@4paw.ba'),
            const SizedBox(height: 8),
            const Text('🌐 Website: www.4paw.ba'),
            const SizedBox(height: 16),
            const Text(
              'Radno vrijeme:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Ponedjeljak - Petak: 08:00 - 18:00'),
            const Text('Subota: 08:00 - 14:00'),
            const Text('Nedjelja: Zatvoreno'),
            const SizedBox(height: 16),
            const Text(
              'Hitna pomoć:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('📞 +387 33 999 888'),
            const Text('(24/7 dostupno)'),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O aplikaciji'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4Paw Veterinary Clinic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text('Verzija: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Mobilna aplikacija za vlasnike ljubimaca koja omogućava:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Registraciju i upravljanje ljubimcima'),
            Text('• Zakazivanje termina kod veterinara'),
            Text('• Pregled istorije termina'),
            Text('• Upravljanje profilom'),
            SizedBox(height: 16),
            Text(
              'Razvijeno za 4Paw Veterinary Clinic',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
  
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda odjave'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MobileLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );
  }
}






