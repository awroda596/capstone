//modular clickable link.  for tea details page but might be able to tweak it for others. 
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkText extends StatelessWidget {
  final String? url;
  final String text;

  const LinkText({
    required this.url,
    this.text = 'Product Page',
    super.key,
  });

  bool isValid()
  {
    return url != null && url! != 'N/A';
  }
      

  @override
  Widget build(BuildContext context) {
    if (!isValid()) {
      return const Text(
        'Page not available',
        style: TextStyle(color: Colors.black54),
      );
    }

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          fontSize: 14,
        ),
      ),
    );
  }
}
