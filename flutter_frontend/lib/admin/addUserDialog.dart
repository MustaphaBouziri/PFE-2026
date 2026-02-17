import 'package:flutter/material.dart';
import 'package:pfe_mes/providers/erp_employee_provider.dart';
import 'package:provider/provider.dart';

class AddUserDialog extends StatelessWidget {
  const AddUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ErpEmployeeProvider>();
    final employees = provider.employees;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),

      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Mes User',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 11),
          
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  child: const Text(
                    'Select an Employee',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null)
                Expanded(child: Center(child: Text(provider.errorMessage!)))
              else

               Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search employee...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // You can implement a filter in provider or locally
              },
            ),
          ),
                // List of employees
                Container(
                  height: 500,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(employee.image),
                          ),
                          title: Text(employee.fullName),
                          subtitle: Text(employee.email),
                          trailing: const Icon(Icons.add),
                          onTap: () {
                            // Example: Add user to your MES list or close dialog
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ),
          
              SizedBox(height: 11),
          
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 253, 238, 227),
                ),
                child: const Text(
                  'Select Role',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          
            ],
          ),
        ),
      ),
    );
  }
}
