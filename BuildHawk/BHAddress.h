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
@property (copy, nonatomic) NSString *streetNumber;
@property (copy, nonatomic) NSString *route;
@property (copy, nonatomic) NSString *postalCode;
@property float latitude;
@property float longitude;
@end
