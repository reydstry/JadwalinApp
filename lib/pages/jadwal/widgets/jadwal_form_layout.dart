import 'package:flutter/material.dart';

/// Menata bagian form dan tombol simpan tanpa mengelola nilai inputnya.
class JadwalFormLayout extends StatelessWidget {
  const JadwalFormLayout({
    super.key,
    required this.constraints,
    required this.wide,
    required this.pinSave,
    required this.submitted,
    required this.formKey,
    required this.info,
    required this.time,
    required this.reminder,
    required this.saveButton,
  });
  final BoxConstraints constraints;
  final bool wide;
  final bool pinSave;
  final bool submitted;
  final GlobalKey<FormState> formKey;
  final Widget info;
  final Widget time;
  final Widget reminder;
  final Widget saveButton;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          width: constraints.maxWidth.clamp(0.0, 1040.0),
          height: constraints.maxHeight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Form(
              key: formKey,
              autovalidateMode: submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          width:
                              (constraints.maxWidth.clamp(0.0, 1040.0) -
                                      2 * (wide ? 32 : 19))
                                  .clamp(0.0, double.infinity),
                          child: Column(
                            children: [
                              if (wide)
                                IntrinsicHeight(
                                  child: Row(
                                    key: const Key('schedule_two_columns'),

                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [info, const Spacer()],
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        child: Column(
                                          children: [time, const Spacer()],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                info,
                                const SizedBox(height: 26),
                                time,
                              ],
                              const SizedBox(height: 20),
                              reminder,
                              const SizedBox(height: 24),
                              if (!pinSave)
                                Row(
                                  children: [
                                    const Spacer(),
                                    SizedBox(
                                      width:
                                          (constraints.maxWidth.clamp(
                                                    0.0,
                                                    1040.0,
                                                  ) -
                                                  (wide ? 64 : 38))
                                              .clamp(0.0, 480.0),
                                      child: saveButton,
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
