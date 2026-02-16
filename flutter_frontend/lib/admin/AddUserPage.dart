import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mes_user_model.dart';
import '../providers/mes_user_provider.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String selectedRole = 'All';
  List<String> roles = ['All', 'Admin', 'Supervisor', 'Employee'];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesUserProvider>(context, listen: false).fetchUsers();// make sure the fetchuser is called after the widget is fully built
    });
  }

  @override
  Widget build(BuildContext context) {

    final provider = Provider.of<MesUserProvider>(context);
    final users = provider.users;

    final filteredUsers = users.where((user) {
      final bool roleMatch = selectedRole == 'All' || user.role == selectedRole;// if drop = all or selected role= user.role return true 
      final bool searchMatch = user.fullName
              .toLowerCase()
              .contains(searchController.text.toLowerCase()) || // exemple searchMatch = "john doe".contains("john") → true
          user.email.toLowerCase().contains(searchController.text.toLowerCase());
      return roleMatch && searchMatch;//both need to be true to enter the list  if true and true return true the retuen true is required cuz we did where 
    }).toList();

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          //provider.addUser
                          MesUser(
                            userId: 'U999',
                            employeeId: 'E999',
                            role: 'Employee',
                            firstName: 'New',
                            lastName: 'User',
                            email: 'new.user@example.com',
                          );
                        },
                        child: const Text('Add User'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: "Search users by name, lastName, or email",
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                              ),
                              onChanged: (_) => provider.notifyListeners(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 47,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedRole,
                                items: roles
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedRole = value!;
                                  });
                                  provider.notifyListeners();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            'https://i.pravatar.cc/150?img=${index + 1}'),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(user.email, style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(flex: 1, child: Text(user.role)),
                                Expanded(flex: 1, child: Text('assembly')),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Online',
                                    style: const TextStyle(
                                        color: Colors.green, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text('Just now', overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
