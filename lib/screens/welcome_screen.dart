import 'package:flutter/material.dart';
import 'main_wrapper.dart'; // Pastikan import ini sesuai dengan project Anda

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // Data Konten Onboarding (Teks & Gambar)
  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "Track Your Goal",
      description:
          "Don't worry if you have trouble determining your goals, We can help you determine your goals and track your goals",
      image: "assets/images/onboarding1.png", // Ganti dengan path aset Anda
      placeholderIcon: Icons.flag_circle, // Icon pengganti jika gambar belum ada
    ),
    OnboardingContent(
      title: "Get Burn",
      description:
          "Let’s keep burning, to achieve yours goals, it hurts only temporarily, if you give up now you will be in pain forever",
      image: "assets/images/onboarding2.png",
      placeholderIcon: Icons.local_fire_department,
    ),
    OnboardingContent(
      title: "Eat Well",
      description:
          "Let's start a healthy lifestyle with us, we can determine your diet every day. healthy eating is fun",
      image: "assets/images/onboarding3.png",
      placeholderIcon: Icons.restaurant,
    ),
    OnboardingContent(
      title: "Morning Yoga",
      description:
          "Let's start a healthy lifestyle with us, we can determine your diet every day. healthy eating is fun",
      image: "assets/images/onboarding4.png",
      placeholderIcon: Icons.self_improvement,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Warna tema gradasi biru (diambil dari sampel gambar)
    final Color colorStart = const Color(0xFF9DCEFF);
    final Color colorEnd = const Color(0xFF92A3FD);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Gradient & Wave (Bagian Atas)
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorStart, colorEnd],
              ),
            ),
          ),
          
          // 2. Konten PageView
          PageView.builder(
            controller: _controller,
            itemCount: _contents.length,
            onPageChanged: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(context, _contents[index]);
            },
          ),

          // 3. Tombol Next dengan Progress Indicator
          Positioned(
            bottom: 40,
            right: 30,
            child: _buildNextButton(colorEnd),
          ),
        ],
      ),
    );
  }

  // Widget untuk setiap halaman
  Widget _buildPage(BuildContext context, OnboardingContent content) {
    return Column(
      children: [
        // Bagian Atas (Gambar/Ilustrasi)
        Expanded(
          flex: 6, // Porsi 60% layar
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave Putih (Custom Clipper)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: OnboardingWaveClipper(),
                  child: Container(
                    height: 150,
                    color: Colors.white,
                  ),
                ),
              ),
              // Gambar Ilustrasi
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: content.image.contains('assets') 
                    // Gunakan Icon besar sbg placeholder jika asset belum diset
                    ? Icon(content.placeholderIcon, size: 200, color: Colors.white.withOpacity(0.9))
                    : Image.asset(content.image, width: 300), 
              ),
            ],
          ),
        ),

        // Bagian Bawah (Teks)
        Expanded(
          flex: 4, // Porsi 40% layar
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  content.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget Tombol Next Melayang
  Widget _buildNextButton(Color themeColor) {
    // Hitung progress (0.25, 0.50, 0.75, 1.0)
    double progress = (_currentIndex + 1) / _contents.length;

    return GestureDetector(
      onTap: () {
        if (_currentIndex == _contents.length - 1) {
          // Jika halaman terakhir, pindah ke Home/MainWrapper
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        } else {
          // Jika belum, geser ke halaman berikutnya
          _controller.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lingkaran Progress Biru
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            // Tombol Bulat Tengah
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [const Color(0xFF9DCEFF), themeColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model Data Sederhana
class OnboardingContent {
  final String title;
  final String description;
  final String image;
  final IconData placeholderIcon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
    required this.placeholderIcon,
  });
}

// Custom Clipper untuk membuat efek gelombang (Wave) di tengah layar
class OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Mulai dari kiri bawah
    path.lineTo(0, size.height); 
    // Garis ke kanan bawah
    path.lineTo(size.width, size.height);
    // Garis naik ke kanan tengah (sedikit turun)
    path.lineTo(size.width, 50); 
    
    // Kurva Bezier untuk membuat gelombang halus
    var firstControlPoint = Offset(size.width * 0.75, 0);
    var firstEndPoint = Offset(size.width * 0.5, 40);
    
    var secondControlPoint = Offset(size.width * 0.25, 80);
    var secondEndPoint = Offset(0, 50);

    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, 
        firstEndPoint.dx, firstEndPoint.dy);
        
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, 
        secondEndPoint.dx, secondEndPoint.dy);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}