import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserActivityChartScreen extends StatefulWidget {
  const UserActivityChartScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserActivityChartScreenState createState() => _UserActivityChartScreenState();
}

class _UserActivityChartScreenState extends State<UserActivityChartScreen> {
  String _selectedInterval = 'Settimanale'; // Intervallo predefinito
  Map<String, int> _userLogins = {};
  DateTime _currentDate = DateTime.now(); // Data corrente per il periodo visualizzato

  @override
  void initState() {
    super.initState();
    _loadUserLogins();
  }

  Future<void> _loadUserLogins() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.get();

    // Mappa per memorizzare il conteggio degli accessi per giorno
    Map<String, int> userLogins = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      
      DateTime? lastAccess;
      if (data['lastAccess'] != null) {
        try {
          lastAccess = DateTime.parse(data['lastAccess']);
        } catch (e) {
          print('Errore nel parsing di lastAccess: $e');
          lastAccess = null;
        }
      }

      if (lastAccess != null) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(lastAccess);

        if (userLogins.containsKey(formattedDate)) {
          userLogins[formattedDate] = userLogins[formattedDate]! + 1;
        } else {
          userLogins[formattedDate] = 1;
        }
      }
    }

    setState(() {
      _userLogins = userLogins;
    });
  }

  List<String> _getDisplayedDates() {
    List<String> displayedDates = [];

    if (_selectedInterval == 'Giornaliero') {
      // Mostra gli ultimi 30 giorni, partendo da oggi
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 30));

      for (DateTime date = endDate; date.isAfter(startDate) || date.isAtSameMomentAs(startDate); date = date.subtract(const Duration(days: 1))) {
        displayedDates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    } else if (_selectedInterval == 'Settimanale') {
      // Raggruppa per settimana
      DateTime startOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
      DateTime endOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
      DateTime currentWeekStart = startOfMonth.subtract(Duration(days: startOfMonth.weekday - 1)); // Inizia dal lunedì

      while (currentWeekStart.isBefore(endOfMonth)) {
        String weekKey = DateFormat('yyyy-MM-dd').format(currentWeekStart);
        displayedDates.add(weekKey);
        currentWeekStart = currentWeekStart.add(const Duration(days: 7)); // Vai alla settimana successiva
      }
    } else if (_selectedInterval == 'Mensile') {
      // Mostra tutti i mesi dell'anno corrente
      DateTime startDate = DateTime(_currentDate.year, 1, 1);

      for (int i = 0; i < 12; i++) {
        String monthKey = DateFormat('yyyy-MM').format(DateTime(startDate.year, startDate.month + i, 1));
        displayedDates.add(monthKey);
      }
    }

    return displayedDates;
  }

  List<BarChartGroupData> _generateBarGroups(List<String> displayedDates) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < displayedDates.length; i++) {
      String dateKey = displayedDates[i];
      int count = 0;

      if (_selectedInterval == 'Giornaliero') {
        count = _userLogins[dateKey] ?? 0;
      } else if (_selectedInterval == 'Settimanale') {
        // Conta gli accessi per ogni giorno della settimana
        for (int j = 0; j < 7; j++) {
          String dayKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(dateKey).add(Duration(days: j)));
          count += _userLogins[dayKey] ?? 0;
        }
      } else if (_selectedInterval == 'Mensile') {
        // Conta gli accessi per ogni giorno del mese
        DateTime monthStart = DateTime.parse('$dateKey-01');
        DateTime monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

        for (DateTime date = monthStart; date.isBefore(monthEnd) || date.isAtSameMomentAs(monthEnd); date = date.add(const Duration(days: 1))) {
          String dayKey = DateFormat('yyyy-MM-dd').format(date);
          count += _userLogins[dayKey] ?? 0;
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              width: 16,
              color: Colors.blueAccent,
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  void _changeMonth(int direction) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + direction, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayedDates = _getDisplayedDates();
    List<BarChartGroupData> barGroups = _generateBarGroups(displayedDates);

    bool canGoForward = _currentDate.month != DateTime.now().month || _currentDate.year != DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiche Accessi Utenti - ${DateFormat('MMMM yyyy').format(_currentDate)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: _selectedInterval,
              items: ['Giornaliero', 'Settimanale', 'Mensile'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedInterval = newValue!;
                  _currentDate = DateTime.now(); // Reset alla data corrente quando si cambia intervallo
                });
              },
            ),
            const SizedBox(height: 20),
            if (_selectedInterval != 'Giornaliero')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      _changeMonth(-1);
                    },
                  ),
                  Text(
                    'Mese di ${DateFormat('MMMM yyyy').format(_currentDate)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: canGoForward
                        ? () {
                            _changeMonth(1);
                          }
                        : null, // Disabilita se non si può andare avanti
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: displayedDates.length * 80.0,  // Larghezza dinamica per i giorni, settimane o mesi
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              // Mostra solo se il valore è un indice valido
                              if (value.toInt() < displayedDates.length) {
                                String date = displayedDates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    _selectedInterval == 'Giornaliero'
                                        ? DateFormat('dd/MM').format(DateTime.parse(date))
                                        : _selectedInterval == 'Settimanale'
                                                                                        ? DateFormat('dd MMM').format(DateTime.parse(date))
                                            : DateFormat('MMM').format(DateTime.parse('$date-01')),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              } else {
                                return Container(); // Ritorna un widget vuoto se non c'è titolo
                              }
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false), // Disabilita la griglia per pulire l'interfaccia
                      borderData: FlBorderData(show: false), // Disabilita i bordi per un aspetto più pulito
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}