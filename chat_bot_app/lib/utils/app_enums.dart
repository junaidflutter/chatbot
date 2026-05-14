enum GenderType { male, female }

enum SuccessStateType { verify, forget }

enum UserRole { user, admin }

//task

enum TaskStatus { completed, warning, inProgress, pending }

enum CalendarView { daily, weekly, monthly }

enum TaskCategory { work, private, goals, health }

enum DueDateOption { today, tomorrow, thisWeek, custom }

enum ActiveTimePicker { none, start, end }

enum NotificationType {
  missedCall,
  taskCompleted,
  passwordUpdated,
  taskReminder,
  taskOverdue,
  unknown;

  static NotificationType fromString(String type) {
    switch (type) {
      case 'missed_call':
        return NotificationType.missedCall;
      case 'task_completed':
        return NotificationType.taskCompleted;
      case 'password_updated':
        return NotificationType.passwordUpdated;
      case 'task_reminder':
        return NotificationType.taskReminder;
      case 'task_overdue':
        return NotificationType.taskOverdue;
      default:
        return NotificationType.unknown;
    }
  }
}
