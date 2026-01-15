import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    required super.key,
    required this.avatarColor,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDiscarding,
  });

  final Color avatarColor;
  final IconData avatarIcon;
  final Color avatarIconColor;
  final Widget title;
  final Widget subtitle;
  final Function onTap;
  final Function onDiscarding;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // confirmDismiss: (direction) => showDialog<bool>(
      //   context: context,
      //   builder: (context) => CustomAlertDialog(
      //     type: AlertType.delete,
      //     title: 'Eintrag löschen?',
      //     content: 'Möchten Sie diesen Eintrag wirklich löschen?',
      //     actions: Row(
      //       children: [
      //         TextButton(
      //           onPressed: () => Navigator.of(context).pop(false),
      //           child: const Text('Abbrechen'),
      //         ),
      //         TextButton(
      //           onPressed: () => Navigator.of(context).pop(true),
      //           child: const Text('Löschen'),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      key: key!,
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red.shade300,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDiscarding();
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: avatarColor,
            child: Icon(
              avatarIcon,
              color: avatarIconColor,
            ),
          ),
          title: title,
          subtitle: subtitle,
          trailing: Icon(
            Icons.delete_sweep,
            color: Colors.grey,
          ),
          onTap: onTap as void Function(),
        ),
      ),
    );
  }
}
