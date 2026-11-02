import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/maintenance/models/maintenance_status.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

import '../../controllers/maintenance_controller.dart';
import '../../widgets/maintenance_widgets.dart';

class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({
    required this.controller,
    required this.apartmentMembershipController,
    required this.user,
    required this.requestId,
    super.key,
  });

  final MaintenanceController controller;
  final ApartmentMembershipController apartmentMembershipController;
  final User user;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Chi tiết yêu cầu',
      subtitle: 'Tình trạng và tiến độ xử lý kỹ thuật',
      icon: Icons.handyman_outlined,
      accentColor: AppColors.maintenance,
      accentSoftColor: AppColors.maintenanceSoft,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final request = controller.requestById(requestId);
          if (request == null || request.residentId != user.id) {
            return const EmptyView(
              icon: Icons.search_off_rounded,
              title: 'Không tìm thấy yêu cầu',
              message:
                  'Yêu cầu không tồn tại hoặc bạn không có quyền truy cập.',
            );
          }
          final apartment = apartmentMembershipController.apartmentById(
            request.apartmentId,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    request.code,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ),
                                MaintenanceStatusBadge(status: request.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              request.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              request.description,
                              style: const TextStyle(height: 1.55),
                            ),
                            const Divider(height: 32),
                            _Info(
                              label: 'Căn hộ',
                              value: apartment?.code ?? '—',
                            ),
                            _Info(label: 'Vị trí', value: request.location),
                            _Info(
                              label: 'Loại sự cố',
                              value: request.category.label,
                            ),
                            _Info(
                              label: 'Mức ưu tiên',
                              value: request.priority.label,
                            ),
                            _Info(
                              label: 'Người phụ trách',
                              value: request.assignedTo ?? 'Chưa phân công',
                            ),
                            _Info(
                              label: 'Ngày gửi',
                              value: formatMaintenanceDate(
                                request.createdAt,
                                includeTime: true,
                              ),
                            ),
                            if (request.imageUrls.isNotEmpty) ...[
                              const Divider(height: 32),
                              MaintenanceAttachments(urls: request.imageUrls),
                            ],
                            if (request.status ==
                                MaintenanceStatus.waitingResident) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: .08,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: .24,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.fact_check_outlined,
                                          color: AppColors.success,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Kết quả đang chờ bạn xác nhận',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Hãy kiểm tra thực tế tại căn hộ. Xác nhận hoàn thành hoặc gửi phản hồi để kỹ thuật viên tiếp tục xử lý.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        AppButton(
                                          label: 'Đã khắc phục',
                                          icon: Icons.task_alt_rounded,
                                          onPressed: controller.isLoading
                                              ? null
                                              : () => _confirmResult(context),
                                        ),
                                        AppButton(
                                          label: 'Vẫn còn sự cố',
                                          icon: Icons.replay_rounded,
                                          variant: AppButtonVariant.outlined,
                                          onPressed: controller.isLoading
                                              ? null
                                              : () => _reopen(context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (request.status ==
                                MaintenanceStatus.submitted) ...[
                              const SizedBox(height: 14),
                              AppButton(
                                label: 'Hủy yêu cầu',
                                icon: Icons.close_rounded,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _cancel(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: MaintenanceTimeline(request: request),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hủy yêu cầu?',
      message: 'Yêu cầu chưa tiếp nhận sẽ được chuyển sang trạng thái đã hủy.',
      confirmLabel: 'Hủy yêu cầu',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final success = await controller.updateStatus(
      requestId: requestId,
      status: MaintenanceStatus.cancelled,
      note: 'Cư dân đã hủy yêu cầu.',
      actorName: user.fullName,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã hủy yêu cầu.'
              : controller.errorMessage ?? 'Không thể hủy yêu cầu.',
        ),
      ),
    );
  }

  Future<void> _confirmResult(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xác nhận đã khắc phục?',
      message: 'Yêu cầu sẽ được hoàn thành và kết quả xác nhận được lưu vào lịch sử xử lý.',
      confirmLabel: 'Đã khắc phục',
    );
    if (!confirmed || !context.mounted) return;
    final success = await controller.respondToResult(
      requestId: requestId,
      confirmed: true,
      note: '',
      actorName: user.fullName,
    );
    if (!context.mounted) return;
    _showResult(
      context,
      success,
      success
          ? 'Đã xác nhận yêu cầu hoàn thành.'
          : controller.errorMessage ?? 'Không thể xác nhận kết quả.',
    );
  }

  Future<void> _reopen(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.replay_circle_filled_outlined),
        title: const Text('Sự cố vẫn chưa được khắc phục'),
        content: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TextFormField(
              controller: noteController,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Mô tả tình trạng hiện tại',
                hintText: 'Ví dụ: Vòi nước vẫn rò khi mở mạnh…',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Vui lòng nhập ít nhất 5 ký tự.'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, noteController.text.trim());
              }
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Gửi phản hồi'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !context.mounted) return;
    final success = await controller.respondToResult(
      requestId: requestId,
      confirmed: false,
      note: note,
      actorName: user.fullName,
    );
    if (!context.mounted) return;
    _showResult(
      context,
      success,
      success
          ? 'Đã gửi phản hồi để kỹ thuật viên tiếp tục xử lý.'
          : controller.errorMessage ?? 'Không thể gửi phản hồi.',
    );
  }

  void _showResult(BuildContext context, bool success, String message) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: colors.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
