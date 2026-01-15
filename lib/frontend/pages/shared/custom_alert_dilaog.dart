import "package:flutter/material.dart";

enum AlertType { delete, info, success, warning }

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final Widget actions;
  final AlertType type;
  final Widget? avatar; // Platz für dein Avatar-Bild oder Icon

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    required this.type,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.transparent,
            child: _getImageByType(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(content),
      actions: [actions],
    );
  }

  // Color _getColorByType() {
  //   switch (type) {
  //     case AlertType.delete:
  //       return Colors.redAccent;
  //     case AlertType.success:
  //       return Colors.green;
  //     case AlertType.warning:
  //       return Colors.orange;
  //     case AlertType.info:
  //     default:
  //       return Colors.blueAccent;
  //   }
  // }

  // IconData _getIconByType() {
  //   switch (type) {
  //     case AlertType.delete:
  //       return Icons.delete_outline;
  //     case AlertType.success:
  //       return Icons.check;
  //     case AlertType.warning:
  //       return Icons.warning_amber;
  //     case AlertType.info:
  //     default:
  //       return Icons.info_outline;
  //   }
  // }

  Image _getImageByType() {
    switch (type) {
      case AlertType.delete:
        return Image.asset('assets/vion/vion_sad.png');
      case AlertType.success:
        return Image.asset('assets/vion/vion_basic.png');
      case AlertType.warning:
        return Image.asset('assets/vion/vion_basic.png');
      case AlertType.info:
        return Image.asset('assets/vion/vion_basic.png');
    }
  }
}
