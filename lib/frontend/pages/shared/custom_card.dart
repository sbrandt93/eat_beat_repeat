import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    required super.key,
    required this.avatarColor,
    required this.avatarIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDiscarding,
  });

  final Color avatarColor;
  final IconData avatarIcon;
  final Widget title;
  final Widget subtitle;
  final Function onTap;
  final Function onDiscarding;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
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
              color: Colors.indigo,
            ),
          ),
          title: title,
          subtitle: subtitle,
          onTap: onTap as void Function(),
        ),
      ),
    );
  }
}
