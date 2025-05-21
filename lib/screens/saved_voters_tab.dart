import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as ex;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SavedVotersTab extends StatefulWidget {
  const SavedVotersTab({super.key});

  @override
  State<SavedVotersTab> createState() => _SavedVotersTabState();
}

class _SavedVotersTabState extends State<SavedVotersTab> {
  List<Map<String, dynamic>> _allVoters = [];
  List<Map<String, dynamic>> _displayedVoters = [];
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 100;

  @override
  void initState() {
    super.initState();
    _fetchVoters();
  }

  Future<void> _fetchVoters() async {
    final url = Uri.parse('https://dev-moamen.pro/test/display.php');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _allVoters = data.cast<Map<String, dynamic>>();
        _applySearchAndPagination();
      });
    }
  }

  void _applySearchAndPagination() {
    List<Map<String, dynamic>> filtered = _searchTerm.isEmpty
        ? _allVoters
        : _allVoters
            .where((v) => v['name'].toString().contains(_searchTerm))
            .toList();

    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    setState(() {
      _displayedVoters = filtered.sublist(start, end);
    });
  }

  Future<void> _exportToExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['الناخبين'];

    sheet.appendRow([
      'الاسم',
      'تاريخ الميلاد',
      'الهاتف',
      'رقم الناخب',
      'العائلة',
      'مركز التسجيل',
      'مركز الاقتراع',
      'المحافظة'
    ]);

    for (var v in _displayedVoters) {
      sheet.appendRow([
        v['name'],
        v['birthdate'],
        v['phone'],
        v['voter_number'],
        v['family_number'],
        v['register_center'],
        v['station_info'],
        v['governorate'],
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'exported_voters.xlsx');
    final fileBytes = excel.encode();
    final file = File(filePath);
    await file.writeAsBytes(fileBytes!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم التصدير: $filePath')),
    );
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
      _applySearchAndPagination();
    });
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _applySearchAndPagination();
      });
    }
  }

  Widget _buildCard(Map<String, dynamic> v) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 ${v['name']}', style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 4),
            Text('📞 الهاتف: ${v['phone']}', style: const TextStyle(color: Colors.white70)),
            Text('🎂 الميلاد: ${v['birthdate']}', style: const TextStyle(color: Colors.white70)),
            Text('🧾 رقم الناخب: ${v['voter_number']}', style: const TextStyle(color: Colors.white70)),
            Text('👪 رقم العائلة: ${v['family_number']}', style: const TextStyle(color: Colors.white70)),
            Text('🏢 مركز التسجيل: ${v['register_center']}', style: const TextStyle(color: Colors.white70)),
            Text('🗳️ مركز الاقتراع: ${v['station_info']}', style: const TextStyle(color: Colors.white70)),
            Text('📍 المحافظة: ${v['governorate']}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_allVoters.length / _rowsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('بيانات الناخبين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                _searchTerm = value;
                _currentPage = 0;
                _applySearchAndPagination();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن اسم ناخب...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _displayedVoters.isEmpty
                  ? const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: _displayedVoters.length,
                      itemBuilder: (_, i) => _buildCard(_displayedVoters[i]),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _prevPage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  child: const Text('الصفحة السابقة'),
                ),
                const SizedBox(width: 16),
                Text('صفحة ${_currentPage + 1} من $totalPages',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (_currentPage + 1 < totalPages) ? _nextPage : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  child: const Text('الصفحة التالية'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}