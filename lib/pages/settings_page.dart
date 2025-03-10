import 'package:car_culture_fyp/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/navigatet_pages.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Settings"),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontSize: 24
        ),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12)
            ),
            margin: const EdgeInsets.only(left: 25, top: 5, right: 25),
            padding: const EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),

                //Switch
                CupertinoSwitch(
                  value: Provider.of<ThemeProvider>(context, listen: false)
                      .isDarkMode,
                  onChanged: (value) =>
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme(),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12)
            ),
            margin: const EdgeInsets.only(left: 25, top: 5, right: 25),
            padding: const EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Blocked Users",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                
                GestureDetector(
                  onTap: () => goBlockedUsersPage(context),
                  child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.tertiary,)
                )
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12)
            ),
            margin: const EdgeInsets.only(left: 25, top: 5, right: 25),
            padding: const EdgeInsets.only(left: 25, right: 25, top: 15, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),

                GestureDetector(
                    onTap: () => goAccountSettingsPage(context),
                    child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.tertiary,)
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
