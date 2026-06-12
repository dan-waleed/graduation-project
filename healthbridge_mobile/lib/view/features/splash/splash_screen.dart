import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/view/widgets/hb_university_brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const routeName = 'splash';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E5C4A), Color(0xFF177864)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              HbUniversityLogo(size: 92, surfaceColor: Colors.white),
              SizedBox(height: 18),
              Text(
                'هيلث بريدج',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'جامعة بوليتكنك فلسطين',
                style: TextStyle(
                  color: Color(0xFFF3FBF8),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'نظام الوصفات الطبية الإلكترونية الجامعي',
                style: TextStyle(color: Color(0xFFE7F7F2), fontSize: 15),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  color: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              SizedBox(height: 14),
              Text(
                'جاري التحقق من حالة تسجيل الدخول...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
