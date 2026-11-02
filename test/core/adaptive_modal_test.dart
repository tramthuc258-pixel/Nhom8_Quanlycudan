import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie/core/widgets/adaptive_modal.dart';

void main() {
  testWidgets('form dùng bottom sheet gọn trên kích thước Android', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAdaptiveModal<void>(
                  context,
                  builder: (context) => AdaptiveModalScaffold(
                    title: 'Tạo yêu cầu',
                    subtitle: 'Nội dung thử nghiệm',
                    body: const SizedBox(height: 900, child: Text('Biểu mẫu')),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hoàn tất'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo yêu cầu'), findsOneWidget);
    expect(find.text('Hoàn tất'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
