//
//  BHComment.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/13/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHUser.h"

@interface BHComment : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) BHUser *user;
@property (nonatomic, strong) NSDate *createdOn;
@property (nonatomic, strong) NSString *createdOnString;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
