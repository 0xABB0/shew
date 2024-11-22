import 'package:flutter/material.dart';
import 'package:shew/models/item.dart';
import 'package:shew/screens/details.dart';
import 'package:shew/services/item_service.dart';

class ShewHomePage extends StatefulWidget {
  const ShewHomePage({super.key});

  @override
  State<ShewHomePage> createState() => _ShewHomePageState();
}

class _ShewHomePageState extends State<ShewHomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = getItems();
  }

  Future<void> _navigateToDetail(BuildContext context, Item item) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(item: item),
      ),
    );
    
    if (!mounted) return;
    
    if (edited == true) {
      setState(() {
        _itemsFuture = getItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items List'),
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(item.title),
                subtitle: const Text('Tap to view details'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToDetail(context, item),
              );
            },
          );
        },
      ),
    );
  }
}
