import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/announcement.dart';

class AnnouncementDialog extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  bool _dontShowToday = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.announcement.title.trim().isEmpty
                          ? '公告'
                          : widget.announcement.title.trim(),
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_dontShowToday),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textHint,
                    tooltip: '關閉',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.divider, width: 0.8),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.announcement.content.trim(),
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: _dontShowToday,
                onChanged: (value) {
                  setState(() => _dontShowToday = value ?? false);
                },
                title: Text('今日不再顯示', style: GoogleFonts.notoSansTc()),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppTheme.primary,
                checkColor: Colors.white,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_dontShowToday),
                  child: Text('知道了', style: GoogleFonts.notoSansTc()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
