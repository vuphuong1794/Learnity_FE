import 'package:flutter/material.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Management'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Posts'), Tab(text: 'Members')],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Posts Content')),
            Center(child: Text('Members Content')),
          ],
        ),
      ),
    );
  }
}
