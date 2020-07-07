import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({Key key, @required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text(
            "HOME",
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.class_),
          title: Text(
            "ENGAGE",
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          title: Text(
            "NOTIFICATIONS",
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.perm_identity),
          title: Text(
            "PROFILE",
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
