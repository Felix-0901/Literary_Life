import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/inspiration_provider.dart';
import '../providers/cycle_provider.dart';
import '../models/inspiration.dart';

class QuickAddSheet extends StatefulWidget {
  final Inspiration? inspiration;
  const QuickAddSheet({super.key, this.inspiration});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _locationController = TextEditingController();
  final _eventController = TextEditingController();
  final _detailController = TextEditingController();
  final _feelingController = TextEditingController();
  final _keywordsController = TextEditingController();
  bool _saving = false;
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.inspiration != null) {
      _locationController.text = widget.inspiration!.location;
      _eventController.text = widget.inspiration!.objectOrEvent;
      _detailController.text = widget.inspiration!.detailText;
      _feelingController.text = widget.inspiration!.feeling;
      _keywordsController.text = widget.inspiration!.keywords;
      _selectedTime = widget.inspiration!.eventTime.toLocal();
    } else {
      _selectedTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _eventController.dispose();
    _detailController.dispose();
    _feelingController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_eventController.text.isEmpty && _detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('至少填寫事件或細節描寫'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final cycleId = context.read<CycleProvider>().currentCycle?.id;
    bool success;
    if (widget.inspiration != null) {
      success = await context.read<InspirationProvider>().updateInspiration(
        widget.inspiration!.id,
        eventTime: _selectedTime,
        location: _locationController.text.trim(),
        objectOrEvent: _eventController.text.trim(),
        detailText: _detailController.text.trim(),
        feeling: _feelingController.text.trim(),
        keywords: _keywordsController.text.trim(),
      );
    } else {
      success = await context.read<InspirationProvider>().createInspiration(
        cycleId: cycleId,
        eventTime: _selectedTime,
        location: _locationController.text.trim(),
        objectOrEvent: _eventController.text.trim(),
        detailText: _detailController.text.trim(),
        feeling: _feelingController.text.trim(),
        keywords: _keywordsController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.inspiration != null ? '靈感已更新 ✦' : '靈感已記錄 ✦',
              style: GoogleFonts.notoSansTc(),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.inspiration != null ? '編輯靈感' : '記一筆靈感',
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '儲存',
                          style: GoogleFonts.notoSansTc(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeSelector(),
                  const SizedBox(height: 14),
                  _buildField(
                    Icons.place_outlined,
                    '地點',
                    '你在哪裡？',
                    _locationController,
                  ),
                  _buildField(
                    Icons.event_note_rounded,
                    '事件 / 物品',
                    '發生了什麼？看到了什麼？',
                    _eventController,
                  ),
                  _buildField(
                    Icons.edit_note_rounded,
                    '細節描寫',
                    '更多細節、感官描述...',
                    _detailController,
                    maxLines: 3,
                  ),
                  _buildField(
                    Icons.favorite_outline_rounded,
                    '當下感受',
                    '你的心情如何？',
                    _feelingController,
                  ),
                  _buildField(
                    Icons.tag_rounded,
                    '靈感關鍵字',
                    '用逗號分隔，例如：光、安靜、溫暖',
                    _keywordsController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime),
        builder: (context, child) =>
            Theme(data: AppTheme.lightTheme, child: child!),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: AppTheme.textHint,
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedTime.year}/${_selectedTime.month}/${_selectedTime.day} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.notoSansTc(
                fontSize: 15,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_calendar_rounded,
              size: 16,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    IconData icon,
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.notoSansTc(fontSize: 14, color: AppTheme.primary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.textHint),
        ),
      ),
    );
  }
}
