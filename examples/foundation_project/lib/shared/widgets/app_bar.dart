import 'package:flutter/material.dart';

/// Custom app bar widget
class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final String? submitText;
  final String? cancelText;
  final bool isSubmitting;

  const FormAppBar({
    super.key,
    required this.title,
    this.onSubmit,
    this.onCancel,
    this.submitText,
    this.cancelText,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onCancel != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCancel,
              tooltip: cancelText ?? 'Cancel',
            )
          : null,
      actions: [
        if (onSubmit != null)
          TextButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitText ?? 'Submit'),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
