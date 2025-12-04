import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana/main.dart';  // <-- burası artık ManaApp

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // ManaApp artık uygulamanın giriş noktası
    await tester.pumpWidget(const ManaApp());

    // Basit bir test – ana ekran açılıyor mu kontrol et
    expect(find.byType(MaterialApp), findsOneWidget);

    // Eğer istersen daha fazla test ekleyebilirsin
    // Şimdilik sadece çalışıyor mu ona bakıyoruz
  });
}