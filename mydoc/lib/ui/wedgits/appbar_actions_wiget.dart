import 'package:flutter/material.dart';

import '../../routes/routs_name.dart';
import '../../utils/hive_storage.dart';

class AppBarActions extends StatelessWidget {
  final Color iconColor;
  final String imagePath;

  const AppBarActions({
    Key? key,
    this.iconColor = Colors.black54,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.pushNamed(context, RouteNames.doctor_profile_screen,arguments: {"isProfile" :"1"});
            break;

          case 'settings':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings tapped')),
            );
            break;

          case 'logout':
            HiveStorage.clearHives();
            Navigator.popAndPushNamed(context, RouteNames.splash);
            break;
        }
      },

      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: iconColor),
              const SizedBox(width: 10),
              const Text('Profile'),
            ],
          ),
        ),

        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_outlined, color: iconColor),
              const SizedBox(width: 10),
              const Text('Logout'),
            ],
          ),
        ),
      ],

      // The widget that opens the menu
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(imagePath),
          ),
        ),
      ),
    );
  }
}
