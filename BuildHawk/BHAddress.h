//
//  BHAddress.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/15/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHAddress : NSObject
@property (copy, nonatomic) NSString *formattedAddress;
@property (copy, nonatomic) NSString *street1;
@property (copy, nonatomic) NSString *street2;
@property (copy, nonatomic) NSString *city;
@property (copy, nonatomic) NSString *state;
@property (copy, nonatomic) NSString *country;
@property (copy, nonatomic) NSString *zip;
@property float latitude;
@property float longitude;

- (id) initWithDictionary:(NSDictionary*)dictionary;

@end
