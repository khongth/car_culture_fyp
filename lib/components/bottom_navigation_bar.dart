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
import '../components/drawer_tile.dart';

class BottomNavWrapper extends StatefulWidget {
  const BottomNavWrapper({Key? key}) : super(key: key);

  @override
  BottomNavWrapperState createState() => BottomNavWrapperState();
}

class BottomNavWrapperState extends State<BottomNavWrapper> with TickerProviderStateMixin {
  // Constants
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // State variables
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  // Overlay pages state
  Post? _selectedPost;
  String? _selectedUserId;
  MarketplacePost? _selectedMarketplaceItem;

  // Navigation history
  Post? _previousPost;
  MarketplacePost? _previousMarketplaceItem;

  // Animation controllers
  late final AnimationController _overlayController;
  late final AnimationController _profilePageController;
  late final AnimationController _postPageController;
  late final AnimationController _marketplaceItemPageController;

  // Page animations
  late final Animation<Offset> _profilePageAnimation;
  late final Animation<Offset> _postPageAnimation;
  late final Animation<Offset> _marketplaceItemPageAnimation;

  // Lazily initialized main pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with consistent duration
    _overlayController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _profilePageController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _postPageController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _marketplaceItemPageController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    // Create animations once
    _profilePageAnimation = _createSlideAnimation(_profilePageController);
    _postPageAnimation = _createSlideAnimation(_postPageController);
    _marketplaceItemPageAnimation = _createSlideAnimation(_marketplaceItemPageController);

    // Initialize pages
    _initPages();

    // Fetch user on start
    context.read<AuthCubit>().fetchUser();
  }

  void _initPages() {
    _pages = [
      HomePage(onDrawerOpen: openDrawer),
      MapPage(onDrawerOpen: openDrawer),
      MarketplacePage(onDrawerOpen: openDrawer),
      InboxPage(onDrawerOpen: openDrawer),
    ];
  }

  Animation<Offset> _createSlideAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
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
      _selectedMarketplaceItem = null;
    });
    _postPageController.forward();
  }

  void openProfilePage(String uid) {
    setState(() {
      // Save previous state for back navigation
      _previousPost = _selectedPost;
      _previousMarketplaceItem = _selectedMarketplaceItem;

      // Update current state
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
    // Handle back navigation to previous pages
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

  void _handleBottomNavTap(int index) {
    // Close any open overlays first
    if (_selectedPost != null || _selectedUserId != null || _selectedMarketplaceItem != null) {
      closeOverlayPage();
    }
    // Close drawer if open
    if (_isDrawerOpen) {
      closeDrawer();
    }
    // Update the current tab
    setState(() => _currentIndex = index);
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
        // Drawer container
        _buildDrawer(drawerWidth),

        // Main content (Moves when drawer opens)
        AnimatedBuilder(
          animation: _overlayController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(drawerWidth * _overlayController.value, 0),
              child: child!,
            );
          },
          child: _buildMainScaffold(),
        ),

        // Drawer overlay touch area for closing
        if (_isDrawerOpen) _buildDrawerOverlay(screenWidth),
      ],
    );
  }

  Widget _buildDrawer(double drawerWidth) {
    return Positioned(
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
                _buildDrawerItems(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItems() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyDrawerTile(
            text: "Discover Friends",
            icon: IconlyLight.add_user,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiscoverFriendsPage()),
              );
            },
          ),
          MyDrawerTile(
            text: "My Comments",
            icon: IconlyLight.chat,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyCommentsPage()),
              );
            },
          ),
          MyDrawerTile(
              text: "Settings",
              icon: IconlyLight.setting,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
          ),
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
    );
  }

  Widget _buildDrawerOverlay(double screenWidth) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: screenWidth * 0.2,
      child: GestureDetector(
        onTap: closeDrawer,
        behavior: HitTestBehavior.opaque,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildMainScaffold() {
    return Scaffold(
      body: Stack(
        children: [
          // Only force recreate Search page
          _currentIndex == 1
              ? _pages[_currentIndex]
              : _pages[_currentIndex],

          // Overlay pages with animations
          _buildProfilePageOverlay(),
          _buildPostPageOverlay(),
          _buildMarketplaceItemOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfilePageOverlay() {
    if (_selectedUserId == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _profilePageAnimation,
      child: ProfilePage(
        uid: _selectedUserId!,
        onClose: closeOverlayPage,
        onUserTap: openProfilePage,
      ),
    );
  }

  Widget _buildPostPageOverlay() {
    if (_selectedPost == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _postPageAnimation,
      child: PostPage(
        post: _selectedPost!,
        onClose: closeOverlayPage,
      ),
    );
  }

  Widget _buildMarketplaceItemOverlay() {
    if (_selectedMarketplaceItem == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _marketplaceItemPageAnimation,
      child: MarketplaceItemPage(
        post: _selectedMarketplaceItem!,
        onClose: closeOverlayPage,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(IconlyBold.location), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Marketplace'),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Inbox'),
      ],
    );
  }

  Widget _buildDrawerHeader() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildGuestHeader();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingHeader();
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return _buildFallbackHeader(currentUser);
        }

        // Convert DocumentSnapshot to UserProfile
        UserProfile userProfile = UserProfile.fromDocument(snapshot.data!);
        return _buildUserHeader(userProfile);
      },
    );
  }

  Widget _buildGuestHeader() {
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

  Widget _buildLoadingHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFallbackHeader(User currentUser) {
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
                backgroundImage: NetworkImage(
                    currentUser.photoURL ?? 'https://avatars.githubusercontent.com/u/91388754?v=4'
                )
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

  Widget _buildUserHeader(UserProfile userProfile) {
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
      ),
    );
  }
}