//
//  Report.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/21/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Report : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * createdOnString;
@property (nonatomic, retain) NSArray *photos;
@property (nonatomic, retain) NSArray *subcontractors;

@end
