import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class Report extends StatefulWidget {
  const Report({Key? key}) : super(key: key);

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> with SingleTickerProviderStateMixin {
  late ScrollController _horizontalScrollController;
  late TabController _tabController;
  late Future<List<dynamic>> fetchData;
  final Color selectedColor = const Color(0xFF2D3748); // Dark slate blue color

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    fetchData = fetchReportData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchReportData() async {
    final response = await http.get(
      Uri.parse('https://api.apify.com/v2/acts/weeebi~edufree-12pm-report/runs/last/dataset/items?token=apify_api_TmKGM7NLP6GM9REsCmhyYPfqXK8Fji06CGf2'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load report data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: selectedColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // Placeholder for export functionality
              print('Export button pressed');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            var allData = snapshot.data!;
            var paidData = allData.where((data) => data['column6'] == 'TELAH DIBAYAR').toList();
            // Exclude entries from pendingData that match any name and number in paidData
            var pendingData = allData.where((data) => 
              data['column6'] != 'TELAH DIBAYAR' &&
              !paidData.any((paid) => paid['column2'] == data['column2'] && paid['column3'] == data['column3'])
            ).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                buildDataTable(pendingData, 'Pending', pendingData.length),
                buildDataTable(paidData, 'Paid', paidData.length),
              ],
            );
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }

  Widget buildDataTable(List<dynamic> data, String status, int totalCount) {
    double totalAmount = data.fold(0.0, (sum, item) {
      double value = double.tryParse(item['column7'].replaceAll(",", "")) ?? 0.0;
      return sum + value;
    });
      String formattedToday = DateFormat('dd MMM yyyy').format(DateTime.now().subtract(Duration(days: 1)));
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Total $status: RM ${totalAmount.toStringAsFixed(2)}', ),
          ),
          Text('$formattedToday',style:TextStyle(fontSize: 15,),),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('No.')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Contact')),

                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Source')),
              ],
              rows: List<DataRow>.generate(
                data.length,
                (index) {
                  var item = data[index];
                  var formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(item['column8']));
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(item['column2'] ?? '')),
                    DataCell(Text(item['column3'] ?? '')),
                    DataCell(Text(item['column5'] ?? '')),
                    DataCell(Text(item['column6'] ?? '')),
                    DataCell(Text('RM ${item['column7']}')),
                    DataCell(Text(formattedDate)),
                    DataCell(Text(item['column9'] ?? '')),
                    DataCell(Text(item['column10'] ?? '')),
                  ]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}