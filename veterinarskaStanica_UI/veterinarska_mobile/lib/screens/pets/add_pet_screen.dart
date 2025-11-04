import 'package:flutter/material.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class AddPetScreen extends StatefulWidget {
  final VoidCallback? onPetAdded; // Callback za refresh liste
  final Pet? petToEdit; // Pet za editovanje
  
  const AddPetScreen({super.key, this.onPetAdded, this.petToEdit});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  
  PetGender _selectedGender = PetGender.male;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.petToEdit != null) {
      // Popuni polja za edit mode
      _nameController.text = widget.petToEdit!.name;
      _speciesController.text = widget.petToEdit!.species;
      _breedController.text = widget.petToEdit!.breed ?? '';
      _colorController.text = widget.petToEdit!.color ?? '';
      _weightController.text = widget.petToEdit!.weight?.toString() ?? '';
      _microchipController.text = widget.petToEdit!.microchipNumber ?? '';
      _notesController.text = widget.petToEdit!.notes ?? '';
      _selectedGender = widget.petToEdit!.gender;
      _selectedDateOfBirth = widget.petToEdit!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addPet() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = serviceLocator.authService;
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška: Korisnik nije prijavljen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = serviceLocator.apiClient;
      final petData = {
        'name': _nameController.text,
        'species': _speciesController.text,
        'breed': _breedController.text.isEmpty ? null : _breedController.text,
        'gender': _selectedGender.index + 1, // Convert to backend enum (1=male, 2=female)
        'color': _colorController.text.isEmpty ? null : _colorController.text,
        'weight': _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
        'microchipNumber': _microchipController.text.isEmpty ? null : _microchipController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
        // petOwnerId se ne šalje jer backend automatski koristi trenutnog korisnika
      };
      
      if (widget.petToEdit != null) {
        // Edit mode
        await apiClient.updatePet(widget.petToEdit!.id, petData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ljubimac je uspešno ažuriran'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Add mode
        final createdPet = await apiClient.addPet(petData);
        
        if (mounted && createdPet != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ljubimac je uspešno dodat'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Pozovi callback za refresh liste NAKON prikazivanja poruke
          widget.onPetAdded?.call();
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
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
        title: Text(widget.petToEdit != null ? 'Uredi ljubimca' : 'Dodaj ljubimca'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ime
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Ime ljubimca *',
                  prefixIcon: const Icon(Icons.pets),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite ime ljubimca';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Vrsta
              TextFormField(
                controller: _speciesController,
                decoration: InputDecoration(
                  labelText: 'Vrsta *',
                  prefixIcon: const Icon(Icons.category),
                  hintText: 'pas, mačka, ptica...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite vrstu životinje';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Rasa
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Rasa (opcionalno)',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pol
              DropdownButtonFormField<PetGender>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Pol',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: PetGender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender == PetGender.male ? 'Muški' : 'Ženski'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Datum rođenja
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDateOfBirth = date;
                    });
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
                      const Icon(Icons.cake, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDateOfBirth != null
                            ? 'Datum rođenja: ${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                            : 'Izaberite datum rođenja (opcionalno)',
                        style: TextStyle(
                          color: _selectedDateOfBirth != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Boja
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Boja (opcionalno)',
                  prefixIcon: const Icon(Icons.palette),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Težina
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Težina u kg (opcionalno)',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mikročip
              TextFormField(
                controller: _microchipController,
                decoration: InputDecoration(
                  labelText: 'Broj mikročipa (opcionalno)',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Napomene
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Napomene (opcionalno)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dugme za dodavanje
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.petToEdit != null ? 'Ažuriraj ljubimca' : 'Dodaj ljubimca',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Text(
                '* Obavezna polja',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}






