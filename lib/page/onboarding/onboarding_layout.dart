import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';
import '../../navigation_menu.dart';
import '../login/login.dart';
import 'onboarding1.dart';
import 'onboarding2.dart';
import 'onboarding3.dart';

// Model class langsung di file ini
class OnboardingContentModel {
  final String title;
  final String description;
  final String imagePath;
  final Widget? additionalIcon;

  const OnboardingContentModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.additionalIcon,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController pageController = PageController();
  int currentIndex = 0;

  // List content data
  final List<OnboardingContentModel> contentData = [
    Onboarding1.data,
    Onboarding2.data,
    Onboarding3.data,
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginAndOnboardingStatus();
  }

  Future<void> _checkLoginAndOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('session_id');
    final sessionTimestamp = prefs.getInt('session_timestamp') ?? 0;
    final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (sessionId != null && sessionId.isNotEmpty && 
        (currentTime - sessionTimestamp) < 24 * 60 * 60 * 1000 && 
        hasCompletedOnboarding) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationMenu()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tealGelap,
              AppColors.cyan,
            ],
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemCount: contentData.length,
            itemBuilder: (context, index) {
              return OnboardingLayout(
                content: contentData[index],
                currentIndex: currentIndex,
                totalPages: contentData.length,
                onPrevious: _onPrevious,
                onNext: _onNext,
              );
            },
          ),
        ),
      ),
    );
  }

  void _onPrevious() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (currentIndex < contentData.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

// Widget Layout - RESPONSIVE VERSION
class OnboardingLayout extends StatelessWidget {
  final OnboardingContentModel content;
  final int currentIndex;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const OnboardingLayout({
    super.key,
    required this.content,
    required this.currentIndex,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFirstPage = currentIndex == 0;
    final bool isLastPage = currentIndex == totalPages - 1;
    
    // Get screen size untuk responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive values berdasarkan ukuran layar
    final titleFontSize = screenWidth < 350 ? 24.0 : (screenWidth < 400 ? 26.0 : 28.0);
    final descriptionFontSize = screenWidth < 350 ? 13.0 : 14.0;
    final imageSize = screenWidth < 350 ? 160.0 : (screenWidth < 400 ? 180.0 : 200.0);
    final containerSize = imageSize + 80;
    final horizontalPadding = screenWidth < 350 ? 16.0 : (screenWidth < 400 ? 20.0 : 24.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                // Content section (title + main content)
                Container(
                  height: constraints.maxHeight * 0.85, // 85% dari tinggi layar
                  child: Column(
                    children: [
                      // Top section with title - responsive flex
                      Expanded(
                        flex: screenHeight < 600 ? 2 : 3, // Lebih kecil untuk layar pendek
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  content.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Bottom section with content
                      Expanded(
                        flex: screenHeight < 600 ? 5 : 4, // Lebih besar untuk layar pendek
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.putihKebiruan,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(horizontalPadding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Flexible spacing
                                SizedBox(height: screenHeight < 600 ? 10 : 20),
                                
                                // Image with circular background - responsive
                                Flexible(
                                  flex: 3, // Kurangi sedikit untuk beri ruang lebih ke text
                                  child: Container(
                                    width: containerSize,
                                    height: containerSize,
                                    decoration: BoxDecoration(
                                      color: AppColors.putihKebiruan.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            content.imagePath,
                                            width: imageSize,
                                            height: imageSize,
                                            fit: BoxFit.contain,
                                          ),
                                          // Additional icon if exists
                                          if (content.additionalIcon != null) content.additionalIcon!,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Flexible spacing
                                SizedBox(height: screenHeight < 600 ? 15 : 25),
                                
                                // Description text - responsive (no text cutting)
                                Flexible(
                                  flex: 3, // Lebih besar untuk ruang text
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth < 350 ? 16 : 32
                                    ),
                                    child: Text(
                                      content.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: descriptionFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.darkGrey,
                                        height: 1.4,
                                      ),
                                      // Hilangkan maxLines dan ellipsis agar text tidak terpotong
                                    ),
                                  ),
                                ),
                                
                                // Flexible spacing
                                SizedBox(height: screenHeight < 600 ? 10 : 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom navigation section - responsive
                Container(
                  height: constraints.maxHeight * 0.15, // 15% dari tinggi layar
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.putihKebiruan,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: screenHeight < 600 ? 12 : 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button (only show if not first page)
                        if (!isFirstPage)
                          GestureDetector(
                            onTap: onPrevious,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth < 350 ? 16 : 20,
                                vertical: screenHeight < 600 ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FittedBox(
                                child: Text(
                                  'Kembali',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: screenWidth < 350 ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkGrey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(width: screenWidth < 350 ? 60 : 80), // Responsive placeholder
                        
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < totalPages; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: screenWidth < 350 ? 6 : 7,
                                height: screenWidth < 350 ? 6 : 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == currentIndex 
                                      ? AppColors.tealGelap 
                                      : AppColors.grey.withOpacity(0.3),
                                ),
                              ),
                          ],
                        ),
                        
                        // Next button
                        GestureDetector(
                          onTap: onNext,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 350 ? 16 : 20,
                              vertical: screenHeight < 600 ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tealGelap,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FittedBox(
                              child: Text(
                                isLastPage ? 'Mulai' : 'Selanjutnya',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: screenWidth < 350 ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}