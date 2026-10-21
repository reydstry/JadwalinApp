import 'package:flutter/material.dart';

/// Keeps the introduction beside the form in landscape, with one scroll area.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.headerBuilder,
    required this.form,
    this.landscapeFormWidthFactor = 1,
  });

  final Widget Function(BuildContext context, double width) headerBuilder;
  final Widget form;
  final double landscapeFormWidthFactor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            size.width > size.height && constraints.maxWidth >= 600;
        final gap = constraints.maxWidth >= 800 ? 48.0 : 24.0;
        final contentWidth = (constraints.maxWidth - 48).clamp(
          0.0,
          sideBySide ? 960.0 : 327.0,
        );
        final columnWidth = sideBySide
            ? (contentWidth - gap) / 2
            : contentWidth;
        final header = headerBuilder(context, columnWidth);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24),
              Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: (constraints.maxWidth - 2 * (24)).clamp(
                      0.0,
                      double.infinity,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          SizedBox(
                            width: contentWidth,
                            child: sideBySide
                                ? Row(
                                    children: [
                                      Expanded(child: header),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width:
                                                  columnWidth *
                                                  landscapeFormWidthFactor,
                                              child: form,
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      header,
                                      const SizedBox(height: 32),
                                      form,
                                    ],
                                  ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
