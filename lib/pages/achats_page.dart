import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/add_achat_page.dart';
import 'package:flutter_application_1/pages/edit_achat_page.dart';
import 'package:intl/intl.dart';

class AchatsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormat = NumberFormat("##0.00", "fr_FR");

  AchatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des achats', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAchatPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('achats').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final achats = snapshot.data?.docs ?? [];

          if (achats.isEmpty) {
            return const Center(child: Text('Aucun achat trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achats.length,
            itemBuilder: (context, index) {
              final doc = achats[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = _parseDate(data['date']);
              final total = (data['total'] as num?)?.toDouble() ?? 0.0;
              final articles = List<Map<String, dynamic>>.from(data['articles'] ?? []);
              final fournisseurId = data['fournisseurId'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('fournisseurs').doc(fournisseurId).get(),
                builder: (context, fournisseurSnapshot) {
                  String societe = 'Société inconnue';
                  if (fournisseurSnapshot.connectionState == ConnectionState.done &&
                      fournisseurSnapshot.hasData &&
                      fournisseurSnapshot.data!.exists) {
                    final fournisseurData = fournisseurSnapshot.data!.data() as Map<String, dynamic>?;
                    societe = fournisseurData?['societe'] ?? 'Société inconnue';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID Achat
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'modifier') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditAchatPage(
                                          achatId: doc.id,
                                          achatData: data,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'supprimer') {
                                    _confirmerSuppression(context, doc.id);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                                  PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                societe,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...articles.map((article) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildArticleDetails(article),
                              )),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Montant total :", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text(
                                '${_currencyFormat.format(total)} DH',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _parseDate(dynamic date) {
    try {
      if (date == null) return 'Date inconnue';
      if (date is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(date.toDate());
      }
      return date.toString();
    } catch (_) {
      return 'Date invalide';
    }
  }

  Widget _buildArticleDetails(Map<String, dynamic> article) {
    final nom = article['nom'] ?? 'Article';
    
    final quantite = article['quantite'] ?? 0;
    final prixUnitaire = (article['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
    final total = quantite * prixUnitaire;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$quantite x ${_currencyFormat.format(prixUnitaire)} DH', style: const TextStyle(fontSize: 13)),
            Text('${_currencyFormat.format(total)} DH', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  void _confirmerSuppression(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet achat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _firestore.collection('achats').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Achat supprimé avec succès.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
