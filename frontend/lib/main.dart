import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stock_entry_screen.dart';
import 'screens/register_screen.dart';
import 'screens/salesmen_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const SsrsmApp());
}

class SsrsmApp extends StatelessWidget {
  const SsrsmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSRSM Accounts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.pri,
        textTheme: GoogleFonts.muktaTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pri,
          primary: AppColors.pri,
          surface: AppColors.card,
        ),
        useMaterial3: true,
      ),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  bool _isLoggedIn = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
            _currentIndex = 0;
          });
        },
      );
    }

    final screens = [
      HomeScreen(
        onLogout: () {
          setState(() {
            _isLoggedIn = false;
          });
        },
      ),
      const SalesmenScreen(),
      StockEntryScreen(
        onSaved: () {
          setState(() {
            _currentIndex = 3; // Navigate directly to Print / PDF (Register) page
          });
        },
      ),
      const RegisterScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(20, 23, 58, 0.22),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: AppColors.card,
            indicatorColor: AppColors.tint,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.pri),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.pri),
                label: 'Sales man',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle, color: AppColors.pri),
                label: 'Stock',
              ),
              NavigationDestination(
                icon: Icon(Icons.print_outlined),
                selectedIcon: Icon(Icons.print, color: AppColors.pri),
                label: 'Print / PDF',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
