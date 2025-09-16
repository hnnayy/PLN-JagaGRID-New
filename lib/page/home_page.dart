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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    final isLargeScreen = screenWidth >= 400;

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

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // HEADER - Responsif berdasarkan ukuran layar
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * (isSmallScreen ? 0.025 : isMediumScreen ? 0.035 : 0.04),
                          horizontal: screenWidth * (isSmallScreen ? 0.04 : 0.06),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.tealGelap, AppColors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(isSmallScreen ? 24 : 32),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * (isSmallScreen ? 0.07 : isMediumScreen ? 0.08 : 0.09),
                              backgroundColor: AppColors.white,
                              child: Image.asset(
                                'assets/logo/logo.png',
                                fit: BoxFit.contain,
                                width: screenWidth * (isSmallScreen ? 0.10 : isMediumScreen ? 0.12 : 0.13),
                              ),
                            ),
                            SizedBox(width: screenWidth * (isSmallScreen ? 0.03 : 0.04)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'PLN JagaGRID',
                                      style: TextStyle(
                                        fontSize: screenWidth * (isSmallScreen ? 0.055 : isMediumScreen ? 0.06 : 0.065),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.yellow,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  FutureBuilder<SharedPreferences>(
                                    future: SharedPreferences.getInstance(),
                                    builder: (context, snapshot) {
                                      final userName = snapshot.data?.getString('session_name') ?? '';
                                      return FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Hi, $userName',
                                          style: TextStyle(
                                            fontSize: screenWidth * (isSmallScreen ? 0.045 : isMediumScreen ? 0.05 : 0.055),
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      greeting(),
                                      style: TextStyle(
                                        fontSize: screenWidth * (isSmallScreen ? 0.035 : isMediumScreen ? 0.04 : 0.045),
                                        color: AppColors.white.withOpacity(0.9),
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * (isSmallScreen ? 0.015 : 0.02)),
                      
                      // STATISTIK CARD - Responsif
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TreeMappingReportPage(filterType: 'total_pohon'),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * (isSmallScreen ? 0.05 : 0.07),
                            vertical: screenHeight * (isSmallScreen ? 0.015 : 0.018),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * (isSmallScreen ? 0.05 : 0.07),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _statInfoTile(
                                    'Total Pohon',
                                    totalPohon,
                                    AppColors.tealGelap,
                                    Icons.eco_outlined,
                                    screenWidth,
                                    isSmallScreen,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: AppColors.grey.withOpacity(0.2),
                                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                ),
                                Expanded(
                                  child: _statInfoTile(
                                    'Prioritas',
                                    prioritasTinggi + prioritasSedang + prioritasRendah,
                                    AppColors.yellow,
                                    Icons.star,
                                    screenWidth,
                                    isSmallScreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (isSmallScreen ? 0.015 : 0.02)),
                      
                      // GRID STATISTIK - Responsif
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 0.4,
                        ),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: screenHeight * (isSmallScreen ? 0.015 : 0.02),
                            left: screenWidth * (isSmallScreen ? 0.03 : 0.04),
                            right: screenWidth * (isSmallScreen ? 0.03 : 0.04),
                            bottom: screenHeight * (isSmallScreen ? 0.02 : 0.04),
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
                            isSmallScreen,
                            isMediumScreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statInfoTile(String label, int value, Color color, IconData icon, double screenWidth, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * (isSmallScreen ? 0.015 : 0.018)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          child: Icon(
            icon,
            color: color,
            size: screenWidth * (isSmallScreen ? 0.05 : 0.06),
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        FittedBox(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: screenWidth * (isSmallScreen ? 0.045 : 0.05),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * (isSmallScreen ? 0.025 : 0.03),
              color: AppColors.grey,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
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
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    final stats = [
      {
        'label': 'Total Pohon',
        'value': totalPohon,
        'icon': Icons.eco_outlined,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'total_pohon',
      },
      {
        'label': 'Prioritas Tinggi',
        'value': prioritasTinggi,
        'icon': Icons.warning_amber_outlined,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'high_priority',
      },
      {
        'label': 'Tebang Habis',
        'value': tebangHabis,
        'icon': Icons.delete_forever_outlined,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'tebang_habis',
      },
      {
        'label': 'Prioritas Sedang',
        'value': prioritasSedang,
        'icon': Icons.error_outline,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'medium_priority',
      },
      {
        'label': 'Tebang Pangkas',
        'value': tebangPangkas,
        'icon': Icons.content_cut_outlined,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'tebang_pangkas',
      },
      {
        'label': 'Prioritas Rendah',
        'value': prioritasRendah,
        'icon': Icons.low_priority_outlined,
        'color1': const Color(0xFF2193b0),
        'color2': const Color(0xFF6dd5ed),
        'filter': 'low_priority',
      },
    ];

    // Menentukan aspect ratio berdasarkan ukuran layar
    double aspectRatio;
    if (isSmallScreen) {
      aspectRatio = 1.2;
    } else if (isMediumScreen) {
      aspectRatio = 1.35;
    } else {
      aspectRatio = 1.45;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: screenWidth * (isSmallScreen ? 0.015 : 0.02),
        mainAxisSpacing: screenHeight * (isSmallScreen ? 0.01 : 0.012),
        childAspectRatio: aspectRatio,
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
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
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
}

class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color1;
  final Color color2;
  final double screenWidth;
  final String filterType;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final VoidCallback onTap;

  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.screenWidth,
    required this.filterType,
    required this.isSmallScreen,
    required this.isMediumScreen,
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
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
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: EdgeInsets.symmetric(
          horizontal: widget.screenWidth * (widget.isSmallScreen ? 0.01 : 0.015),
          vertical: widget.screenWidth * (widget.isSmallScreen ? 0.01 : 0.015),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color1.withOpacity(0.85),
              widget.color2.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(widget.isSmallScreen ? 10 : 14),
          boxShadow: [
            BoxShadow(
              color: widget.color2.withOpacity(0.10),
              blurRadius: 5,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(
                  widget.screenWidth * (widget.isSmallScreen ? 0.008 : widget.isMediumScreen ? 0.01 : 0.012),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.screenWidth * (widget.isSmallScreen ? 0.045 : widget.isMediumScreen ? 0.05 : 0.055),
                ),
              ),
            ),
            SizedBox(height: widget.isSmallScreen ? 4 : 6),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => FittedBox(
                child: Text(
                  '${_animation.value}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.055 : widget.isMediumScreen ? 0.06 : 0.065),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.isSmallScreen ? 1 : 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.028 : widget.isMediumScreen ? 0.032 : 0.035),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}