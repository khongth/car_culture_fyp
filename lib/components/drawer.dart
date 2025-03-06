import 'package:car_culture_fyp/components/drawer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().fetchUser();

    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade500, // Set the color of the border
              width: 0.5, // Set the width of the border
            ),
          ),
        ),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.successMessage == "Signed out successfully") {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          builder: (context, state) {
            final user = state.user;
            final displayName = user?.displayName ?? "Guest";
            final email = user?.email ?? "Not Logged In";

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(
                    email,
                    style: TextStyle(color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                          'https://blog.sebastiano.dev/content/images/2019/07/1_l3wujEgEKOecwVzf_dqVrQ.jpeg'),
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://avatars.githubusercontent.com/u/91388754?v=4'),
                  ),
                ),
                const SizedBox(height: 10),
                MyDrawerTile(
                  text: "Home",
                  icon: IconlyBold.home,
                  onTap: () {
                    Navigator.pop(context);
                    FocusScope.of(context).unfocus();
                  },
                ),
                MyDrawerTile(
                  text: "Forum",
                  icon: IconlyBroken.category,
                  onTap: () {},
                ),
                MyDrawerTile(
                  text: "Car Clubs",
                  icon: IconlyBroken.game,
                  onTap: () {},
                ),
                MyDrawerTile(
                  text: "Maps",
                  icon: IconlyBroken.home,
                  onTap: () {},
                ),
                MyDrawerTile(
                  text: "Settings",
                  icon: IconlyBroken.setting,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Divider before Logout
                Divider(
                  color: Colors.grey[400],
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 10),

                SafeArea(
                  child: MyDrawerTile(
                    text: "Logout",
                    icon: Icons.logout,
                    onTap: () {
                      context.read<AuthCubit>().signOut();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
