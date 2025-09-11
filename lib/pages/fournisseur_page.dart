import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/add_fournisseur_page.dart';
import 'package:flutter_application_1/pages/edit_fournisseur_page.dart';

class FournisseursPage extends StatefulWidget {
  const FournisseursPage({super.key});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  String searchQuery = '';

  void _confirmerSuppression(String docId, String nomFournisseur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le fournisseur "$nomFournisseur" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await FirebaseFirestore.instance
                    .collection('fournisseurs')
                    .doc(docId)
                    .delete();

                await Future.delayed(const Duration(milliseconds: 300));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fournisseur supprimé avec succès.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un fournisseur',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFournisseurPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fournisseurs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox.shrink());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final fournisseurs = snapshot.data?.docs ?? [];

          final filteredFournisseurs = fournisseurs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final societe = (data['societe'] ?? '').toString().toLowerCase();
            return societe.contains(searchQuery);
          }).toList();

          if (filteredFournisseurs.isEmpty) {
            return const Center(child: Text("Aucun fournisseur trouvé."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredFournisseurs.length,
            itemBuilder: (context, index) {
              final doc = filteredFournisseurs[index];
              final data = doc.data() as Map<String, dynamic>;
              final societe = data['societe'] ?? 'Non spécifié';
              final telephone = data['telephone'] ?? 'Non spécifié';
              final email = data['email'] ?? 'Non spécifié';
              final adresse = data['adresse'] ?? 'Non spécifiée';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ID du fournisseur
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    doc.id,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Nom de la société
                                Text(
                                  societe,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'modifier') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditFournisseurPage(
                                      fournisseurId: doc.id,
                                      fournisseurData: data,
                                    ),
                                  ),
                                );
                              } else if (value == 'supprimer') {
                                _confirmerSuppression(doc.id, societe);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'modifier',
                                child: Text('Modifier'),
                              ),
                              const PopupMenuItem(
                                value: 'supprimer',
                                child: Text('Supprimer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.phone, telephone),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email, email),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, adresse),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey[300]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
