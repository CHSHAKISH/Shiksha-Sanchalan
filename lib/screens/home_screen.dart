import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:shiksha_sanchalan/screens/dashboard_page.dart';
import 'package:shiksha_sanchalan/screens/profile_screen.dart';
import 'package:shiksha_sanchalan/screens/settings_screen.dart';
import 'package:shiksha_sanchalan/screens/all_users_page.dart';

// This is the main entry point, responsible only for fetching user data.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Use a FutureBuilder to fetch the user's details just once.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        // Show a loading indicator while fetching data.
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Handle cases where user data might be missing.
        if (snapshot.hasError || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Could not load user data.")));
        }

        // Create a user model from the fetched data.
        final userModel = UserModel.fromMap(user.uid, snapshot.data!.data() as Map<String, dynamic>);

        // Once data is fetched, build the actual UI with the bottom navigation.
        return HomeView(userModel: userModel);
      },
    );
  }
}

// This is the actual UI widget, which manages the navigation state.
class HomeView extends StatefulWidget {
  final UserModel userModel;
  const HomeView({super.key, required this.userModel});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Define the pages list here, using the userModel from the widget.
    _pages = [
      DashboardPage(userModel: widget.userModel),
      AllUsersPage(currentUser: widget.userModel),
      ProfileScreen(userModel: widget.userModel),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // This function is called when a bottom navigation icon is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Animate the PageView to the selected page.
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        // This is called when the user swipes between pages.
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'All Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
