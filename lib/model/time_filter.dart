import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimeFilter {
  all,
  today,
  yesterday,
  last3Days,
  older;

  String get label {
    switch (this) {
      case TimeFilter.all:
        return '全部时间';
      case TimeFilter.today:
        return '今天';
      case TimeFilter.yesterday:
        return '昨天';
      case TimeFilter.last3Days:
        return '最近3天';
      case TimeFilter.older:
        return '更早';
    }
  }

  IconData get icon {
    switch (this) {
      case TimeFilter.all:
        return Icons.history;
      case TimeFilter.today:
        return Icons.today;
      case TimeFilter.yesterday:
        return Icons.event_repeat;
      case TimeFilter.last3Days:
        return Icons.date_range;
      case TimeFilter.older:
        return Icons.calendar_today;
    }
  }

  /// Returns the start and end time for the filter
  ({DateTime? start, DateTime? end}) get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    switch (this) {
      case TimeFilter.all:
        return (start: null, end: null);
      case TimeFilter.today:
        return (start: today, end: tomorrow);
      case TimeFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (start: yesterday, end: today);
      case TimeFilter.last3Days:
        final threeDaysAgo = today.subtract(const Duration(days: 2));
        return (start: threeDaysAgo, end: tomorrow);
      case TimeFilter.older:
        final threeDaysAgo = today.subtract(const Duration(days: 2));
        return (start: null, end: threeDaysAgo);
    }
  }

  /// Helper to format a date for grouping headers
  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDay = DateTime(date.year, date.month, date.day);

    if (itemDay == today) {
      return '今天';
    } else if (itemDay == yesterday) {
      return '昨天';
    } else {
      return DateFormat('MM月dd日').format(date);
    }
  }
}
