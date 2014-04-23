//
//  BHSub.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSub : NSObject

@property (strong, nonatomic) NSNumber *identifier;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *phone;
@property (nonatomic, strong) NSString *formatted_phone;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *count;
@property (strong, nonatomic) NSNumber *reportSubId;

- (id) initWithDictionary:(NSDictionary*)dictionary;
- (void)encodeWithCoder:(NSCoder *)coder;
@end
