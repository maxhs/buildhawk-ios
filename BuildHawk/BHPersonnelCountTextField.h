//
//  BHPersonnelCountTextField.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 5/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kUserHours = 0,
    kSubcontractorCount
} BHPersonnelType;

@interface BHPersonnelCountTextField : UITextField
@property (assign) BHPersonnelType personnelType;
@end
