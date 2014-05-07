//
//  BHReport.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"
#import "Project.h"
#import <CoreData/CoreData.h>
#import "Report.h"
#import "BHSafetyTopic.h"

@interface Report (helper)

- (void) populateWithDict:(NSDictionary*)dictionary;
- (void) addSafetyTopic:(BHSafetyTopic*)topic;
@end
