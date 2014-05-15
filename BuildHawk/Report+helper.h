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
#import "BHSafetyTopic.h"
#import "User+helper.h"

@interface Report (helper)

- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) addSafetyTopic:(BHSafetyTopic*)topic;
- (void) addReportUser:(User*)reportUser;
- (void) removeReportUser:(User*)reportUser;
- (void) addPhoto:(Photo*)photo;
- (void) removePhoto:(Photo*)photo;
@end
