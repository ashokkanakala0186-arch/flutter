import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  late Future<Map<String, List<Map<String, Object?>>>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _tablesFuture = _loadAllTables();
  }

  Future<Map<String, List<Map<String, Object?>>>> _loadAllTables() async {
    final db = await DatabaseHelper.instance.database;
    final master = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final tables = <String, List<Map<String, Object?>>>{};
    for (final row in master) {
      final tableName = row['name'] as String;
      final rows = await db.query(tableName, orderBy: 'id ASC');
      tables[tableName] = rows;
    }
    return tables;
  }

  String _cell(Object? value) {
    if (value == null) return 'NULL';
    if (value is String) return value.isEmpty ? "''" : value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer (SQLite)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _tablesFuture = _loadAllTables();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, Object?>>>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            );
          }
          final tables = snapshot.data!;
          if (tables.isEmpty) {
            return const Center(child: Text('No tables found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in tables.entries) ...[
                _buildTable(context, entry.key, entry.value),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    String name,
    List<Map<String, Object?>> rows,
  ) {
    final columns = rows.isEmpty ? <String>[] : rows.first.keys.toList();
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.table_rows, color: AppColors.green),
          title: Text(
            '$name  (${rows.length} rows)',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          children: [
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '(empty)',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SelectableText(
                          '-- row ${i + 1} --\n'
                          '${columns.map((c) => '$c = ${_cell(rows[i][c])}').join('\n')}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textDark,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
