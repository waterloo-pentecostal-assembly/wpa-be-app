import 'package:flutter/material.dart';

// Color Constants
const Color kWpaBlue = Color(0xff0092d6);
const Color kSuccessColor = Color(0xff4BB543);
const Color kLateColor = Color(0xffffc107);
const Color kDraftColor = Color(0xff007bff);
const Color kBlackColor = Color(0xff212121);
const Color kDarkGreyColor = Color(0x50212121);
const Color kErrorTextColor = Colors.red;
Color kCardGrey = Colors.grey.shade300;
Color kCardOverlayGrey = Colors.grey.shade100;

// Size Constants
const kRecentBibleSeriesTileWidth = 250.0;
const kRecentBibleSeriesTileHeight = 130.0;
const kRecentBibleSeriesTileDescriptionHeight = 60.0;
const kMediaTileWidth = 150.0;
const kMediaTileHeight = 75.0;
const kMediaTileDescriptionHeight = 60.0;
const kAllPrayerRequestsCardHeight = 100.0;

// Limits
const kPrayerRequestsReportsLimit = 2;
const kPrayerRequestPerUserLimit = 10;

// Images
const kWpaLogoLoc = 'assets/images/wpa-logo.png';
const kProfilePhotoPlaceholder = 'assets/images/person-placeholder-image.png';

// Regex
const kPasswordRegex = r"""^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$""";
const kEmailRegex = r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

// Restrictions
const kMaxResponseBody = 4000;
const kMaxPrayerRequestBody = 500;
const kMaxActivePrayerRequests = 10;

// URLs
const kWpaGiveUrl = 'https://www.canadahelps.org/en/dne/15479';

// Firebase Messaging Topics
const kDailyEngagementReminderTopic = 'daily_engagement_reminder';

// Help/Reporting
const kWpaContactEmail = 'dan@wpa.church';
const kHelpEmailSubject = '[WPA BE APP] Help Request';
const kReportEmailSubject = '[WPA BE APP] Problem Report';
