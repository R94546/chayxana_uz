enum BookingStatus { pending, confirmed, cancelled, completed }

enum PaymentStatus { unpaid, paid, refunded }

enum PaymentMethod { cash, click, payme, card }

extension BookingStatusValue on BookingStatus {
  String get value => name;

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Kutilmoqda';
      case BookingStatus.confirmed:
        return 'Tasdiqlangan';
      case BookingStatus.cancelled:
        return 'Bekor qilingan';
      case BookingStatus.completed:
        return 'Yakunlangan';
    }
  }

  String get colorHex {
    switch (this) {
      case BookingStatus.pending:
        return '#FFA726';
      case BookingStatus.confirmed:
        return '#66BB6A';
      case BookingStatus.cancelled:
        return '#EF5350';
      case BookingStatus.completed:
        return '#42A5F5';
    }
  }

  bool get isTerminal => this == BookingStatus.cancelled || this == BookingStatus.completed;
}

extension PaymentStatusValue on PaymentStatus {
  String get value => name;
}

extension PaymentMethodValue on PaymentMethod {
  String get value => name;
}

extension BookingStatusParser on String? {
  BookingStatus toBookingStatus() {
    final value = (this ?? '').toLowerCase();
    return BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

extension PaymentStatusParser on String? {
  PaymentStatus toPaymentStatus() {
    final value = (this ?? '').toLowerCase();
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

extension PaymentMethodParser on String? {
  PaymentMethod toPaymentMethod() {
    final value = (this ?? '').toLowerCase();
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

