import 'package:flutter/material.dart';

class InternetWarning extends StatelessWidget {
  const InternetWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              "Bu uygulamayı kullanabilmeniz için internete bağlı olmalısınız.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}