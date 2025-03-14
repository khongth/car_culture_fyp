import 'package:car_culture_fyp/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../models/post.dart';
import '../pages/home_page.dart';
import '../pages/post_page.dart';
import '../pages/search_page.dart';
import '../pages/profile_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../components/drawer_tile.dart';

class BottomNavWrapper extends StatefulWidget {
  @override
  BottomNavWrapperState createState() => BottomNavWrapperState();
}

class BottomNavWrapperState extends State<BottomNavWrapper> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Post? _selectedPost;
  String? _selectedUserId;

  late AnimationController _overlayController;
  late AnimationController _profilePageController;
  late AnimationController _postPageController;

  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _profilePageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _postPageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

  }

  void openDrawer() {
    _overlayController.forward();
    setState(() => _isDrawerOpen = true);
  }

  void closeDrawer() {
    _overlayController.reverse().then((_) {
      setState(() => _isDrawerOpen = false);
    });
  }

  void openPostPage(Post post) {
    setState(() {
      _selectedPost = post;
      _selectedUserId = null;
    });
    _postPageController.forward();
  }

  void openProfilePage(String uid) {
    setState(() {
      _selectedUserId = uid;
      _selectedPost = null;
    });
    _profilePageController.forward();
  }

  void closeOverlayPage() {
    _profilePageController.reverse();
    _postPageController.reverse().then((_) {
      setState(() {
        _selectedPost = null;
        _selectedUserId = null;
      });
    });
  }

  @override
  void dispose() {
    if (!_isDrawerOpen) {
      _overlayController.dispose();
    }
    _profilePageController.dispose();
    _postPageController.dispose();
    super.dispose();
  }

  Widget _buildPageWithDrawerAccess(Widget page) {
    if (page is HomePage) {
      return HomePage(onDrawerOpen: openDrawer);
    }
    if (page is SearchPage) {
      return SearchPage(
        onDrawerOpen: openDrawer,
        onUserTap: openProfilePage,
      );
    }
    return page;
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    List<Widget> _pages = [
      HomePage(),
      if (_currentIndex == 1) SearchPage(onDrawerOpen: openDrawer, onUserTap: openProfilePage), // ✅ Force recreate
      SettingsPage(),
      HomePage(),
      HomePage(),
      HomePage(),
    ];

    return Stack(
      children: [
        // Drawer (Fixed on the left)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: screenWidth * 0.8,
            height: double.infinity,
            color: Colors.white,
            child: SafeArea(
              child: Material(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final user = state.user;
                        final username = state.username ?? "Guest";
                        final email = user?.email ?? "Not Logged In";
                        final profileImage = user?.photoURL ?? 'https://avatars.githubusercontent.com/u/91388754?v=4';
                
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          child: GestureDetector(
                            onTap: () {
                              if (user != null && user.uid.isNotEmpty) {
                                 // Close any existing overlays (optional)
                                openProfilePage(user?.uid ?? "");
                                closeDrawer();
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 20, backgroundImage: NetworkImage(profileImage)),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("@$username", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    MyDrawerTile(text: "Profile", icon: IconlyBold.profile, onTap: closeDrawer),
                    MyDrawerTile(text: "Forum", icon: IconlyBroken.category, onTap: closeDrawer),
                    MyDrawerTile(text: "Car Clubs", icon: IconlyBroken.game, onTap: closeDrawer),
                    MyDrawerTile(text: "Maps", icon: IconlyBroken.home, onTap: closeDrawer),
                    MyDrawerTile(text: "Settings", icon: IconlyBroken.setting, onTap: closeDrawer),
                    const Spacer(),
                    SafeArea(
                      child: MyDrawerTile(
                        text: "Logout",
                        icon: Icons.logout,
                        onTap: () {
                          context.read<AuthCubit>().signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Main content (Moves 80% when drawer opens)
        AnimatedBuilder(
          animation: _overlayController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(screenWidth * 0.8 * _overlayController.value, 0),
              child: Scaffold(
                body: Stack(
                  children: [
                    IndexedStack(
                      index: _currentIndex,
                      children: _pages.map((page) => _buildPageWithDrawerAccess(page)).toList(),
                    ),

                    if (_selectedUserId != null)
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(_profilePageController),
                        child: ProfilePage(
                          uid: _selectedUserId!,
                          onClose: closeOverlayPage,
                          onUserTap: openProfilePage,
                        ),
                      ),

                    if (_selectedPost != null)
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(_postPageController),
                        child: PostPage(
                          post: _selectedPost!,
                          onClose: closeOverlayPage,
                        ),
                      ),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (_selectedPost != null || _selectedUserId != null) {
                      closeOverlayPage();
                    }
                    if (_isDrawerOpen) {
                      closeDrawer(); // ✅ Close drawer when switching pages
                    }
                    setState(() => _currentIndex = index);
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.black,
                  unselectedItemColor: Colors.grey,
                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  items: [
                    BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(IconlyBold.search), label: 'Search'),
                    BottomNavigationBarItem(icon: Icon(IconlyBold.game), label: 'Car Clubs'),
                    BottomNavigationBarItem(icon: Icon(IconlyBold.location), label: 'Maps'),
                    BottomNavigationBarItem(icon: Icon(IconlyBold.profile), label: 'Profile'),
                  ],
                ),
              ),
            );
          },
        ),

        if (_isDrawerOpen)
          Positioned(
            right: 0, // Aligns the overlay to the right
            top: 0,
            bottom: 0,
            width: screenWidth * 0.2, // Covers only 20% of the screen width
            child: GestureDetector(
              onTap: closeDrawer,
              child: Container(
                color: Colors.black.withOpacity(0 * _overlayController.value),
              ),
            ),
          ),
      ],
    );
  }
}
