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
    // Services
    'exterior_wash': 'Exterior Wash',
    'interior_clean': 'Interior Clean',
    'full_detail': 'Full Detail',
    'polish': 'Polish',
    'tyre_shine': 'Tyre Shine',
    'engine_clean': 'Engine Clean',
    // Detection
    'detection_camera_ai': 'AI Camera',
    'detection_crowd': 'Community',
    'detection_verified': 'Business Verified',
    'detection_camera_desc': 'Queue detected automatically via AI camera — no sign-up needed',
    'detection_crowd_desc': 'Queue reported by nearby app users — no sign-up needed',
    'detection_verified_desc': 'Queue reported directly by the business',
    'how_detected': 'How queue is detected',
    // Report queue
    'report_queue': 'Report Queue',
    'report_subtitle': 'See a different count? Help others.',
    'submit_report': 'Submit Report',
    'report_submitted': 'Thanks for your report!',
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
    // Services
    'exterior_wash': 'غسيل خارجي',
    'interior_clean': 'تنظيف داخلي',
    'full_detail': 'تفصيل كامل',
    'polish': 'تلميع',
    'tyre_shine': 'تلميع الإطارات',
    'engine_clean': 'تنظيف المحرك',
    // Detection
    'detection_camera_ai': 'كاميرا ذكاء اصطناعي',
    'detection_crowd': 'مجتمعي',
    'detection_verified': 'موثق من المحل',
    'detection_camera_desc': 'يُكتشف الطابور تلقائياً عبر كاميرا الذكاء الاصطناعي — بدون تسجيل',
    'detection_crowd_desc': 'أبلغ عن الطابور مستخدمو التطبيق القريبون — بدون تسجيل',
    'detection_verified_desc': 'يُبلَّغ عن الطابور مباشرة من المنشأة',
    'how_detected': 'كيف يُكتشف الطابور',
    // Report queue
    'report_queue': 'الإبلاغ عن الطابور',
    'report_subtitle': 'هل ترى عدداً مختلفاً؟ ساعد الآخرين.',
    'submit_report': 'إرسال التقرير',
    'report_submitted': 'شكراً على تقريرك!',
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
      _ => '',
    };
    return key.isEmpty ? service : t(key);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
