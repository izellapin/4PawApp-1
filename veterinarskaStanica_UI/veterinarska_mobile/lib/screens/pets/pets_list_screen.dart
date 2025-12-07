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
  UniqueKey _futureBuilderKey = UniqueKey(); // Key za forsiranje rebuild FutureBuilder-a
  List<Pet>? _cachedPets; // Cache za trenutne pacijente - koristi se za optimistički update

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadMyPets();
  }

  Future<void> _refreshPets() async {
    print('🔄 [REFRESH] Refreshing pets list...');
    // Osveži podatke sa servera
    final newPetsFuture = _loadMyPets();
    setState(() {
      _futureBuilderKey = UniqueKey(); // Novi key da forsiraj rebuild
      _petsFuture = newPetsFuture;
      // Ne briši cache - koristi optimistički ažurirani cache dok čeka na novi rezultat
    });
    print('🔄 [REFRESH] setState called, FutureBuilder should rebuild with new key');
    // Sačekaj da se podaci učitaju i ažuriraj cache
    try {
      final pets = await newPetsFuture;
      if (mounted) {
        setState(() {
          _cachedPets = pets;
        });
        print('✅ [REFRESH] Cache updated with ${pets.length} pets');
      }
    } catch (e) {
      print('❌ [REFRESH] Error loading pets: $e');
      // Ignoriši greške, FutureBuilder će ih prikazati
    }
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
        key: _futureBuilderKey, // Key za forsiranje rebuild
        future: _petsFuture,
        builder: (context, snapshot) {
          // Ako snapshot još uvek čeka, koristi keširane podatke (optimistički update)
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_cachedPets != null) {
              print('📦 [BUILDER] Using cached pets while waiting: ${_cachedPets!.length}');
              return _buildPetsList(_cachedPets!);
            }
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            // Ako ima grešku, pokušaj da prikažeš cache ako postoji
            if (_cachedPets != null) {
              print('⚠️ [BUILDER] Error but using cached pets: ${_cachedPets!.length}');
              return _buildPetsList(_cachedPets!);
            }
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
          // Ažuriraj cache kada dobijemo nove podatke (bez setState jer smo u build fazi)
          if (snapshot.connectionState == ConnectionState.done && pets.isNotEmpty) {
            // Koristi WidgetsBinding.instance.addPostFrameCallback da ažuriraš cache nakon build faze
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _cachedPets != pets) {
                _cachedPets = pets;
                print('✅ [BUILDER] Updated cache with ${pets.length} pets from server');
              }
            });
          }
          
          return _buildPetsList(pets);
        },
      ),
    );
  }

  Widget _buildPetsList(List<Pet> pets) {
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
      // Koristi /pets/my endpoint koji automatski koristi ID iz tokena
      print('🔄 Loading pets for current user via /pets/my');
      final pets = await apiClient.getMyPets();
      print('✅ Loaded ${pets.length} pets');
      // Ažuriraj cache
      if (mounted) {
        _cachedPets = pets;
      }
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
      
      // Eksplicitno ukloni pacijenta iz cache-a pre poziva API-ja (optimistički update)
      List<Pet>? previousPets;
      if (_cachedPets != null) {
        previousPets = List.from(_cachedPets!);
        final updatedPets = _cachedPets!.where((p) => p.id != petId).toList();
        setState(() {
          _cachedPets = updatedPets; // Ažuriraj cache odmah
          _futureBuilderKey = UniqueKey(); // Forsiraj rebuild
          // Kreiraj novi Future koji će osvježiti podatke sa servera
          _petsFuture = _loadMyPets();
        });
        print('🗑️ [DELETE] Removed pet $petId from cache, now ${_cachedPets!.length} pets');
      }
      
      await apiClient.deletePet(petId);
      print('✅ [DELETE] Pet $petId deleted from server');
      
      if (mounted) {
        // Osveži listu sa servera - sačekaj da se podaci učitaju
        try {
          final pets = await _loadMyPets();
          setState(() {
            _cachedPets = pets;
            _futureBuilderKey = UniqueKey(); // Forsiraj rebuild sa novim podacima
            _petsFuture = Future.value(pets); // Postavi Future sa novim podacima
          });
          print('✅ [DELETE] Refreshed list, now ${pets.length} pets from server');
        } catch (e) {
          print('⚠️ [DELETE] Error refreshing after delete: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ljubimac je uspešno obrisan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [DELETE] Error deleting pet: $e');
      if (mounted) {
        // Ako je došlo do greške, osveži listu da se vrati na originalno stanje
        await _refreshPets();
        
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






