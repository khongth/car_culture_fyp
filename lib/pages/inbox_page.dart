import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  const InboxPage({super.key, this.onDrawerOpen});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
