import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:provider/provider.dart';
import '../providers/data_pohon_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report/treemapping_report.dart'; // Import halaman report

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.putihKebiruan,
      body: SafeArea(
        child: Consumer<DataPohonProvider>(
          builder: (context, provider, _) {
            String greeting() {
              final hour = DateTime.now().hour;
              if (hour >= 4 && hour < 11) return "Selamat Pagi";
              if (hour >= 11 && hour < 15) return "Selamat Siang";
              if (hour >= 15 && hour < 18) return "Selamat Sore";
              return "Selamat Malam";
            }
            final pohonList = provider.pohonList;
            final totalPohon = pohonList.length;
            final prioritasTinggi = pohonList.where((p) => p.prioritas == 3).length;
            final prioritasSedang = pohonList.where((p) => p.prioritas == 2).length;
            final prioritasRendah = pohonList.where((p) => p.prioritas == 1).length;
            final tebangHabis = pohonList.where((p) => p.tujuanPenjadwalan == 2).length;
            final tebangPangkas = pohonList.where((p) => p.tujuanPenjadwalan == 1).length;

            // Ambil nama dari session SharedPreferences dengan FutureBuilder

            return Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.04, horizontal: screenWidth * 0.06),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealGelap, AppColors.cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.09,
                        backgroundColor: AppColors.white,
                        child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain, width: screenWidth * 0.13),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLN JagaGRID', style: TextStyle(fontSize: screenWidth * 0.065, fontWeight: FontWeight.bold, color: AppColors.yellow, fontFamily: 'Poppins')),
                            SizedBox(height: 6),
                            FutureBuilder<SharedPreferences>(
                              future: SharedPreferences.getInstance(),
                              builder: (context, snapshot) {
                                final userName = snapshot.data?.getString('session_name') ?? '';
                                return Text(
                                  'Hi, $userName',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.055,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                );
                              },
                            ),
                            Text(greeting(), style: TextStyle(fontSize: screenWidth * 0.045, color: AppColors.white.withOpacity(0.9), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // STATISTIK CARD
                GestureDetector(
                  onTap: () {
                    // Klik total pohon atau prioritas, navigasi ke report dengan filter sesuai
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeMappingReportPage(filterType: 'total_pohon'),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: screenHeight * 0.018),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statInfoTile('Total Pohon', totalPohon, AppColors.tealGelap, Icons.eco_outlined, screenWidth),
                        Container(width: 1, height: screenHeight * 0.06, color: AppColors.grey.withOpacity(0.2)),
                        _statInfoTile('Prioritas', prioritasTinggi + prioritasSedang + prioritasRendah, AppColors.yellow, Icons.star, screenWidth),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // GRID STATISTIK
                Expanded(
                  child: Container(
                    width: double.infinity,
                    // background dihilangkan, hanya borderRadius agar grid tetap rapi
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: screenHeight * 0.02,
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                        bottom: screenHeight * 0.04,
                      ),
                      child: _buildStatsGridAktual(
                        context,
                        screenWidth,
                        screenHeight,
                        totalPohon,
                        prioritasTinggi,
                        prioritasSedang,
                        prioritasRendah,
                        tebangHabis,
                        tebangPangkas,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // _buildLegendItem dihapus
  Widget _statInfoTile(String label, int value, Color color, IconData icon, double screenWidth) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.018),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: screenWidth * 0.06),
        ),
        SizedBox(height: 6),
        Text('$value', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: screenWidth * 0.03, color: AppColors.grey, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildStatsGridAktual(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    int totalPohon,
    int prioritasTinggi,
    int prioritasSedang,
    int prioritasRendah,
    int tebangHabis,
    int tebangPangkas,
  ) {
    // Styling baru: grid 2 kolom, card gradient, icon besar, animasi angka, efek tap
    final stats = [
      {
        'label': 'Total Pohon',
        'value': totalPohon,
        'icon': Icons.eco_outlined,
        'color1': Color(0xFF2193b0), // biru gradasi
        'color2': Color(0xFF6dd5ed),
        'filter': 'total_pohon',
      },
      {
        'label': 'Prioritas Tinggi',
        'value': prioritasTinggi,
        'icon': Icons.warning_amber_outlined,
        'color1': Color(0xFF2193b0),
        'color2': Color(0xFF6dd5ed),
        'filter': 'high_priority',
      },
      {
        'label': 'Tebang Habis',
        'value': tebangHabis,
        'icon': Icons.delete_forever_outlined,
        'color1': Color(0xFF2193b0),
        'color2': Color(0xFF6dd5ed),
        'filter': 'tebang_habis',
      },
      {
        'label': 'Prioritas Sedang',
        'value': prioritasSedang,
        'icon': Icons.error_outline,
        'color1': Color(0xFF2193b0),
        'color2': Color(0xFF6dd5ed),
        'filter': 'medium_priority',
      },
      {
        'label': 'Tebang Pangkas',
        'value': tebangPangkas,
        'icon': Icons.content_cut_outlined,
        'color1': Color(0xFF2193b0),
        'color2': Color(0xFF6dd5ed),
        'filter': 'tebang_pangkas',
      },
      {
        'label': 'Prioritas Rendah',
        'value': prioritasRendah,
        'icon': Icons.low_priority_outlined,
        'color1': Color(0xFF2193b0),
        'color2': Color(0xFF6dd5ed),
        'filter': 'low_priority',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenHeight * 0.012,
        childAspectRatio: 1.45, // lebih ramping agar tidak terpotong
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final stat = stats[i];
        return _AnimatedStatCard(
          label: stat['label'] as String,
          value: stat['value'] as int,
          icon: stat['icon'] as IconData,
          color1: stat['color1'] as Color,
          color2: stat['color2'] as Color,
          screenWidth: screenWidth,
          filterType: stat['filter'] as String,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TreeMappingReportPage(filterType: stat['filter'] as String),
              ),
            );
          },
        );
      },
    );
  }

  // Card statistik baru dengan animasi dan gradient
}

class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color1;
  final Color color2;
  final double screenWidth;
  final String filterType;
  final VoidCallback onTap;
  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.screenWidth,
    required this.filterType,
    required this.onTap,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _animation = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1),
        padding: EdgeInsets.symmetric(
          horizontal: widget.screenWidth * 0.015,
          vertical: widget.screenWidth * 0.015,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color1.withOpacity(0.85), widget.color2.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: widget.color2.withOpacity(0.10), blurRadius: 5, offset: Offset(0, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(widget.screenWidth * 0.012),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: widget.screenWidth * 0.055),
              ),
            ),
            SizedBox(height: 6),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Text(
                '${_animation.value}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: widget.screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 2),
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: widget.screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}