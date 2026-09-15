import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
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
      final dio = context.read<Dio>();
      final res = await dio.get<Map<String, dynamic>>('/users');
      final content = res.data?['content'];
      _users = content is List
          ? content.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
    } catch (e) {
      try {
        mapDioError(e);
      } on AppException catch (ae) {
        _error = ae.message;
      } catch (_) {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleTitle(String? code) => Role.fromCode(code).title;

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
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = _users[i];
                final roleTitle = _roleTitle(u['role'] as String?);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (u['username'] as String? ?? '?')[0].toUpperCase(),
                    ),
                  ),
                  title: Text(u['fullName'] as String? ?? ''),
                  subtitle: Text('${u['username']} · ${u['email']}'),
                  trailing: Chip(label: Text(roleTitle)),
                );
              },
            ),
    );
  }
}
