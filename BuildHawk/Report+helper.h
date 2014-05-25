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
#import "SafetyTopic+helper.h"
#import "User+helper.h"
#import "Subcontractor.h"

@interface Report (helper)

- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) addSafetyTopic:(SafetyTopic*)topic;
- (void) removeSafetyTopic:(SafetyTopic*)topic;
- (void) addReportUser:(User*)reportUser;
- (void) removeReportUser:(User*)reportUser;
- (void) clearReportUsers;
- (void) addPhoto:(Photo*)photo;
- (void) removePhoto:(Photo*)photo;
- (void) addReportSubcontractor:(Subcontractor*)reportSubcontractor;
- (void) removeReportSubcontractor:(Subcontractor*)reportSubcontractor;
- (void) clearReportSubcontractors;
@end
