import 'package:car_culture_fyp/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Settings"),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
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
              color: Theme.of(context).colorScheme.primary,
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
          )
        ],
      ),
    );
  }
}
