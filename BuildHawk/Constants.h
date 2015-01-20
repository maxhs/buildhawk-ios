//
//  Constants.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#ifndef BuildHawk_Constants_h
#define BuildHawk_Constants_h

static inline int screenHeight(){ return [UIScreen mainScreen].bounds.size.height; }
static inline int screenWidth(){ return [UIScreen mainScreen].bounds.size.width; }
#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

#define kApiBaseUrl @"https://buildhawk.com/api/v3"
#define kBaseUrl @"https://buildhawk.com"
#define kUrlScheme @"buildhawk"
#define kForecastAPIKey @"32a0ebe578f183fac27d67bb57f230b5"

#define ANUIFontTextStyleCaption3 @"ANUIFontTextStyleCaption3"
#define ANUIFontTextStyleCaption4 @"ANUIFontTextStyleCaption4"

#define kUserDefaultsId @"user_id"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsFirstName @"firstName"
#define kUserDefaultsLastName @"lastName"
#define kUserDefaultsFullName @"fullName"
#define kUserDefaultsPhotoUrl100 @"userPhoto100"
#define kUserDefaultsCoworkers @"coworkers"
#define kUserDefaultsDeviceToken @"deviceToken"
#define kUserDefaultsCompanyId @"companyId"
#define kUserDefaultsAdmin @"admin"
#define kUserDefaultsCompanyAdmin @"companyAdmin"
#define kUserDefaultsUberAdmin @"uberAdmin"
#define kUserDefaultsMobileToken @"mobileToken"

#define kCompleted @"Completed"
#define kcompleted @"completed"
#define kInProgress @"In-Progress"
#define kNotApplicable @"Not Applicable"

#define kChecklist @"Checklist"
#define kTasklist @"Tasklist"
#define kTasks @"Tasks"
#define kTask @"Task"
#define kReports @"Reports"
#define kNoReport @"No report"
#define kNoTask @"No task"
#define kNoComment @"No comment"
#define kDocuments @"Documents"
#define kPhase @"Phase"
#define kCategory @"Category"
#define kItem @"Item"
#define kAddOther @"Add other..."
#define kAddNew @"Add new..."
#define kPdf @"application/pdf"
#define kCancel @"Cancel"
#define ksubcontractors @"subcontractors"
#define kSubcontractor @"Subcontractor"
#define kSubcontractors @"Subcontractors"
#define kpersonnel @"personnel"
#define kCompanyUser @"Company User"
#define kCompanyUsers @"Company Users"
#define kUsers @"Users"
#define kIndividual @"Individual"
#define kCompany @"Company"
#define kAddCommentPlaceholder @"Add a comment..."

#define kHelveticaNeueLight @"HelveticaNeue-Light"
#define kHelveticaNeueMedium @"HelveticaNeue-Medium"
#define kHelveticaNeueRegular @"HelveticaNeue-Regular"
#define kHelveticaNeueLightItalic @"HelveticaNeue-LightItalic"
#define kMyriadProRegular @"MyriadPro-Regular"
#define kMyriadProLight @"MyriadPro-Light"
#define kMyriadProSemibold @"MyriadPro-Semibold"
#define kMyriadProIt @"MyriadPro-It"
#define kLato @"Lato-Regular"
#define kLatoItalic @"Lato-Italic"
#define kLatoLight @"Lato-Light"
#define kLatoLightItalic @"Lato-LightItalic"
#define kLatoHairline @"Lato-Hairline"
#define kLatoHairlineItalic @"Lato-HairlineItalic"
#define kLatoBlack @"Lato-Black"
#define kLatoBlackItalic @"Lato-BlackItalic"
#define kLatoBold @"Lato-Bold"
#define kLatoBoldItalic @"Lato-BoldItalic"

//Reports
#define kDaily @"Daily"
#define kSafety @"Safety"
#define kWeekly @"Weekly"

#define kReport @"Report"
#define kChecklistItem @"ChecklistItem"
#define kComment @"Comment"
#define kTask @"Task"
#define kPhoto @"Photo"
#define kReminder @"Reminder"
#define kFolder @"Folder"

//Numerical Constants
#define kOfflineStatusHeight 25.f

//Colors
#define kBackgroundFade 0.3f
#define kLightestGrayColor [UIColor colorWithWhite:.95 alpha:1.0]
#define kLighterGrayColor [UIColor colorWithWhite:.925 alpha:1.0]
#define kLightGrayColor [UIColor colorWithWhite:.90 alpha:.9]
#define kSeparatorColor [UIColor colorWithWhite:.925 alpha:1]
#define kPlaceholderTextColor [UIColor colorWithWhite:.7 alpha:1]

#define kDarkerGrayColor [UIColor colorWithWhite:.06 alpha:0.9]
#define kDarkGrayColor [UIColor colorWithWhite:.05 alpha:1.0]
#define kBackgroundBlack [UIColor colorWithWhite:1.0 alpha:0.1]
#define kLightBlueColor [UIColor colorWithRed:(85.0/255.0) green:(140.0/255.0) blue:(200.0/255.0) alpha:1.0]
#define kBlueColor [UIColor colorWithRed:(51.0/255.0) green:(102.0/255.0) blue:(153.0/255.0) alpha:1.0]
#define kElectricBlueColor [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1.0]
#define kBlueTransparentColor [UIColor colorWithRed:(51.0/255.0) green:(102.0/255.0) blue:(153.0/255.0) alpha:0.9]
#define kSelectBlueColor [UIColor colorWithRed:(0.0/255.0) green:(122.0/255.0) blue:(255.0/255.0) alpha:1.0]
#define kDarkShade3 [UIColor colorWithRed:(77.0/255.0) green:(97.0/255.0) blue:(117.0/255.0) alpha:1.0]
#define kDarkShade2 [UIColor colorWithRed:(126.0/255.0) green:(144.0/255.0) blue:(162.0/255.0) alpha:1.0]
#define kDarkShade1 [UIColor colorWithRed:(163.0/255.0) green:(178.0/255.0) blue:(192.0/255.0) alpha:1.0]

#define kElectricBlue [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1]

#endif
