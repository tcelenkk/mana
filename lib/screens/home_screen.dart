import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  List<QueryDocumentSnapshot> words = [];
  int currentIndex = 0;
  int swipeCount = 0;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;

  final ScreenshotController _screenshotController = ScreenshotController();
  Set<String> likedWordIds = {};
  Map<String, int> wordLikeCounts = {}; // Firestore'dan gerçek beğeni sayısı

  bool _isOnline = true;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkInternetAndLoad();

    Connectivity().onConnectivityChanged.listen((result) {
      final bool nowOnline = !result.contains(ConnectivityResult.none);
      if (nowOnline != _isOnline) {
        setState(() => _isOnline = nowOnline);
        if (nowOnline) _reloadEverything();
      }
    });
  }

  Future<void> _checkInternetAndLoad() async {
    final result = await Connectivity().checkConnectivity();
    final bool online = !result.contains(ConnectivityResult.none);
    setState(() => _isOnline = online);
    if (online) await _loadEverything();
  }

  Future<void> _reloadEverything() async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    await _loadEverything();
  }

  Future<void> _loadEverything() async {
    await Future.wait([_loadWords(), _loadUserLikes()]);
    _initAds();
  }

  Future<void> _loadWords() async {
    final snapshot = await FirebaseFirestore.instance.collection('words').get();
    if (!mounted) return;

    setState(() {
      words = snapshot.docs..shuffle();
      // Gerçek beğeni sayılarını çek
      wordLikeCounts = {
        for (var doc in words) doc.id: (doc.data() as Map<String, dynamic>)['likes'] ?? 0
      };
    });
  }

  Future<void> _loadUserLikes() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('likes')
        .get();
    if (mounted) {
      setState(() => likedWordIds = snapshot.docs.map((e) => e.id).toSet());
    }
  }

  void _initAds() {
    // Banner
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();

    // HER SEFERİNDE YENİ INTERSTITIAL YÜKLE
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void _showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial(); // YENİ REKLAM YÜKLE
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  Future<void> _toggleLike(String wordId, DocumentReference ref, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (isLiked) {
      // Beğeniyi kaldır
      await FirebaseFirestore.instance.runTransaction((t) async {
        t.update(ref, {'likes': FieldValue.increment(-1)});
        t.delete(FirebaseFirestore.instance.collection('users').doc(uid).collection('likes').doc(wordId));
      });
      setState(() {
        likedWordIds.remove(wordId);
        wordLikeCounts[wordId] = (wordLikeCounts[wordId] ?? 1) - 1;
        if (wordLikeCounts[wordId]! < 0) wordLikeCounts[wordId] = 0;
      });
    } else {
      // Beğen
      await FirebaseFirestore.instance.runTransaction((t) async {
        t.update(ref, {'likes': FieldValue.increment(1)});
        t.set(FirebaseFirestore.instance.collection('users').doc(uid).collection('likes').doc(wordId), {'t': FieldValue.serverTimestamp()});
      });
      setState(() {
        likedWordIds.add(wordId);
        wordLikeCounts[wordId] = (wordLikeCounts[wordId] ?? 0) + 1;
        _showLikeAnimation = true;
      });

      // Animasyonu kapat
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showLikeAnimation = false);
      });
    }
  }

  Future<void> _shareWord(Map<String, dynamic> word) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final image = await _screenshotController.captureFromWidget(
    Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF171717), const Color(0xFF000000)]
              : [const Color(0xFFFFF8F0), const Color(0xFFFBE8D8), const Color(0xFFF5D5C0)],
        ),
      ),
      child: Stack(
        children: [
          // Kelime + anlam
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    word['word'],
                    style: const TextStyle(fontFamily: 'Ahkio', fontSize: 48, color: Color(0xFFCB312A)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    word['definition'],
                    style: TextStyle(fontFamily: 'Ubuntu', fontSize: 24, color: isDark ? Colors.white : Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // SOL ALT: LOGO + YAZI
          Positioned(
  left: 16,
  bottom: 16,
  child: Row(
    children: [
      Image.asset("assets/images/app_stores.png", height: 24, fit: BoxFit.contain),
      const SizedBox(width: 9),
Text(
  "Mânâ App",
  style: TextStyle(
    fontFamily: 'Ubuntu',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87,
    letterSpacing: 0.3,
    shadows: isDark ? null : [const Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black26)],
  ),
),
    ],
  ),
),
        ],
      ),
    ),
    pixelRatio: 3.0, // daha net görüntü için
  );

  await Share.shareXFiles(
    [XFile.fromData(image, mimeType: 'image/png', name: 'mana.png')],
    text: "Mânâ’dan: ${word['word']}\n${word['definition']}\n\nGoogle Play ve App Store’da: Mânâ",
  );
}

  @override
  void dispose() {
    _pageController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo.png", width: 140, height: 140, color: Colors.white70),
              const SizedBox(height: 30),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(colors: [Color(0xFFCB312A), Color(0xFFFF6B6B)]).createShader(rect),
                child: const Icon(Icons.wifi_off_rounded, size: 110, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const Text("İnternet bağlantısı gerekli", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text("Mânâ’yı kullanmak için lütfen internete bağlanın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 17))),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _checkInternetAndLoad,
                icon: const Icon(Icons.refresh_rounded, size: 28),
                label: const Text("Tekrar Dene", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB312A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 10),
              ),
            ],
          ),
        ),
      );
    }

    if (words.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFCB312A))));
    }

    final currentDoc = words[currentIndex % words.length];
    final data = currentDoc.data() as Map<String, dynamic>;
    final wordId = currentDoc.id;
    final isLiked = likedWordIds.contains(wordId);
    final likeCount = wordLikeCounts[wordId] ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          // GRADIENT ARKA PLAN
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0A0A0A), const Color(0xFF171717), const Color(0xFF000000)]
                      : [const Color(0xFFFFF8F0), const Color(0xFFFBE8D8), const Color(0xFFF5D5C0)],
                ),
              ),
              child: Image.asset("assets/images/noise.png", repeat: ImageRepeat.repeat, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.06)),
            ),
          ),

          // Kelimeler
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              HapticFeedback.lightImpact();
              setState(() => currentIndex = i % words.length);
              if (++swipeCount >= 12) {
                swipeCount = 0;
                _showInterstitial();
                _loadInterstitial(); // HEMEN YENİSİNİ YÜKLE
              }
            },
            itemBuilder: (_, i) {
              final d = words[i % words.length].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(d['word'] ?? '', style: const TextStyle(fontFamily: 'Ahkio', fontSize: 58, color: Color(0xFFCB312A), height: 1.1), textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            Text(d['definition'] ?? '', style: TextStyle(fontFamily: 'Ubuntu', fontSize: 26, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, height: 1.5), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),

          // PAYLAŞ + BEĞEN
          // PAYLAŞ + BEĞEN (OVERFLOW HATASI YOK!)
// PAYLAŞ + BEĞEN (Sadece kalp ve sayı kısmı)
Positioned(
  bottom: 100,
  left: 0,
  right: 0,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        onPressed: () => _shareWord(data),
        icon: const Icon(FontAwesomeIcons.arrowUpFromBracket, color: Colors.white, size: 38),
      ),
      const SizedBox(width: 70),

      // SADECE KALP + SAYI (animasyon artık ekran ortasında)
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _toggleLike(wordId, currentDoc.reference, isLiked),
            icon: Icon(
              isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              color: isLiked ? Colors.red : Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$likeCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ),
        ],
      ),
    ],
  ),
),



