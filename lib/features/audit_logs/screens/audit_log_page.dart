import 'package:flutter/material.dart';

import '../controllers/audit_log_controller.dart';
import '../models/audit_log_entry.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({required this.controller, super.key});

  final AuditLogController controller;

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.load(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      title: const Text('Nhật ký quản trị'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: widget.controller.load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _summary(controller.entries),
              const SizedBox(height: 16),
              _filters(),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 14),
                _error(controller.errorMessage!),
              ],
              const SizedBox(height: 16),
              if (controller.isLoading && controller.entries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (controller.entries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Chưa có thao tác phù hợp bộ lọc.'),
                  ),
                )
              else
                ...controller.entries.map(_entryCard),
            ],
          ),
        );
      },
    ),
  );

  Widget _summary(List<AuditLogEntry> entries) {
    final failed = entries.where((entry) => !entry.succeeded).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3157D5), Color(0xFF16A6B6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            child: Icon(Icons.policy_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theo dõi thay đổi hệ thống',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${entries.length} thao tác gần nhất · $failed thao tác không thành công',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: widget.controller.action,
              decoration: const InputDecoration(labelText: 'Hành động'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Tất cả')),
                DropdownMenuItem(value: 'POST', child: Text('Tạo mới')),
                DropdownMenuItem(value: 'PATCH', child: Text('Cập nhật')),
                DropdownMenuItem(value: 'DELETE', child: Text('Xóa')),
              ],
              onChanged: (value) => widget.controller.load(action: value ?? ''),
            ),
          ),
          SizedBox(
            width: 260,
            child: TextFormField(
              initialValue: widget.controller.resource,
              decoration: const InputDecoration(
                labelText: 'Nhóm chức năng',
                hintText: 'Ví dụ: invoices',
                suffixIcon: Icon(Icons.search_rounded),
              ),
              onFieldSubmitted: (value) =>
                  widget.controller.load(resource: value.trim()),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _entryCard(AuditLogEntry entry) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: entry.succeeded
            ? const Color(0xFFE3F7EF)
            : const Color(0xFFFFE7E7),
        foregroundColor: entry.succeeded
            ? const Color(0xFF087A5B)
            : const Color(0xFFB42318),
        child: Icon(
          entry.succeeded ? Icons.check_rounded : Icons.error_outline_rounded,
        ),
      ),
      title: Text(
        '${_actionLabel(entry.action)} · ${_resourceLabel(entry.resource)}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${entry.actor.fullName} · ${_formatDate(entry.createdAt)}',
      ),
      trailing: Chip(label: Text('${entry.statusCode}')),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      children: [
        _detail('Email', entry.actor.email),
        _detail('API', entry.path),
        if (entry.targetId != null) _detail('Đối tượng', entry.targetId!),
        if (entry.metadata.isNotEmpty)
          _detail('Dữ liệu', entry.metadata.toString()),
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );

  Widget _error(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE7E7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFB42318))),
  );

  String _actionLabel(String action) => switch (action) {
    'POST' => 'Tạo mới',
    'PATCH' => 'Cập nhật',
    'DELETE' => 'Xóa',
    _ => action,
  };

  String _resourceLabel(String resource) => resource.replaceAll('-', ' ');

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
