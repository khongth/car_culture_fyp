import 'dart:ui';

import 'package:car_culture_fyp/pages/inbox_page.dart';
import 'package:car_culture_fyp/pages/map_page.dart';
import 'package:car_culture_fyp/pages/marketplace_page.dart';
import 'package:car_culture_fyp/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../models/marketplace.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../pages/discover_friends_page.dart';
import '../pages/home_page.dart';
import '../pages/marketplace_item_page.dart';
import '../pages/my_comments_page.dart';
import '../pages/post_page.dart';
import '../pages/search_page.dart';
import '../pages/profile_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../components/drawer_tile.dart';

class BottomNavWrapper extends StatefulWidget {
  const BottomNavWrapper({Key? key}) : super(key: key);

  @override
  BottomNavWrapperState createState() => BottomNavWrapperState();
}

class BottomNavWrapperState extends State<BottomNavWrapper> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Post? _selectedPost;
  String? _selectedUserId;
  MarketplacePost? _selectedMarketplaceItem;
  bool _isDrawerOpen = false;

  Post? _previousPost;
  MarketplacePost? _previousMarketplaceItem;

  late final AnimationController _overlayController;
  late final AnimationController _profilePageController;
  late final AnimationController _postPageController;
  late final AnimationController _marketplaceItemPageController;

  // Lazy initialize pages
  late final List<Widget> _pages = [
    HomePage(onDrawerOpen: openDrawer),
    SearchPage(onDrawerOpen: openDrawer, onUserTap: openProfilePage),
    MapPage(onDrawerOpen: openDrawer),
    MarketplacePage(onDrawerOpen: openDrawer),
    SettingsPage(),
  ];

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

    _marketplaceItemPageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    context.read<AuthCubit>().fetchUser();
  }

  void openDrawer() {
    _overlayController.forward();
    setState(() => _isDrawerOpen = true);
  }

  void closeDrawer() {
    _overlayController.reverse().then((_) {
      if (mounted) setState(() => _isDrawerOpen = false);
    });
  }

  void openPostPage(Post post) {
    setState(() {
      _selectedPost = post;
      _selectedUserId = null;
    });
    _postPageController.forward(); // Ensure this controller is being triggered
    print("Navigating to post with ID: ${post.id}");
  }

  void openProfilePage(String uid) {
    setState(() {
      _previousPost = _selectedPost;
      _previousMarketplaceItem = _selectedMarketplaceItem;

      _selectedUserId = uid;
      _selectedPost = null;
      _selectedMarketplaceItem = null;
    });
    _profilePageController.forward();
  }

  void openMarketplaceItemPage(MarketplacePost post) {
    setState(() {
      _selectedMarketplaceItem = post;
      _selectedUserId = null;
      _selectedPost = null;
    });
    _marketplaceItemPageController.forward();
  }

  void closeOverlayPage() {
    if (_selectedUserId != null) {

      if (_previousPost != null) {
        openPostPage(_previousPost!);
        _previousPost = null;
        return;
      }

      if (_previousMarketplaceItem != null) {
        openMarketplaceItemPage(_previousMarketplaceItem!);
        _previousMarketplaceItem = null;
        return;
      }
    }

    // Close all overlays if there's no previous page to restore
    _profilePageController.reverse();
    _postPageController.reverse();
    _marketplaceItemPageController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedPost = null;
          _selectedUserId = null;
          _selectedMarketplaceItem = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _profilePageController.dispose();
    _postPageController.dispose();
    _marketplaceItemPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth * 0.8;

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: drawerWidth,
            color: Colors.white,
            child: SafeArea(
              child: Material(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDrawerHeader(),
                    const SizedBox(height: 10),
                    MyDrawerTile(text: "Discover Friends", icon: IconlyLight.add_user, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DiscoverFriendsPage(),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(text: "My Comments", icon: IconlyLight.chat, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyCommentsPage()),
                      );
                    },),
                    MyDrawerTile(text: "Settings", icon: IconlyLight.setting, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    }),
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
              offset: Offset(drawerWidth * _overlayController.value, 0),
              child: child!,
            );
          },
          child: Scaffold(
            body: Stack(
              children: [
                // Only force recreate Search page
                _currentIndex == 1
                    ? SearchPage(onDrawerOpen: openDrawer, onUserTap: openProfilePage)
                    : _pages[_currentIndex],

                if (_selectedUserId != null)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
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
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(_postPageController),
                    child: PostPage(
                      post: _selectedPost!,
                      onClose: closeOverlayPage,
                    ),
                  ),

                if (_selectedMarketplaceItem != null)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(_marketplaceItemPageController),
                    child: MarketplaceItemPage(
                      post: _selectedMarketplaceItem!,
                      onClose: closeOverlayPage,
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (_selectedPost != null || _selectedUserId != null || _selectedMarketplaceItem != null) {
                  closeOverlayPage();
                }
                if (_isDrawerOpen) {
                  closeDrawer();
                }
                setState(() => _currentIndex = index);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.game), label: 'Car Clubs'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Marketplace'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.profile), label: 'Profile'),
              ],
            ),
          ),
        ),

        // Drawer overlay touch area
        if (_isDrawerOpen)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: screenWidth * 0.2,
            child: GestureDetector(
              onTap: closeDrawer,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerHeader() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            SizedBox(height: 10),
            Text("@Guest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Not Logged In", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          // Fallback to Auth data if Firestore data isn't available
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: GestureDetector(
              onTap: () {
                if (currentUser.uid.isNotEmpty) {
                  openProfilePage(currentUser.uid);
                  closeDrawer();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(currentUser.photoURL ??
                          'https://avatars.githubusercontent.com/u/91388754?v=4')
                  ),
                  const SizedBox(height: 10),
                  Text(
                      "@${currentUser.displayName ?? "User"}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  Text(
                      currentUser.email ?? "",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                  ),
                ],
              ),
            ),
          );
        }

        // Convert DocumentSnapshot to UserProfile
        UserProfile userProfile = UserProfile.fromDocument(snapshot.data!);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: GestureDetector(
            onTap: () {
              openProfilePage(userProfile.uid);
              closeDrawer();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userProfile.profileImageUrl.isNotEmpty
                      ? NetworkImage(userProfile.profileImageUrl)
                      : const NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "@${userProfile.username}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Text(
                        userProfile.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}