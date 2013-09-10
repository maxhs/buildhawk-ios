//
//  BHItem.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/4/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BHItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property BOOL checklist;
@property BOOL punchlist;

@end
