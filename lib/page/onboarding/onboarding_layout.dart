// onboarding_layout.dart (Main file dengan model)
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../navigation_menu.dart';
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => NavigationMenu()),
      );
    }
  }
}

// Widget Layout
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

    return Column(
      children: [
        // Content section (title + main content)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Top section with title
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        content.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom section with content
              Expanded(
                flex: 4,
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image with circular background
                        Container(
                          width: 280,
                          height: 280,
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
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                                // Additional icon if exists
                                if (content.additionalIcon != null) content.additionalIcon!,
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Description text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            content.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.darkGrey,
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom navigation section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.putihKebiruan,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button (only show if not first page)
                if (!isFirstPage)
                  GestureDetector(
                    onTap: onPrevious,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Kembali',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80), // Placeholder for alignment
                
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < totalPages; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tealGelap,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      isLastPage ? 'Mulai' : 'Selanjutnya',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}