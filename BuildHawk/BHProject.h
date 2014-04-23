//
//  BHProject.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHAddress.h"
#import "BHCompany.h"
#import "BHProjectGroup.h"

@interface BHProject : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *subs;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) BHProjectGroup *group;
@property (nonatomic, strong) BHAddress *address;
@property (nonatomic, strong) BHCompany *company;
@property (nonatomic, strong) NSMutableArray *recentDocuments;
@property (nonatomic, strong) NSMutableArray *upcomingItems;
@property (nonatomic, strong) NSMutableArray *recentItems;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, strong) NSMutableArray *checklistCategories;
@property (nonatomic, strong) NSString *progressPercentage;
@property BOOL active;
@property BOOL demo;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
