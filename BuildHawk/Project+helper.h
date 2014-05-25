//
//  Project+helper.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/24/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "Project.h"
#import "User.h"
#import "ChecklistItem.h"
#import "Cat.h"

@interface Project (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary;
- (void)parseDocuments:(NSArray*)array;
- (void)addPhoto:(Photo *)photo;
- (void)removePhoto:(Photo *)photo;
- (void)addReport:(Report *)report;
- (void)removeReport:(Report *)report;
- (void)clearReports;
@end
