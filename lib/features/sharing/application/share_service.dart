import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ShareOutcome { shared, copied, dismissed }

abstract interface class ShareService {
  Future<ShareOutcome> shareText({required String text, required String url});
}

class PlatformShareService implements ShareService {
  PlatformShareService({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<ShareOutcome> shareText({
    required String text,
    required String url,
  }) async {
    final payload = '$text\n$url';
    try {
      final result = await _sharePlus.share(ShareParams(text: payload));
      if (result.status == ShareResultStatus.dismissed) {
        return ShareOutcome.dismissed;
      }
      if (result.status == ShareResultStatus.success) {
        return ShareOutcome.shared;
      }
    } catch (_) {
      // Clipboard is the browser-safe fallback when the platform share sheet fails.
    }
    await Clipboard.setData(ClipboardData(text: url));
    return ShareOutcome.copied;
  }
}
