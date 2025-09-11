import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AddAchatPage extends StatefulWidget {
  const AddAchatPage({super.key});

  @override
  State<AddAchatPage> createState() => _AddAchatPageState();
}

class _AddAchatPageState extends State<AddAchatPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idAchatController = TextEditingController();
  String? _selectedFournisseurId;
  String? _selectedFournisseurNom;
  DateTime? _selectedDate;
  final _dateController = TextEditingController();
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addArticleRow();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _idAchatController.dispose();
    super.dispose();
  }

  void _addArticleRow() {
    setState(() {
      _articles.add({'articleId': null, 'nom': null, 'quantite': 1, 'prixUnitaire': 0.0});
    });
  }

  double _calculerTotal() {
    return _articles.fold(0.0, (total, article) {
      final quantite = article['quantite'] ?? 0;
      final prix = article['prixUnitaire'] ?? 0.0;
      return total + (quantite * prix);
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFournisseurId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final idAchat = _idAchatController.text.trim();

    try {
      final docRef = FirebaseFirestore.instance.collection('achats').doc(idAchat);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur : ID Achat déjà utilisé.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await docRef.set({
        'fournisseurId': _selectedFournisseurId,
        'date': _selectedDate,
        'total': _calculerTotal(),
        'articles': _articles,
      });

      for (var item in _articles) {
        final articleRef = FirebaseFirestore.instance.collection('articles').doc(item['articleId']);
        final doc = await articleRef.get();
        final data = doc.data()!;
        final nouvelleQuantite = (data['quantite'] ?? 0) + item['quantite'];
        await articleRef.update({'quantite': nouvelleQuantite});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achat ajouté avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildFormSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[100],
      suffixIcon: icon != null ? Icon(icon) : null,
    );
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final formattedDate = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : 'Non spécifiée';

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Facture d'achat", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("ID Achat : ${_idAchatController.text}"),
            pw.Text("Date : $formattedDate"),
            pw.Text("Fournisseur : $_selectedFournisseurNom"),
            pw.SizedBox(height: 20),
            pw.Text("Articles :"),
            pw.Table.fromTextArray(
              headers: ['Article', 'Quantité', 'Prix U.', 'Total'],
              data: _articles.map((a) {
                final total = (a['quantite'] ?? 0) * (a['prixUnitaire'] ?? 0.0);
                return [a['nom'] ?? '', '${a['quantite']}', '${a['prixUnitaire']} DH', '$total DH'];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Total : ${_calculerTotal().toStringAsFixed(2)} DH", style: pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un achat"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idAchatController,
                decoration: _inputDecoration("ID Achat"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ID Achat requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildFormSectionTitle("Fournisseur"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('fournisseurs').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final fournisseurs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedFournisseurId,
                    items: fournisseurs.map((doc) {
                      final societe = doc.data().toString().contains('societe') ? doc['societe'] : 'Société non définie';
                      return DropdownMenuItem(value: doc.id, child: Text(societe));
                    }).toList(),
                    onChanged: (value) {
                      final selected = fournisseurs.firstWhere((doc) => doc.id == value);
                      setState(() {
                        _selectedFournisseurId = value;
                        _selectedFournisseurNom = selected['societe'];
                      });
                    },
                    validator: (value) => value == null ? "Sélectionner un fournisseur" : null,
                    decoration: _inputDecoration("Sélectionner un fournisseur"),
                  );
                },
              ),
              _buildFormSectionTitle("Date de l'achat"),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                validator: (_) => _selectedDate == null ? "Date requise" : null,
                decoration: _inputDecoration("Sélectionner la date", icon: Icons.calendar_today),
              ),
              _buildFormSectionTitle("Articles"),
              ..._articles.asMap().entries.map((entry) {
                final index = entry.key;
                final article = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('articles').get(),
                      builder: (context, snapshot) {
                        final articlesDocs = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          value: article['articleId'],
                          items: articlesDocs.map((doc) {
                            final categorie = doc.data().toString().contains('categorie') ? doc['categorie'] : 'Catégorie inconnue';
                            return DropdownMenuItem(value: doc.id, child: Text(categorie));
                          }).toList(),
                          onChanged: (value) {
                            final selected = articlesDocs.firstWhere((doc) => doc.id == value);
                            setState(() {
                              article['articleId'] = value;
                              article['nom'] = selected['categorie'];
                            });
                          },
                          validator: (value) => value == null ? "Sélectionner un article" : null,
                          decoration: _inputDecoration("Article"),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: article['quantite'].toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => article['quantite'] = int.tryParse(value) ?? 0,
                            decoration: _inputDecoration("Quantité"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: article['prixUnitaire'].toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => article['prixUnitaire'] = double.tryParse(value) ?? 0.0,
                            decoration: _inputDecoration("Prix unitaire"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _articles.removeAt(index)),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addArticleRow,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Ajouter un article", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: const Text("Calculer le Total", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text("Total : ${_calculerTotal().toStringAsFixed(2)} DH", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final pdf = await _buildPdf();
                  await Printing.layoutPdf(onLayout: (format) => pdf.save());

                  try {
                    final outputDir = await getExternalStorageDirectory();
                    final filePath = '${outputDir!.path}/facture_${DateTime.now().millisecondsSinceEpoch}.pdf';
                    final file = File(filePath);
                    await file.writeAsBytes(await pdf.save());

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Facture enregistrée : ${file.path}')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur de sauvegarde PDF : $e')),
                    );
                  }
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text("Imprimer la facture", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Enregistrer l'achat", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
