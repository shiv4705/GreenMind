// ignore_for_file: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditPlantPage extends StatefulWidget {
  final String plantId;

  const EditPlantPage({super.key, required this.plantId});

  @override
  _EditPlantPageState createState() => _EditPlantPageState();
}

class _EditPlantPageState extends State<EditPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedSunlight = 'Low';
  String _selectedWater = 'Once a Week';

  final List<String> sunlightOptions = ['Low', 'Medium', 'High'];
  final List<String> waterOptions = [
    'Once a Week',
    'Twice a Week',
    'Every Other Day',
    'Everyday',
  ];

  // Load plant data from Firestore when the page is opened
  @override
  void initState() {
    super.initState();
    _loadPlantData();
  }

  Future<void> _loadPlantData() async {
    DocumentSnapshot plantDoc =
        await FirebaseFirestore.instance
            .collection('plants')
            .doc(widget.plantId)
            .get();

    if (plantDoc.exists) {
      var plantData = plantDoc.data() as Map<String, dynamic>;
      _nameController.text = plantData['name'] ?? '';
      _descriptionController.text = plantData['description'] ?? '';
      _selectedSunlight = plantData['sunlight'] ?? 'Low';
      _selectedWater = plantData['water'] ?? 'Once a Week';
    }
  }

  // Save the updated plant details
  Future<void> _updatePlant() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'sunlight': _selectedSunlight,
        'water': _selectedWater,
      };

      try {
        await FirebaseFirestore.instance
            .collection('plants')
            .doc(widget.plantId)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant details updated successfully')),
        );

        Navigator.pop(context); // Go back to the home page
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update plant details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Plant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Plant Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a plant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Sunlight Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSunlight,
                items:
                    sunlightOptions
                        .map(
                          (sunlight) => DropdownMenuItem<String>(
                            value: sunlight,
                            child: Text(sunlight),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSunlight = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Sunlight',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Watering Frequency Dropdown
              DropdownButtonFormField<String>(
                value: _selectedWater,
                items:
                    waterOptions
                        .map(
                          (water) => DropdownMenuItem<String>(
                            value: water,
                            child: Text(water),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWater = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Watering Frequency',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _updatePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
