import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int articlesCount = 0;
  int alertsCount = 0;
  int mouvementsCount = 0;
  int fournisseursCount = 0;
  int achatsCount = 0;
  int nonAlertCount = 0;
  int ajoutMouvementCount = 0;
  int retraitMouvementCount = 0;

  List<Map<String, dynamic>> alertItems = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final firestore = FirebaseFirestore.instance;
    final articlesSnapshot = await firestore.collection('articles').get();
    final articles = articlesSnapshot.docs;
    final alerts = articles.where((doc) {
      final data = doc.data();
      return (data['quantite'] ?? 0) < (data['seuil_min'] ?? 0);
    }).toList();
    final nonAlerts = articles.length - alerts.length;

    final mouvementsSnapshot = await firestore.collection('mouvements').get();
    final mouvements = mouvementsSnapshot.docs;

    int ajoutCount = 0;
    int retraitCount = 0;
    for (var doc in mouvements) {
      final data = doc.data();
      if (data['type'] == 'Ajout') {
        ajoutCount++;
      } else if (data['type'] == 'Retrait') {
        retraitCount++;
      }
    }

    final fournisseursSnapshot = await firestore.collection('fournisseurs').get();
    final achatsSnapshot = await firestore.collection('achats').get();

    setState(() {
      articlesCount = articles.length;
      alertsCount = alerts.length;
      mouvementsCount = mouvements.length;
      fournisseursCount = fournisseursSnapshot.size;
      achatsCount = achatsSnapshot.size;
      nonAlertCount = nonAlerts;
      ajoutMouvementCount = ajoutCount;
      retraitMouvementCount = retraitCount;

      alertItems = alerts.map((doc) {
        final data = doc.data();
        return {
          'categorie': data['categorie'] ?? 'Article',
          'quantite': data['quantite'] ?? 0,
          'seuil': data['seuil_min'] ?? 0,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé du stock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(Icons.inventory, 'Articles', '$articlesCount', Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.warning_amber, 'Alertes', '$alertsCount', Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(Icons.check_circle_outline, 'Non-alertes', '$nonAlertCount', Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.swap_horiz, 'Mouvements', '$mouvementsCount', Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(Icons.add_circle_outline, 'Ajout Mouvement', '$ajoutMouvementCount', Colors.indigo),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.remove_circle_outline, 'Retrait Mouvement', '$retraitMouvementCount', Colors.deepOrange),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(Icons.group, 'Fournisseurs', '$fournisseursCount', Colors.purple),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.shopping_cart, 'Achats', '$achatsCount', Colors.teal),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Alertes de stock bas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: alertItems.isEmpty
                  ? const SizedBox()
                  : Column(
                      key: ValueKey(alertItems.length),
                      children: alertItems.map((item) => _buildAlertItem(
                        item['categorie'],
                        item['quantite'],
                        item['seuil'],
                      )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertItem(String name, int quantity, int threshold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.warning, color: Colors.red[700]),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Quantité: $quantity  •  Seuil: $threshold'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Alerte',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
