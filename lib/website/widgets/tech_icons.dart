import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tech icon widget that displays technology icons with clickable links.
class TechIcon extends StatelessWidget {
  final String name;
  final String url;
  final double size;
  final Color? color;

  const TechIcon({
    super.key,
    required this.name,
    required this.url,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _buildIcon(context),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final iconData = _getIconData(name);
    final iconColor = color ?? Colors.white;

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: size,
        color: iconColor,
        semanticLabel: name,
      ),
    );
  }

  IconData _getIconData(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('flutter')) {
      return Icons.phone_android_outlined;
    } else if (lowerName.contains('firebase')) {
      if (lowerName.contains('auth')) {
        return Icons.lock_outline;
      } else if (lowerName.contains('storage')) {
        return Icons.folder_outlined;
      } else if (lowerName.contains('firestore')) {
        return Icons.storage_outlined;
      }
      return Icons.cloud_outlined;
    } else if (lowerName.contains('gemini')) {
      return Icons.auto_awesome_outlined;
    } else if (lowerName.contains('dart')) {
      return Icons.code_outlined;
    } else if (lowerName.contains('router')) {
      return Icons.navigation_outlined;
    } else if (lowerName.contains('font')) {
      return Icons.text_fields_outlined;
    } else if (lowerName.contains('pdf') || lowerName.contains('syncfusion')) {
      return Icons.picture_as_pdf_outlined;
    }
    
    return Icons.help_outline;
  }
}

