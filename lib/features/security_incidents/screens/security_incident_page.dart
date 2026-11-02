import 'package:flutter/material.dart';
import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/status_badge.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/enums/user_role.dart';
import 'package:homie/core/models/work_assignee.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';

import '../controllers/security_incident_controller.dart';
import '../models/security_incident.dart';
import '../models/security_incident_status.dart';
import '../models/security_incident_type.dart';

class SecurityIncidentPage extends StatefulWidget {
  const SecurityIncidentPage({
    required this.controller,
    required this.membershipController,
    required this.user,
    required this.managementMode,
    super.key,
  });
  final SecurityIncidentController controller;
  final ApartmentMembershipController membershipController;
  final User user;
  final bool managementMode;
  @override
  State<SecurityIncidentPage> createState() => _SecurityIncidentPageState();
}

class _SecurityIncidentPageState extends State<SecurityIncidentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => Future.wait([
    widget.controller.load(),
    widget.membershipController.load(),
  ]);
  @override
  Widget build(BuildContext context) => ResidentPageScaffold(
    title: widget.managementMode ? 'Điều phối an ninh' : 'Phản ánh an ninh',
    subtitle: widget.managementMode
        ? 'Tiếp nhận và cập nhật tình trạng xử lý'
        : '${widget.membershipController.apartmentById(widget.membershipController.activeMembershipForResident(widget.user.id)?.apartmentId ?? '')?.code ?? 'Chưa chọn căn'} · Báo sự cố',
    icon: Icons.shield_outlined,
    accentColor: AppColors.security,
    accentSoftColor: AppColors.securitySoft,
    actions: [
      IconButton(
        tooltip: 'Tải lại dữ liệu',
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    floatingActionButton: widget.managementMode
        ? null
        : ResidentFloatingAction(
            onPressed: _create,
            icon: Icons.add_alert_outlined,
            label: 'Báo sự cố',
            color: AppColors.security,
            endColor: AppColors.maintenance,
          ),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.membershipController,
      ]),
      builder: (context, child) {
        if (widget.controller.isLoading &&
            widget.controller.incidents.isEmpty) {
          return const LoadingView(message: 'Đang tải sự cố an ninh…');
        }
        if (widget.controller.errorMessage != null &&
            widget.controller.incidents.isEmpty) {
          return ErrorView(
            message: widget.controller.errorMessage,
            onRetry: _load,
          );
        }
        final activeApartmentId = widget.membershipController
            .activeMembershipForResident(widget.user.id)
            ?.apartmentId;
        final visibleIncidents = widget.managementMode
            ? widget.controller.incidents
            : widget.controller.incidents
                  .where(
                    (incident) => incident.apartmentId == activeApartmentId,
                  )
                  .toList(growable: false);
        if (visibleIncidents.isEmpty) {
          return EmptyView(
            icon: Icons.shield_outlined,
            title: 'Chưa có sự cố an ninh',
            message: widget.managementMode
                ? 'Các phản ánh an ninh sẽ xuất hiện tại đây.'
                : 'Bạn có thể báo tiếng ồn, mất trật tự hoặc vấn đề an toàn.',
            actionLabel: 'Tải lại',
            onAction: _load,
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
            itemCount: visibleIncidents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = visibleIncidents[index];
              return _IncidentCard(
                item: item,
                management: widget.managementMode,
                canAssign: widget.user.role.isManager,
                canResolve:
                    widget.user.role == UserRole.security ||
                    widget.user.role == UserRole.admin,
                canCancel: widget.user.role.isManager,
                onAssign: () => _assign(item),
                onResolve: () => _update(item, SecurityIncidentStatus.resolved),
                onCancel: () => _update(item, SecurityIncidentStatus.cancelled),
              );
            },
          ),
        );
      },
    ),
  );

  Future<void> _create() async {
    final membership = widget.membershipController.activeMembershipForResident(
      widget.user.id,
    );
    if (membership == null) {
      _message('Bạn chưa được gắn với căn hộ đang cư trú.');
      return;
    }
    final draft = await showDialog<_IncidentDraft>(
      context: context,
      builder: (_) => const _IncidentDialog(),
    );
    if (draft == null || !mounted) return;
    final ok = await widget.controller.create(
      apartmentId: membership.apartmentId,
      type: draft.type,
      title: draft.title,
      description: draft.description,
      location: draft.location,
      occurredAt: DateTime.now(),
    );
    if (mounted) {
      _message(
        ok
            ? 'Đã gửi phản ánh đến bộ phận an ninh.'
            : widget.controller.errorMessage ?? 'Không thể gửi phản ánh.',
      );
    }
  }

  Future<void> _update(
    SecurityIncident item,
    SecurityIncidentStatus status,
  ) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == SecurityIncidentStatus.resolved
              ? 'Hoàn tất xử lý'
              : 'Cập nhật sự cố',
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: status == SecurityIncidentStatus.resolved
                ? 'Kết quả xử lý *'
                : 'Ghi chú',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !mounted) return;
    final ok = await widget.controller.update(
      id: item.id,
      status: status,
      note: note,
    );
    if (mounted) {
      _message(
        ok
            ? 'Đã cập nhật sự cố.'
            : widget.controller.errorMessage ?? 'Không thể cập nhật.',
      );
    }
  }

  Future<void> _assign(SecurityIncident item) async {
    List<WorkAssignee> assignees;
    try {
      assignees = await widget.controller.getAssignees(item.id);
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
      return;
    }
    if (!mounted || assignees.isEmpty) {
      if (mounted) _message('Tòa nhà chưa có bảo vệ đang hoạt động.');
      return;
    }
    final selected = await showDialog<WorkAssignee>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Phân công bảo vệ'),
        children: [
          for (final assignee in assignees)
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: Text(assignee.fullName),
              subtitle: Text(assignee.email),
              onTap: () => Navigator.pop(context, assignee),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final ok = await widget.controller.assign(
      id: item.id,
      assigneeId: selected.id,
    );
    if (mounted) {
      _message(
        ok
            ? 'Đã phân công cho ${selected.fullName}.'
            : widget.controller.errorMessage ?? 'Không thể phân công.',
      );
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.item,
    required this.management,
    required this.canAssign,
    required this.canResolve,
    required this.canCancel,
    required this.onAssign,
    required this.onResolve,
    required this.onCancel,
  });
  final SecurityIncident item;
  final bool management;
  final bool canAssign, canResolve, canCancel;
  final VoidCallback onAssign, onResolve, onCancel;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.securitySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.security,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.code} · ${item.type.label}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: item.status.label,
                tone: switch (item.status) {
                  SecurityIncidentStatus.reported => StatusBadgeTone.warning,
                  SecurityIncidentStatus.reviewing => StatusBadgeTone.info,
                  SecurityIncidentStatus.resolved => StatusBadgeTone.success,
                  SecurityIncidentStatus.cancelled => StatusBadgeTone.neutral,
                },
              ),
            ],
          ),
          const Divider(height: 28),
          _IncidentInfoLine(
            icon: Icons.apartment_outlined,
            text:
                '${item.buildingName}${item.apartmentCode == null ? '' : ' · Căn ${item.apartmentCode}'}',
          ),
          if ((item.assignedToName ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            _IncidentInfoLine(
              icon: Icons.security_rounded,
              text: 'Bảo vệ phụ trách: ${item.assignedToName}',
            ),
          ],
          const SizedBox(height: 9),
          _IncidentInfoLine(icon: Icons.notes_rounded, text: item.description),
          if ((item.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 9),
            _IncidentInfoLine(
              icon: Icons.location_on_outlined,
              text: 'Vị trí: ${item.location}',
            ),
          ],
          const SizedBox(height: 9),
          _IncidentInfoLine(
            icon: Icons.person_outline_rounded,
            text: 'Người báo: ${item.reportedByName}',
          ),
          if ((item.resolutionNote ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            Text('Kết quả: ${item.resolutionNote}'),
          ],
          if (management &&
              canAssign &&
              item.status == SecurityIncidentStatus.reported) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (canCancel)
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Hủy'),
                    ),
                  FilledButton(
                    onPressed: onAssign,
                    child: const Text('Phân công'),
                  ),
                ],
              ),
            ),
          ],
          if (management &&
              canResolve &&
              item.status == SecurityIncidentStatus.reviewing) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (canCancel)
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Hủy sự cố'),
                    ),
                  FilledButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Hoàn tất xử lý'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _IncidentInfoLine extends StatelessWidget {
  const _IncidentInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(width: 1),
      Icon(icon, size: 18, color: AppColors.security),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ),
    ],
  );
}

class _IncidentDialog extends StatefulWidget {
  const _IncidentDialog();
  @override
  State<_IncidentDialog> createState() => _IncidentDialogState();
}

class _IncidentDialogState extends State<_IncidentDialog> {
  SecurityIncidentType type = SecurityIncidentType.noise;
  final title = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Báo sự cố an ninh'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SecurityIncidentType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Loại sự cố'),
              items: [
                for (final value in SecurityIncidentType.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Tiêu đề *'),
            ),
            TextField(
              controller: description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mô tả *'),
            ),
            TextField(
              controller: location,
              decoration: const InputDecoration(labelText: 'Vị trí xảy ra'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (title.text.trim().length < 5 ||
              description.text.trim().length < 10) {
            return;
          }
          Navigator.pop(
            context,
            _IncidentDraft(
              type,
              title.text.trim(),
              description.text.trim(),
              location.text.trim(),
            ),
          );
        },
        child: const Text('Gửi phản ánh'),
      ),
    ],
  );
}

class _IncidentDraft {
  const _IncidentDraft(this.type, this.title, this.description, this.location);
  final SecurityIncidentType type;
  final String title, description, location;
}
