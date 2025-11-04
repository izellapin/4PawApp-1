import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';
import 'add_pet_screen.dart';

class MobilePetsListScreen extends StatefulWidget {
  const MobilePetsListScreen({super.key});

  @override
  State<MobilePetsListScreen> createState() => _MobilePetsListScreenState();
}

class _MobilePetsListScreenState extends State<MobilePetsListScreen> {
  Future<List<Pet>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadMyPets();
  }

  Future<void> _refreshPets() async {
    setState(() {
      _petsFuture = _loadMyPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji ljubimci'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPetScreen(onPetAdded: _refreshPets),
                ),
              );
              // Refresh nakon vraćanja sa AddPetScreen
              _refreshPets();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Pet>>(
        future: _petsFuture,
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
                    onPressed: _refreshPets,
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }
          
          final pets = snapshot.data ?? [];
          
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nemate registrovane ljubimce',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dodajte svog prvog ljubimca da biste mogli zakazivati termine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPetScreen(onPetAdded: _refreshPets),
                        ),
                      );
                      // Refresh nakon vraćanja sa AddPetScreen
                      _refreshPets();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj ljubimca'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final imagePath = _petImageFor(pet);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    backgroundImage: imagePath != null ? AssetImage(imagePath) : null,
                    child: imagePath == null
                        ? Text(
                            pet.name[0],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(
                    pet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pet.species} - ${pet.breed ?? 'Nepoznata rasa'}'),
                      Text(
                        '${pet.genderText} • ${pet.ageText}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          _showPetDetails(pet);
                          break;
                        case 'edit':
                          _editPet(pet);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(pet);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Detalji'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Uredi'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Obriši', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showPetDetails(pet),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String? _petImageFor(Pet pet) {
    final species = (pet.species ?? '').trim().toLowerCase();
    final name = (pet.name).trim().toLowerCase();

    // Any parrot uses rio.jpg regardless of name
    if (species.contains('papag') || species.contains('parrot')) {
      return 'assets/images/rio.jpg';
    }

    // Dogs: Rex -> rex.jpg; other dogs -> luna.jpg
    if (species.contains('pas') || species.contains('dog')) {
      if (name == 'rex') return 'assets/images/rex.jpg';
      return 'assets/images/luna.jpg';
    }

    return null;
  }
  
  Future<List<Pet>> _loadMyPets() async {
    try {
      final authService = serviceLocator.authService;
      if (authService.currentUser == null) {
        print('❌ No current user found');
        return [];
      }
      
      final apiClient = serviceLocator.apiClient;
      final userId = authService.currentUser!['id'] as int?;
      if (userId == null) {
        print('❌ User ID is null');
        return [];
      }
      
      print('🔄 Loading pets for user ID: $userId');
      final pets = await apiClient.getUserPets(userId);
      print('✅ Loaded ${pets.length} pets');
      return pets;
    } catch (e) {
      print('❌ Error loading pets: $e');
      throw e;
    }
  }
  
  void _showPetDetails(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pet.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Vrsta', pet.species),
            _buildDetailRow('Rasa', pet.breed ?? 'Nepoznata'),
            _buildDetailRow('Pol', pet.genderText),
            _buildDetailRow('Starost', pet.ageText),
            if (pet.weight != null)
              _buildDetailRow('Težina', '${pet.weight} kg'),
            if (pet.color != null)
              _buildDetailRow('Boja', pet.color!),
            if (pet.microchipNumber != null)
              _buildDetailRow('Mikročip', pet.microchipNumber!),
            if (pet.notes != null && pet.notes!.isNotEmpty)
              _buildDetailRow('Napomene', pet.notes!),
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
            width: 80,
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
  
  void _editPet(Pet pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPetScreen(
          onPetAdded: _refreshPets,
          petToEdit: pet,
        ),
      ),
    );
    // Refresh nakon vraćanja sa edit screen
    _refreshPets();
  }
  
  void _showDeleteConfirmation(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite da obrišete pacijenta "${pet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePet(pet.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePet(int petId) async {
    try {
      final apiClient = serviceLocator.apiClient;
      await apiClient.deletePet(petId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ljubimac je uspešno obrisan'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshPets(); // Koristi refresh funkciju
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri brisanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}






