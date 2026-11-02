import 'package:flutter/material.dart';

import 'package:homie/core/widgets/app_button.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';

import 'housing_presentation_helpers.dart';

List<String> housingIllustrationAssets(HousingListing listing) =>
    switch (listing.apartmentCode) {
      'A-0101' => const [
        'assets/images/housing/A-0101-01.jpg',
        'assets/images/housing/A-0101-02.jpg',
      ],
      'B-0201' => const ['assets/images/housing/B-0201-01.jpg'],
      _ => [
        listing.transactionType == HousingTransactionType.rent
            ? 'assets/images/housing/A-0101-02.jpg'
            : 'assets/images/housing/B-0201-01.jpg',
      ],
    };

Widget _housingIllustration(String assetPath) =>
    Image.asset(assetPath, fit: BoxFit.cover);

Widget _housingPhoto(
  HousingListing listing, {
  String? imageUrl,
  String? assetPath,
}) {
  final fallback = assetPath ?? housingIllustrationAssets(listing).first;
  return imageUrl == null
      ? _housingIllustration(fallback)
      : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _housingIllustration(fallback),
        );
}

class HousingListingCard extends StatelessWidget {
  const HousingListingCard({
    required this.listing,
    required this.onView,
    this.compact = false,
    this.onApply,
    this.applyLabel = 'Nộp hồ sơ',
    this.applyIcon = Icons.send_outlined,
    this.onApprove,
    this.onReject,
    super.key,
  });

  final HousingListing listing;
  final VoidCallback onView;
  final bool compact;
  final VoidCallback? onApply;
  final String applyLabel;
  final IconData applyIcon;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final transactionColor =
        listing.transactionType == HousingTransactionType.rent
        ? colors.secondary
        : colors.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 122,
                  child: _housingPhoto(
                    listing,
                    imageUrl: listing.imageUrls.isEmpty
                        ? null
                        : listing.imageUrls.first,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: transactionColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      listing.transactionType == HousingTransactionType.rent
                          ? Icons.key_rounded
                          : Icons.apartment_rounded,
                      color: transactionColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.apartmentCode,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          listing.buildingName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  HousingListingStatusBadge(status: listing.status),
                  if (onApprove != null || onReject != null)
                    PopupMenuButton<_ListingModerationAction>(
                      tooltip: 'Xử lý bài đăng',
                      onSelected: (action) {
                        switch (action) {
                          case _ListingModerationAction.approve:
                            onApprove?.call();
                          case _ListingModerationAction.reject:
                            onReject?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onApprove != null)
                          const PopupMenuItem(
                            value: _ListingModerationAction.approve,
                            child: ListTile(
                              leading: Icon(Icons.check_circle_outline),
                              title: Text('Duyệt bài đăng'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (onReject != null)
                          const PopupMenuItem(
                            value: _ListingModerationAction.reject,
                            child: ListTile(
                              leading: Icon(Icons.cancel_outlined),
                              title: Text('Từ chối bài đăng'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HousingTransactionBadge(type: listing.transactionType),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                listing.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (listing.ownerSubmitted) ...[
                const SizedBox(height: 8),
                Text(
                  'Chủ hộ gửi: ${listing.submittedByName ?? 'Không rõ'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (compact) const SizedBox(height: 16) else const Spacer(),
              Text(
                '${formatHousingMoney(listing.price)}${listing.transactionType.priceUnit}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: transactionColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sẵn sàng từ ${formatHousingDate(listing.availableFrom)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Chi tiết',
                      icon: Icons.visibility_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: onView,
                    ),
                  ),
                  if (onApply != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: applyLabel,
                        icon: applyIcon,
                        onPressed: onApply,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showHousingListingDetailSheet(
  BuildContext context, {
  required HousingListing listing,
  bool canApply = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _HousingListingDetail(listing: listing, canApply: canApply),
  );
}

class _HousingListingDetail extends StatelessWidget {
  const _HousingListingDetail({required this.listing, required this.canApply});

  final HousingListing listing;
  final bool canApply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${listing.buildingName} · ${listing.apartmentCode}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          listing.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HousingTransactionBadge(type: listing.transactionType),
                  HousingListingStatusBadge(status: listing.status),
                ],
              ),
              const SizedBox(height: 20),
              if (listing.imageUrls.isNotEmpty ||
                  housingIllustrationAssets(listing).isNotEmpty) ...[
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    itemCount: listing.imageUrls.isNotEmpty
                        ? listing.imageUrls.length
                        : housingIllustrationAssets(listing).length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _housingPhoto(
                          listing,
                          imageUrl: listing.imageUrls.isEmpty
                              ? null
                              : listing.imageUrls[index],
                          assetPath: listing.imageUrls.isEmpty
                              ? housingIllustrationAssets(listing)[index]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.imageUrls.isNotEmpty
                      ? '${listing.imageUrls.length} hình ảnh · Vuốt để xem'
                      : '${housingIllustrationAssets(listing).length} hình ảnh · Vuốt để xem',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatHousingMoney(listing.price)}${listing.transactionType.priceUnit}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (listing.transactionType ==
                            HousingTransactionType.rent &&
                        listing.deposit > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tiền đặt cọc: ${formatHousingMoney(listing.deposit)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Thông tin căn hộ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.apartment_outlined,
                label: 'Căn hộ',
                value: '${listing.apartmentCode} · ${listing.buildingName}',
              ),
              if (listing.submittedByName != null)
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Người đăng',
                  value:
                      '${listing.submittedByName}${listing.ownerSubmitted ? ' · Chủ sở hữu' : ' · Ban quản lý'}',
                ),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Có thể nhận từ',
                value: formatHousingDate(listing.availableFrom),
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Hình thức',
                value: listing.transactionType.label,
              ),
              const SizedBox(height: 16),
              Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                listing.description,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              if ((listing.reviewNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Phản hồi của ban quản lý',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(listing.reviewNote!),
              ],
              const SizedBox(height: 24),
              if (canApply)
                AppButton(
                  label:
                      'Nộp hồ sơ ${listing.transactionType == HousingTransactionType.rent ? 'thuê' : 'mua'}',
                  icon: Icons.description_outlined,
                  expand: true,
                  onPressed: () => Navigator.pop(context, true),
                )
              else if (!listing.isAvailable)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Tin đăng hiện không nhận thêm hồ sơ.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ListingModerationAction { approve, reject }

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
