import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';

  static const delegate = _AppLocalizationsDelegate();

  static const _en = <String, String>{
    // General
    'app_title': 'Emirates Wash',
    'nearby_washes': 'Nearby Car Washes',
    'filter_all': 'All',
    'status_free': 'Free',
    'status_busy': 'Busy',
    'status_full': 'Full',
    'no_wait': 'No wait',
    'min_wait': 'min wait',
    'cars_in_queue': 'cars in queue',
    'car_in_queue': 'car in queue',
    'estimated_wait': 'Estimated Wait',
    'services': 'Services',
    'rating': 'Rating',
    'get_directions': 'Get Directions',
    'km_away': 'km away',
    'locate_me': 'My Location',
    'opening_hours': 'Opening Hours',
    'call': 'Call',
    'from_price': 'from AED',
    // Services
    'exterior_wash': 'Exterior Wash',
    'interior_clean': 'Interior Clean',
    'full_detail': 'Full Detail',
    'polish': 'Polish',
    'tyre_shine': 'Tyre Shine',
    'engine_clean': 'Engine Clean',
    'ceramic_coating': 'Ceramic Coating',
    // Detection
    'detection_camera_ai': 'AI Camera',
    'detection_crowd': 'Community',
    'detection_verified': 'Business Verified',
    'detection_camera_desc':
        'Queue detected automatically via AI camera — no sign-up needed',
    'detection_crowd_desc':
        'Queue reported by nearby app users — no sign-up needed',
    'detection_verified_desc': 'Queue reported directly by the business',
    'how_detected': 'How queue is detected',
    // Login
    'login_heading': 'Find Car Washes\nNear You',
    'login_sub': 'UAE\'s smartest car wash finder',
    'phone_hint': '50 123 4567',
    'send_otp': 'Send OTP',
    'continue_guest': 'Continue as Guest',
    'terms': 'By continuing you agree to our Terms & Privacy Policy',
    'or': 'or',
    // OTP
    'otp_heading': 'Verify your number',
    'otp_sub': 'Enter the 6-digit code sent to',
    'verify': 'Verify',
    'resend_in': 'Resend in',
    'resend': 'Resend Code',
    'skip_demo': 'Skip Verification (Demo)',
    'invalid_phone': 'Enter a valid phone number',
    // Payment
    'reserve_pay': 'Reserve & Pay',
    'select_package': 'Select Package',
    'select_slot': 'Choose a Time Slot',
    'basic_wash': 'Basic',
    'standard_wash': 'Standard',
    'premium_wash': 'Premium',
    'aed': 'AED',
    'proceed_payment': 'Proceed to Payment',
    'pay_now': 'Pay',
    'booking_confirmed': 'Booking Confirmed!',
    'booking_ref': 'Booking Reference',
    'your_slot': 'Your Slot',
    'done': 'Done',
    'cardholder_name': 'Cardholder Name',
    'card_number': 'Card Number',
    'expiry': 'Expiry (MM/YY)',
    'cvv': 'CVV',
    'payment_secure': 'Secured with 256-bit encryption',
    'total': 'Total',
    'basic_includes': 'Exterior wash',
    'standard_includes': 'Exterior + Interior + Tyre shine',
    'premium_includes': 'Full detail + Polish + Engine clean',
    // Sort & Filter
    'sort_filter': 'Sort & Filter',
    'sort_by': 'Sort By',
    'sort_distance': 'Nearest First',
    'sort_wait': 'Shortest Wait',
    'sort_rating': 'Highest Rated',
    'filter_services': 'Filter by Service',
    'apply': 'Apply',
    'clear_all': 'Clear All',
    'no_results': 'No washes match your filters',
    'no_results_sub': 'Try adjusting or clearing filters',
    'active_filters': 'Active filters',
  };

  static const _ar = <String, String>{
    // General
    'app_title': 'إمارات ووش',
    'nearby_washes': 'مراكز الغسيل القريبة',
    'filter_all': 'الكل',
    'status_free': 'متاح',
    'status_busy': 'مشغول',
    'status_full': 'ممتلئ',
    'no_wait': 'لا انتظار',
    'min_wait': 'دقيقة انتظار',
    'cars_in_queue': 'سيارات في الطابور',
    'car_in_queue': 'سيارة في الطابور',
    'estimated_wait': 'وقت الانتظار المتوقع',
    'services': 'الخدمات',
    'rating': 'التقييم',
    'get_directions': 'احصل على الاتجاهات',
    'km_away': 'كم',
    'locate_me': 'موقعي',
    'opening_hours': 'ساعات العمل',
    'call': 'اتصل',
    'from_price': 'من AED',
    // Services
    'exterior_wash': 'غسيل خارجي',
    'interior_clean': 'تنظيف داخلي',
    'full_detail': 'تفصيل كامل',
    'polish': 'تلميع',
    'tyre_shine': 'تلميع الإطارات',
    'engine_clean': 'تنظيف المحرك',
    'ceramic_coating': 'طلاء سيراميك',
    // Detection
    'detection_camera_ai': 'كاميرا ذكاء اصطناعي',
    'detection_crowd': 'مجتمعي',
    'detection_verified': 'موثق من المحل',
    'detection_camera_desc':
        'يُكتشف الطابور تلقائياً عبر كاميرا الذكاء الاصطناعي — بدون تسجيل',
    'detection_crowd_desc':
        'أبلغ عن الطابور مستخدمو التطبيق القريبون — بدون تسجيل',
    'detection_verified_desc': 'يُبلَّغ عن الطابور مباشرة من المنشأة',
    'how_detected': 'كيف يُكتشف الطابور',
    // Login
    'login_heading': 'ابحث عن\nغسيل السيارات القريب',
    'login_sub': 'أذكى مكتشف لغسيل السيارات في الإمارات',
    'phone_hint': '50 123 4567',
    'send_otp': 'إرسال الرمز',
    'continue_guest': 'المتابعة كضيف',
    'terms': 'بالمتابعة توافق على شروط الاستخدام وسياسة الخصوصية',
    'or': 'أو',
    // OTP
    'otp_heading': 'تحقق من رقمك',
    'otp_sub': 'أدخل الرمز المكون من 6 أرقام المرسل إلى',
    'verify': 'تحقق',
    'resend_in': 'إعادة الإرسال بعد',
    'resend': 'إعادة إرسال الرمز',
    'skip_demo': 'تخطي التحقق (عرض توضيحي)',
    'invalid_phone': 'أدخل رقم هاتف صحيح',
    // Payment
    'reserve_pay': 'احجز وادفع',
    'select_package': 'اختر الباقة',
    'select_slot': 'اختر موعداً',
    'basic_wash': 'أساسي',
    'standard_wash': 'قياسي',
    'premium_wash': 'بريميوم',
    'aed': 'درهم',
    'proceed_payment': 'المتابعة للدفع',
    'pay_now': 'ادفع',
    'booking_confirmed': 'تم الحجز!',
    'booking_ref': 'رقم الحجز',
    'your_slot': 'موعدك',
    'done': 'تم',
    'cardholder_name': 'اسم حامل البطاقة',
    'card_number': 'رقم البطاقة',
    'expiry': 'تاريخ الانتهاء (شهر/سنة)',
    'cvv': 'رمز CVV',
    'payment_secure': 'مؤمَّن بتشفير 256 بت',
    'total': 'الإجمالي',
    'basic_includes': 'غسيل خارجي',
    'standard_includes': 'خارجي + داخلي + إطارات',
    'premium_includes': 'تفصيل كامل + تلميع + محرك',
    // Sort & Filter
    'sort_filter': 'ترتيب وتصفية',
    'sort_by': 'ترتيب حسب',
    'sort_distance': 'الأقرب أولاً',
    'sort_wait': 'أقصر انتظار',
    'sort_rating': 'الأعلى تقييماً',
    'filter_services': 'تصفية حسب الخدمة',
    'apply': 'تطبيق',
    'clear_all': 'مسح الكل',
    'no_results': 'لا توجد مراكز تطابق فلاترك',
    'no_results_sub': 'جرب تعديل الفلاتر أو مسحها',
    'active_filters': 'فلاتر نشطة',
  };

  String t(String key) => (isArabic ? _ar[key] : _en[key]) ?? _en[key] ?? key;

  String serviceLabel(String service) {
    final key = switch (service) {
      'Exterior Wash' => 'exterior_wash',
      'Interior Clean' => 'interior_clean',
      'Full Detail' => 'full_detail',
      'Polish' => 'polish',
      'Tyre Shine' => 'tyre_shine',
      'Engine Clean' => 'engine_clean',
      'Ceramic Coating' => 'ceramic_coating',
      _ => '',
    };
    return key.isEmpty ? service : t(key);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
