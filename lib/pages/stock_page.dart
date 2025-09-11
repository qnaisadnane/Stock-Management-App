import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/pages/edit_article_page.dart';
import 'add_article_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Stock Industriel', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddArticlePage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildArticleList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un article',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildFilters() {
    final filters = ['Tous', 'Sous seuil', 'Normal'];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFilter = filter),
          selectedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(color: isSelected ? Colors.blue.shade800 : Colors.black87),
        );
      }).toList(),
    );
  }

  Widget _buildArticleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('articles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur lors du chargement'));
        }

        final articles = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final categorie = data['categorie']?.toString().toLowerCase() ?? '';
          final quantite = data['quantite'] ?? 0;
          final seuil = data['seuil_min'] ?? 0;
          final isLow = quantite < seuil;

          if (_selectedFilter == 'Sous seuil' && !isLow) return false;
          if (_selectedFilter == 'Normal' && isLow) return false;

          return categorie.contains(_searchQuery);
        }).toList();

        if (articles.isEmpty) {
          return const Center(child: Text('Aucun article trouvé.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final doc = articles[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildStockItem(
              id: data['id'] ?? doc.id,
              name: data['type'] ?? 'Inconnu',
              quantity: data['quantite'] ?? 0,
              minThreshold: data['seuil_min'] ?? 0,
              unit: data['unite'] ?? '',
              categorie: data['categorie'] ?? '',
              poste: data['poste'] ?? '',
              isLow: (data['quantite'] ?? 0) < (data['seuil_min'] ?? 0),
              docId: doc.id,
            );
          },
        );
      },
    );
  }

  Widget _buildStockItem({
    required String id,
    required String name,
    required int quantity,
    required int minThreshold,
    required String unit,
    required String categorie,
    required String poste,
    required bool isLow,
    required String docId,
  }) {
    final statusColor = isLow ? Colors.red : Colors.green;
    final statusLabel = isLow ? '⚠️ Sous seuil' : '✅ OK';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          radius: 26,
          child: Text(
            id,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Catégorie : $categorie'),
            Text('Quantité : $quantity'),
            Text('Unité : $unit'),
            Text('Seuil minimum : $minThreshold'),
            Text('Poste : $poste'),
            const SizedBox(height: 4),
            Text('Statut : $statusLabel', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditArticlePage(articleId: docId)),
              );
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, docId);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet article ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('articles').doc(id).delete();
              Navigator.of(ctx).pop();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
