import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/app_exceptions.dart';
import '../api/supabase_errors.dart';
import '../models/role.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('full_name');
      _users = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      try {
        mapSupabaseError(e);
      } on AppException catch (ae) {
        _error = ae.message;
      } catch (_) {
        _error = '$e';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? const Center(child: Text('Нет пользователей'))
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        final email = '${u['email'] ?? ''}';
                        final name = '${u['full_name'] ?? email}';
                        final roleTitle = Role.fromCode('${u['role']}').title;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (name.isEmpty ? '?' : name[0]).toUpperCase(),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(email),
                          trailing: Chip(label: Text(roleTitle)),
                        );
                      },
                    ),
    );
  }
}
