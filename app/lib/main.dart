import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'providers/locale_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/store/store_screen.dart';
import 'core/utils/logger.dart';
import 'core/services/achievements_service.dart';
import 'core/services/admob_service.dart';
import 'core/services/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Immersive Mode (Hide OS Navigation Bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ProviderScope(child: AutoRepairAISimulatorApp()));
}

class AutoRepairAISimulatorApp extends ConsumerWidget {
  const AutoRepairAISimulatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Auto Fix AI Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Localization
      locale: locale,
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initAuthAndProfile();
  }

  Future<void> _initAuthAndProfile() async {
    try {
      // 1. Sign in anonymously
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // 2. Load profile from backend
      if (mounted) {
        await ref.read(userProfileProvider.notifier).load();

        // 3. Initialize Games Services (Play Games / Game Center)
        ref.read(achievementsServiceProvider).signIn();

        // 4. Initialize AdMob
        ref.read(adMobServiceProvider).initialize();

        // 5. Initialize and Login RevenueCat
        await RevenueCatService.init();
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await RevenueCatService.logIn(uid);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Init Error during Authentication or Profile loading',
        e,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () => setState(() => _showSplash = false),
      );
    }
    return const MainShell();
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    LeaderboardScreen(),
    StoreScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.bgElevated, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.garage),
              label: loc?.tabGarage ?? 'Garaj',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events),
              label: loc?.tabLeaderboard ?? 'Sıralama',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront),
              label: loc?.tabStore ?? 'Mağaza',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: loc?.tabProfile ?? 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
