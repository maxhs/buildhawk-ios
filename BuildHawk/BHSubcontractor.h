//
//  BHSubcontractor.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 11/14/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHSubcontractor : NSObject
@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSString *count;
@property (copy, nonatomic) NSString *name;
- (id) initWithDictionary:(NSDictionary*)dictionary;
@end
