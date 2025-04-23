import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'add_plant_page.dart';
import 'edit_plant_page.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PlantListScreen(),
    const AddPlantPage(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.green.shade100,
        buttonBackgroundColor: Colors.green,
        height: 60,
        index: _selectedIndex,
        items: const <Widget>[
          Icon(Icons.dashboard, size: 30),
          Icon(Icons.add, size: 30),
          Icon(Icons.settings, size: 30),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String selectedSunlight = 'All';
  String selectedWater = 'All';

  final List<String> sunlightOptions = ['All', 'Low', 'Medium', 'High'];
  final List<String> waterOptions = [
    'All',
    'Once a Week',
    'Twice a Week',
    'Every Other Day',
    'Everyday',
  ];

  void _showDeleteConfirmationDialog(BuildContext context, String plantId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Plant"),
            content: const Text("Are you sure you want to delete this plant?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('plants')
                      .doc(plantId)
                      .delete();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("You must be logged in."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.pushNamed(context, '/calendar');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSunlight,
                    items:
                        sunlightOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSunlight = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Sunlight'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedWater,
                    items:
                        waterOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedWater = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Watering'),
                  ),
                ),
              ],
            ),
          ),

          // Plant List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('plants')
                      .where('uid', isEqualTo: user!.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading plants'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allPlants = snapshot.data!.docs;

                final filteredPlants =
                    allPlants.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final sunlightMatch =
                          selectedSunlight == 'All' ||
                          data['sunlight'] == selectedSunlight;
                      final waterMatch =
                          selectedWater == 'All' ||
                          data['water'] == selectedWater;
                      return sunlightMatch && waterMatch;
                    }).toList();

                if (filteredPlants.isEmpty) {
                  return const Center(child: Text('No plants match filters.'));
                }

                return ListView.builder(
                  itemCount: filteredPlants.length,
                  itemBuilder: (context, index) {
                    final plant =
                        filteredPlants[index].data() as Map<String, dynamic>;
                    final plantId = filteredPlants[index].id;

                    return ListTile(
                      leading: Hero(
                        tag: 'plantHero_$plantId',
                        child: const Icon(
                          Icons.local_florist,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(plant['name'] ?? 'Unnamed Plant'),
                      subtitle: Text(plant['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditPlantPage(plantId: plantId),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                () => _showDeleteConfirmationDialog(
                                  context,
                                  plantId,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
