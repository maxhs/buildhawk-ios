//
//  BHReport.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"
#import <CoreData/CoreData.h>
#import "Report.h"
#import "Photo.h"
#import "SafetyTopic+helper.h"
#import "User+helper.h"
#import "ReportUser+helper.h"
#import "ReportSub.h"
#import "Subcontractor.h"

@interface Report (helper)

- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) update:(NSDictionary*)dictionary;
- (void) addSafetyTopic:(SafetyTopic*)topic;
- (void) removeSafetyTopic:(SafetyTopic*)topic;
- (void) addReportUser:(ReportUser*)reportUser;
- (void) removeReportUser:(ReportUser*)reportUser;
- (void) clearReportUsers;
- (void) addPhoto:(Photo*)photo;
- (void) removePhoto:(Photo*)photo;
- (void) addReportSubcontractor:(ReportSub*)reportSubcontractor;
- (void) removeReportSubcontractor:(ReportSub*)reportSubcontractor;
- (void) clearReportSubcontractors;
@end
