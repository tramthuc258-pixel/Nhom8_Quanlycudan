import 'package:flutter/material.dart';

import 'package:homie/features/residents/controllers/apartment_membership_controller.dart';
import 'package:homie/features/residents/models/apartment_membership.dart';
import 'package:homie/features/residents/models/membership_type.dart';

Future<bool> showResidentApartmentPicker({
  required BuildContext context,
  required ApartmentMembershipController controller,
  required String residentId,
  bool requireSelection = false,
}) async {
  final memberships = controller.activeMembershipsForResident(residentId);
  if (memberships.length < 2) return false;

  final apartmentId = await showModalBottomSheet<String>(
    context: context,
    isDismissible: !requireSelection,
    enableDrag: !requireSelection,
    showDragHandle: !requireSelection,
    isScrollControlled: true,
    builder: (sheetContext) => PopScope(
      canPop: !requireSelection,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Chọn căn hộ đang sử dụng',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Hóa đơn, yêu cầu và dịch vụ sẽ hiển thị theo căn bạn chọn.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: memberships.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ApartmentMembership membership = memberships[index];
                    final apartment = controller.apartmentById(
                      membership.apartmentId,
                    );
                    final selected =
                        controller
                            .activeMembershipForResident(residentId)
                            ?.apartmentId ==
                        membership.apartmentId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.apartment_rounded),
                      ),
                      title: Text(apartment?.code ?? 'Căn hộ'),
                      subtitle: Text(
                        '${apartment?.buildingName ?? 'Tòa nhà'} · ${membership.type.displayName}',
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          Navigator.pop(sheetContext, membership.apartmentId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (apartmentId == null) return false;
  return controller.selectApartmentForResident(residentId, apartmentId);
}
