import 'package:flutter/material.dart';

class UnifiedActionBottomSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String clientName;
  final String pensionLabel;
  final String? touchpointLabel;
  final List<Widget> cards;
  final String submitLabel;
  final bool isFormValid;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const UnifiedActionBottomSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.clientName,
    required this.pensionLabel,
    required this.touchpointLabel,
    required this.cards,
    required this.submitLabel,
    required this.isFormValid,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Leave a fixed scrim above the sheet so it's clearly a bottom sheet and
    // not a full page on small phones. ~64dp below the status bar reads as a
    // sheet across all device sizes, instead of scaling with screen height.
    final maxHeight = media.size.height - media.padding.top - 64;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, size: 18, color: const Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(
                      pensionLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (touchpointLabel != null) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Text(
                        touchpointLabel!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                child: Column(children: cards),
              ),
            ),

            // Submit button — bottom safe-area only, so the home indicator
            // doesn't overlap the button on edge-to-edge devices.
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: (isFormValid && !isSubmitting) ? onSubmit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            submitLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
