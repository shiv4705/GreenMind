import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class AddPlantPage extends StatefulWidget {
  const AddPlantPage({super.key});

  @override
  State<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  String _selectedSunlight = 'Low';
  String _selectedWater = 'Once a Week';

  final List<String> _sunlightOptions = ['Low', 'Medium', 'High'];
  final List<String> _waterOptions = [
    'Once a Week',
    'Twice a Week',
    'Every Other Day',
    'Everyday',
  ];

  Future<void> _addPlant() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (_formKey.currentState!.validate() && user != null) {
        final plantData = {
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'temperature': _temperatureController.text.trim(),
          'sunlight': _selectedSunlight,
          'water': _selectedWater,
          'timestamp': Timestamp.now(),
        };

        await FirebaseFirestore.instance.collection('plants').add(plantData);

        await NotificationService.showImmediateNotification(
          _nameController.text,
        );
        await NotificationService.scheduleRecurringReminder(
          plantName: _nameController.text,
          frequency: _selectedWater,
        );

        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant added successfully')),
        );
      }
    } catch (e) {
      print('Error adding plant: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error adding plant')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Plant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Plant Name'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _temperatureController,
                decoration: const InputDecoration(
                  labelText: 'Temperature (e.g., 18-27°C)',
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter temperature' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSunlight,
                items:
                    _sunlightOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged:
                    (value) => setState(() => _selectedSunlight = value!),
                decoration: const InputDecoration(labelText: 'Sunlight Level'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedWater,
                items:
                    _waterOptions
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                onChanged: (value) => setState(() => _selectedWater = value!),
                decoration: const InputDecoration(
                  labelText: 'Watering Frequency',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPlant,
                child: const Text('Save Plant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
