import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:veterinarska_shared/veterinarska_shared.dart';

class FinancialDashboard extends StatefulWidget {
  final UserRole userRole;

  const FinancialDashboard({super.key, required this.userRole});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  final FinancialService _financialService = FinancialService();
  bool _isLoading = true;
  FinancialSummary? _financialSummary;
  VeterinarianStats? _veterinarianStats;
  List<RevenueByService>? _adminRevenueByServices;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Javna metoda za refresh podataka
  void refreshData() {
    _loadData();
  }

  // Force refresh token i podataka
  Future<void> _forceRefreshToken() async {
    print('Force refreshing token...');
    await serviceLocator.authService.forceRefreshToken();
    // Vrati korisnika na login ekran
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      print('Loading data for role: ${widget.userRole} (attempt ${_retryCount + 1})');
      if (widget.userRole == UserRole.admin) {
        print('Loading admin financial summary...');
        _financialSummary = await _financialService.getAdminFinancialSummary();
        print('Admin data loaded: ${_financialSummary != null}');
        
        // Učitaj dodatne podatke za admin panel
        print('Loading admin revenue by services...');
        _adminRevenueByServices = await _financialService.getAdminRevenueByServices();
        print('Admin revenue by services loaded: ${_adminRevenueByServices?.length ?? 0} services');
      } else {
        print('Loading veterinarian stats...');
        _veterinarianStats = await _financialService.getVeterinarianStats();
        print('Veterinarian data loaded: ${_veterinarianStats != null}');
      }
      
      // Reset retry count on success
      _retryCount = 0;
    } catch (e, stackTrace) {
      print('Error in _loadData: $e');
      print('Stack trace: $stackTrace');
      
      // Check if we should retry
      if (_retryCount < _maxRetries && e.toString().contains('500')) {
        _retryCount++;
        print('Retrying in 2 seconds... (attempt ${_retryCount + 1}/$_maxRetries)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška na serveru. Pokušavam ponovo... (${_retryCount}/$_maxRetries)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Wait 2 seconds before retrying
        await Future.delayed(Duration(seconds: 2));
        return _loadData(); // Recursive retry
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju podataka: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Refresh Token',
              textColor: Colors.white,
              onPressed: () {
                _forceRefreshToken();
              },
            ),
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (widget.userRole == UserRole.admin && _financialSummary != null)
              _buildAdminDashboard(_financialSummary!)
            else if (widget.userRole == UserRole.veterinarian && _veterinarianStats != null)
              _buildVeterinarianDashboard(_veterinarianStats!)
            else
              const Center(child: Text('Nema dostupnih podataka')),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userRole == UserRole.admin ? 'Finansijska kontrolna tabla' : 'Moje statistike',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ažurirano: ${DateTime.now().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (widget.userRole == UserRole.admin)
              ElevatedButton.icon(
                onPressed: _downloadPdfReport,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Preuzmi PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            if (widget.userRole == UserRole.admin)
              const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Osveži'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadPdfReport() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preuzimanje PDF izvještaja...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get PDF bytes
      final pdfBytes = await _financialService.getFinancialReportPdfBytes();

      // Ask user where to save the file
      final fileName = 'Finansijski_izvjestaj_${DateTime.now().toString().replaceAll(':', '-').substring(0, 19).replaceAll(' ', '_')}.pdf';
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sačuvaj finansijski izvještaj',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        // Save the file
        final file = File(outputFile);
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF izvještaj je sačuvan: $outputFile'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Čuvanje otkazano'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri preuzimanju PDF-a: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildAdminDashboard(FinancialSummary data) {
    return Column(
      children: [
        // KPI kartice
        _buildKPICards(data),
        const SizedBox(height: 32),
        
        // Grafikoni
        Row(
          children: [
            Expanded(child: _buildRevenueChart(data.dailyRevenueChart)),
            const SizedBox(width: 16),
            Expanded(child: _buildServicesPieChart(_adminRevenueByServices ?? data.revenueByService)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Tabele
        Row(
          children: [
            Expanded(child: _buildTopClientsTable(data.topClients)),
            const SizedBox(width: 16),
            Expanded(child: _buildServicesTable(_adminRevenueByServices ?? data.revenueByService)),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueBarChart(List<DailyRevenue> data) {
    // Ako nema podataka ili su svi podaci 0, generiši mock podatke
    final hasRealData = data.isNotEmpty && data.any((d) => d.revenue > 0);
    final chartData = hasRealData ? data : _generateMockDailyRevenue();

    final maxY = chartData.isEmpty
        ? 0.0
        : chartData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) * 1.1;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ukupni dnevni prihodi (zadnjih 60 dana)${!hasRealData ? " - Primjer podataka" : ""}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'No revenue data available',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < chartData.length) {
                                final date = chartData[value.toInt()].date;
                                return Text('${date.day}/${date.month}');
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text('${(value / 1000).toStringAsFixed(0)}k');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: chartData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.revenue,
                              color: Colors.green,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianDashboard(VeterinarianStats data) {
    return Column(
      children: [
        // Lične KPI kartice
        _buildVetKPICards(data),
        const SizedBox(height: 32),
        
        // Grafikoni
        Row(
          children: [
            Expanded(child: _buildMyAppointmentsChart(data.myDailyAppointments)),
            const SizedBox(width: 16),
            Expanded(child: _buildMyServicesPieChart(data.myTopServices)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Tabela mojih pacijenata
        _buildMyPatientsTable(data.myRecentPatients),
      ],
    );
  }

  Widget _buildKPICards(FinancialSummary data) {
    return Row(
      children: [
        Expanded(child: _buildKPICard(
          'Dnevni prihod',
          '${data.dailyRevenue.toStringAsFixed(0)} BAM',
          Icons.today,
          Colors.green,
          '${data.dailyAppointments} termina',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'Mjesečni prihod',
          '${data.monthlyRevenue.toStringAsFixed(0)} BAM',
          Icons.calendar_month,
          Colors.blue,
          '${data.monthlyGrowth > 0 ? "+" : ""}${data.monthlyGrowth.toStringAsFixed(1)}%',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'Prosječni termin',
          '${data.averageAppointmentValue.toStringAsFixed(0)} BAM',
          Icons.payments,
          Colors.orange,
          'Prosječno',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'Godišnji rast',
          '${data.yearlyGrowth.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
          'u odnosu na prošlu godinu',
        )),
      ],
    );
  }

  Widget _buildVetKPICards(VeterinarianStats data) {
    return Row(
      children: [
        Expanded(child: _buildKPICard(
          'Appointments Today',
          '${data.myAppointmentsToday}',
          Icons.today,
          Colors.blue,
          'Moji termini',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'This Week',
          '${data.myAppointmentsWeek}',
          Icons.date_range,
          Colors.green,
          'termina',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'My Patients',
          '${data.myTotalPatients}',
          Icons.pets,
          Colors.orange,
          'total',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildKPICard(
          'Average Rating',
          '${data.myAverageRating.toStringAsFixed(1)} ⭐',
          Icons.star,
          Colors.amber,
          'from clients',
        )),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<DailyRevenue> data) {
    // Ako nema podataka ili su svi podaci 0, generiši mock podatke
    final hasRealData = data.isNotEmpty && data.any((d) => d.revenue > 0);
    final chartData = hasRealData ? data : _generateMockDailyRevenue();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dnevni prihod (zadnjih 60 dana)${!hasRealData ? " - Primjer podataka" : ""}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty 
              ? const Center(
                  child: Text(
                    'No revenue data available',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text('${(value / 1000).toStringAsFixed(0)}k');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < chartData.length) {
                              final date = chartData[value.toInt()].date;
                              return Text('${date.day}/${date.month}');
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value.revenue);
                        }).toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<DailyRevenue> _generateMockDailyRevenue() {
    final List<DailyRevenue> data = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final revenue = 8000 + (i * 300) + (DateTime.now().millisecond % 3000);
      
      data.add(DailyRevenue(
        date: date,
        revenue: revenue.toDouble(),
      ));
    }
    
    return data;
  }

  Widget _buildServicesPieChart(List<RevenueByService> data) {
    // Izračunaj ukupan prihod za percentage
    final totalRevenue = data.fold<double>(0, (sum, item) => sum + item.revenue);
    
    // Kreiraj podatke sa izračunatim percentage
    final chartData = data.map((item) {
      final percentage = totalRevenue > 0 ? (item.revenue / totalRevenue) * 100 : 0.0;
      return MapEntry(item, percentage);
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.userRole == UserRole.admin 
              ? 'Ukupni prihod po uslugama (svi veterinari)'
              : 'Prihod po uslugama',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty 
              ? const Center(
                  child: Text(
                    'No service data available',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: chartData.asMap().entries.map((entry) {
                            final colors = [
                              const Color(0xFF2196F3), // Plava
                              const Color(0xFF4CAF50), // Zelena  
                              const Color(0xFFFF9800), // Narandžasta
                              const Color(0xFFE91E63), // Roza
                              const Color(0xFF9C27B0), // Ljubičasta
                            ];
                            final percentage = entry.value.value;
                            return PieChartSectionData(
                              value: percentage,
                              title: '${percentage.toStringAsFixed(1)}%',
                              color: colors[entry.key % colors.length],
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: chartData.asMap().entries.map((entry) {
                            final colors = [
                              const Color(0xFF2196F3), // Plava
                              const Color(0xFF4CAF50), // Zelena  
                              const Color(0xFFFF9800), // Narandžasta
                              const Color(0xFFE91E63), // Roza
                              const Color(0xFF9C27B0), // Ljubičasta
                            ];
                            final service = entry.value.key;
                            final percentage = entry.value.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[entry.key % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          service.serviceName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${service.revenue.toStringAsFixed(0)} BAM (${service.count} termina)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAppointmentsChart(List<DailyRevenue> data) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Appointments by Day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: data.isEmpty 
              ? const Center(
                  child: Text(
                    'No appointment data available',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.map((e) => e.appointments.toDouble()).reduce((a, b) => a > b ? a : b) + 2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.length) {
                          final date = data[value.toInt()].date;
                          return Text('${date.day}/${date.month}');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.appointments.toDouble(),
                        color: Colors.blue,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMyServicesPieChart(List<RevenueByService> data) {
    return _buildServicesPieChart(data); // Ista logika kao admin pie chart
  }

  Widget _buildTopClientsTable(List<TopClient> clients) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Najbolji klijenti',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...clients.map((client) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(client.clientName[0], style: const TextStyle(color: Colors.blue)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.clientName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${client.appointmentCount} termina', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${client.totalSpent.toStringAsFixed(0)} BAM',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildServicesTable(List<RevenueByService> services) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.userRole == UserRole.admin 
              ? 'Ukupni prihod po uslugama (svi veterinari)'
              : 'Usluge po prihodu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: services.map((service) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service.serviceName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${service.appointmentCount} termina',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${service.revenue.toStringAsFixed(0)} BAM',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${service.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPatientsTable(List<PatientInfo> patients) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Recent Patients',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...patients.map((patient) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.pets, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${patient.petName} (${patient.species})', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Owner: ${patient.ownerName}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(patient.lastService, style: const TextStyle(fontSize: 12)),
                    Text(
                      '${patient.lastVisit.day}/${patient.lastVisit.month}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}