// YENİ TEMA BUTONU — 0 HATA, 0 UYARI, ULTRA ŞIK
// TEMA BUTONU — %100 GÖRÜNEN, ULTRA ŞIK, 0 HATA

// TEMA BUTONU — FONTAWESOME, %100 GÖZÜKÜR, ULTRA ŞIK
// TEMA BUTONU — SADECE İKON, HİÇBİR ARKA PLAN YOK, MİNİMAL VE ŞIK
Positioned(
  top: MediaQuery.of(context).padding.top + 20,
  right: 20,
  child: Consumer<ThemeProvider>(
    builder: (_, theme, _) => GestureDetector(
      onTap: theme.toggleTheme,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: animation,
            child: child,
          ),
        ),
        child: Icon(
          theme.isDark 
              ? FontAwesomeIcons.solidSun 
              : FontAwesomeIcons.solidMoon,
          key: ValueKey(theme.isDark),
          color: theme.isDark 
              ? const Color(0xFFFFB300)     // Koyu mod: Açık sarı ay
              : const Color(0xFF9BB1FF),    // Açık mod: Canlı turuncu güneş
          size: 34,  // büyük ve net
        ),
      ),
    ),
  ),
),

// YENİ: EKRAN ORTASINDA BÜYÜK KALP PATLAMASI (EN ÜST KATMAN)
if (_showLikeAnimation)
  Center(
    child: Lottie.asset(
      'assets/lottie/heart_burst.json',
      width: 380,
      height: 380,
      fit: BoxFit.contain,
      repeat: false,
      onLoaded: (composition) {
        Future.delayed(composition.duration, () {
          if (mounted) setState(() => _showLikeAnimation = false);
        });
      },
    ),
  ),


          // Reklam
          if (_isBannerLoaded && _bannerAd != null)
            Align(alignment: Alignment.bottomCenter, child: SizedBox(width: double.infinity, height: 76, child: AdWidget(ad: _bannerAd!))),
        ],
      ),
    );
  }
}