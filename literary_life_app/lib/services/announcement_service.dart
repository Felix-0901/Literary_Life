import '../config/api_config.dart';
import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static Future<Announcement?> fetchActiveAnnouncement() async {
    try {
      final data = await ApiService.get('${ApiConfig.announcementsUrl}/active');
      final announcement = Announcement.fromJson(data);
      if (!announcement.isActive) return null;
      if (announcement.content.trim().isEmpty) return null;
      return announcement;
    } on ApiException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
