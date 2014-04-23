//
//  BHChecklist.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/28/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHProject.h"
#import <CoreData/CoreData.h>

@interface BHChecklist : NSObject

@property (nonatomic, copy) NSNumber *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) BHProject *project;
@property (strong, nonatomic) NSMutableArray *children;

//- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
