import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'addFAQ.dart';
import 'home.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, int> complaintsLastWeek = {};
  Map<String, double> complaintDomainPercentages = {};

  @override
  void initState() {
    super.initState();
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.get(Uri.parse('$apiUrl/analytics'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        complaintsLastWeek = Map<String, int>.from(data['complaints_last_week']);
        complaintDomainPercentages = Map<String, double>.from(data['complaint_domain_percentages']);
      });
    } else {
      print('Failed to fetch analytics data');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              'images/logo.png',
              // Assuming you have a login image
              height: height * .07,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Text('Analytics',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Baker',
                  fontSize: height * .07,
                  fontWeight: FontWeight.bold))
        ]),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Color(0xFF0A0E21),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.question_answer),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return AddFAQScreen();
                        }));
                  },
                ),
                Text(
                  'Manage FAQs',
                  style: TextStyle(fontSize: 10.0),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.analytics),
                  onPressed: () {},
                ),
                Text(
                  'Analytic Screen',
                  style: TextStyle(fontSize: 10.0),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return DocumentRequestScreen();
                        }));
                  },
                ),
                Text(
                  'Home',
                  style: TextStyle(fontSize: 10.0),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'User Insights',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 1.3),
                children: [
                  _buildTile(
                    title: 'Number of Queries Last Week',
                    child: Expanded(child: _buildBarChart(context)),
                  ),
                  _buildTile(
                    title: 'Most Popular Complaint Domain',
                    child: Expanded(child: _buildPieChart(context)),
                  ),
                  _buildTile(
                    title: 'Average Resolution Time',
                    child: _buildAverageResolutionTime(),
                  ),
                  _buildTile(
                    title: 'User Satisfaction Rating',
                    child: _buildUserRating(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({required String title, required Widget child}) {
    return Card(
      elevation: 2.0,
      color: Color(0xFF006DE3),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          maxY: complaintsLastWeek.values.reduce((a, b) => a > b ? a : b).toDouble(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTextStyles: (context, value) => TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
              margin: 10,
              getTitles: (double value) {
                return complaintsLastWeek.keys.elementAt(value.toInt());
              },
            ),
            leftTitles: SideTitles(showTitles: false),
          ),
          borderData: FlBorderData(show: false),
          barGroups: complaintsLastWeek.entries.map((entry) {
            final index = complaintsLastWeek.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [BarChartRodData(y: entry.value.toDouble())],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      child: PieChart(
        PieChartData(
          sections: complaintDomainPercentages.entries.map((entry) {
            final color = Colors.primaries[complaintDomainPercentages.keys.toList().indexOf(entry.key) % Colors.primaries.length];
            return PieChartSectionData(
              value: entry.value * 100,
              color: color,
              title: '${entry.key} (${(entry.value * 100).toStringAsFixed(1)}%)',
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAverageResolutionTime() {
    return Text(
      '7 hours', // Placeholder for demonstration
      style: TextStyle(fontSize: 14.0),
    );
  }

  Widget _buildUserRating() {
    return Text(
      '4.5', // Placeholder for demonstration
      style: TextStyle(fontSize: 14.0),
    );
  }
}