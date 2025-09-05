import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:provider/provider.dart';
import '../providers/data_pohon_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.putihKebiruan,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Consumer<DataPohonProvider>(
            builder: (context, provider, _) {
              final pohonList = provider.pohonList;
              final totalPohon = pohonList.length;
              final prioritasTinggi = pohonList.where((p) => p.prioritas == 3).length;
              final prioritasSedang = pohonList.where((p) => p.prioritas == 2).length;
              final prioritasRendah = pohonList.where((p) => p.prioritas == 1).length;
              final tebangHabis = pohonList.where((p) => p.tujuanPenjadwalan == 2).length;
              final tebangPangkas = pohonList.where((p) => p.tujuanPenjadwalan == 1).length;
              // Chart dummy: Menunggu = total - (tebangHabis + tebangPangkas)
              final menunggu = totalPohon - (tebangHabis + tebangPangkas);
              // Persentase
              String percent(int value) => totalPohon == 0 ? '0%' : '${((value / totalPohon) * 100).toStringAsFixed(1)}%';

              return Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  // ...existing header code...
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth * 0.18,
                          height: screenWidth * 0.18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLN JagaGRID',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: AppColors.yellow,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hi, Welcome Back',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Good Morning',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: AppColors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Statistik
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pohon',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: AppColors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '$totalPohon',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tealGelap,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: screenHeight * 0.06,
                          color: AppColors.grey.withOpacity(0.4),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Prioritas',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: AppColors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '${prioritasTinggi + prioritasSedang + prioritasRendah}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tealGelap,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Chart + Cards
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: screenHeight * 0.03,
                        left: screenWidth * 0.03,
                        right: screenWidth * 0.03,
                        bottom: screenHeight * 0.15,
                      ),
                      child: Column(
                        children: [
                          // Chart
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.15,
                                  height: screenWidth * 0.15,
                                  child: CustomPaint(
                                    painter: DonutChartPainter(
                                      total: totalPohon,
                                      menunggu: menunggu,
                                      tebangPangkas: tebangPangkas,
                                      tebangHabis: tebangHabis,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildLegendItem('Total Pohon', percent(totalPohon), AppColors.green, screenWidth),
                                          _buildLegendItem('Ditebang', percent(tebangHabis), AppColors.pink, screenWidth),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildLegendItem('Menunggu', percent(menunggu), AppColors.orange, screenWidth),
                                          _buildLegendItem('Tebang Pangkas', percent(tebangPangkas), AppColors.blue, screenWidth),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          // Grid Statistik
                          _buildStatsGridAktual(
                            screenWidth,
                            screenHeight,
                            totalPohon,
                            prioritasTinggi,
                            prioritasSedang,
                            prioritasRendah,
                            tebangHabis,
                            tebangPangkas,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: screenWidth * 0.03, color: AppColors.grey, fontFamily: 'Poppins')),
          ],
        ),
        SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            percentage,
            style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGridAktual(
    double screenWidth,
    double screenHeight,
    int totalPohon,
    int prioritasTinggi,
    int prioritasSedang,
    int prioritasRendah,
    int tebangHabis,
    int tebangPangkas,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('$totalPohon', 'Total Pohon', Icons.eco_outlined, screenWidth)),
            SizedBox(width: screenWidth * 0.02),
            Expanded(child: _buildStatCard('$prioritasTinggi', 'Prioritas Tinggi', Icons.warning_amber_outlined, screenWidth)),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        Row(
          children: [
            Expanded(child: _buildStatCard('$tebangHabis', 'Tebang Habis', Icons.delete_forever_outlined, screenWidth)),
            SizedBox(width: screenWidth * 0.02),
            Expanded(child: _buildStatCard('$prioritasSedang', 'Prioritas Sedang', Icons.error_outline, screenWidth)),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        Row(
          children: [
            Expanded(child: _buildStatCard('$tebangPangkas', 'Tebang Pangkas', Icons.content_cut_outlined, screenWidth)),
            SizedBox(width: screenWidth * 0.02),
            Expanded(child: _buildStatCard('$prioritasRendah', 'Prioritas Rendah', Icons.low_priority_outlined, screenWidth)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: AppColors.tealGelap,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.1,
            height: screenWidth * 0.1,
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.tealGelap, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: AppColors.yellow, fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
                ),
                Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: screenWidth * 0.025)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final int total;
  final int menunggu;
  final int tebangPangkas;
  final int tebangHabis;

  DonutChartPainter({
    required this.total,
    required this.menunggu,
    required this.tebangPangkas,
    required this.tebangHabis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 12;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = (size.width / 2) - 6;
    paint.color = AppColors.grey.withOpacity(0.2);
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    double startAngle = -90 * (3.14159 / 180);
    double sweepTotal = total > 0 ? 2 * 3.14159 : 0;
    double sweepMenunggu = total > 0 ? (menunggu / total) * sweepTotal : 0;
    double sweepTebangPangkas = total > 0 ? (tebangPangkas / total) * sweepTotal : 0;
    double sweepTebangHabis = total > 0 ? (tebangHabis / total) * sweepTotal : 0;
    double sweepSisa = sweepTotal - (sweepMenunggu + sweepTebangPangkas + sweepTebangHabis);

    // Menunggu (orange)
    paint.color = AppColors.orange;
    canvas.drawArc(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius), startAngle, sweepMenunggu, false, paint);
    startAngle += sweepMenunggu;
    // Tebang Pangkas (blue)
    paint.color = AppColors.blue;
    canvas.drawArc(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius), startAngle, sweepTebangPangkas, false, paint);
    startAngle += sweepTebangPangkas;
    // Tebang Habis (pink)
    paint.color = AppColors.pink;
    canvas.drawArc(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius), startAngle, sweepTebangHabis, false, paint);
    startAngle += sweepTebangHabis;
    // Sisa (green)
    paint.color = AppColors.green;
    canvas.drawArc(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius), startAngle, sweepSisa, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
