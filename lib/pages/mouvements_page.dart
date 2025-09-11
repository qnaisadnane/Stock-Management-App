import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/add_mouvement_page.dart';
import 'package:flutter_application_1/pages/edit_mouvement_page.dart';

class MouvementsPage extends StatelessWidget {
  const MouvementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Historique des mouvements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMouvementPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mouvements')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final mouvements = snapshot.data!.docs;

          if (mouvements.isEmpty) {
            return const Center(child: Text('Aucun mouvement trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mouvements.length,
            itemBuilder: (context, index) {
              final doc = mouvements[index];
              final data = doc.data() as Map<String, dynamic>;

              final id = doc.id;
              final type = data['type'] ?? 'Non spécifié';
              final quantite = data['quantite'] ?? 0;
              final date = (data['date'] as Timestamp).toDate();
              final categorie = data.containsKey('categorie')
                  ? data['categorie']
                  : 'Non spécifiée';

              return _buildMovementItem(
                context,
                id,
                type,
                quantite,
                date,
                categorie,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMovementItem(
    BuildContext context,
    String id,
    String type,
    int quantite,
    DateTime dateTime,
    String categorie,
  ) {
    Color color = type == 'Ajout' ? Colors.green : Colors.red;
    IconData icon = type == 'Ajout' ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),

            // Colonne principale (ID, Type, Infos)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID en haut
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Type
                  Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Infos
                  Text('Catégorie : $categorie'),
                  Text('Quantité : $quantite'),
                  Text(_formatDateTime(dateTime)),
                ],
              ),
            ),

            // Bouton menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMouvementPage(mouvementId: id),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce mouvement ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annuler", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('mouvements')
                  .doc(id)
                  .delete();
              Navigator.of(ctx).pop();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} à ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
