//
//  BHTabBarViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "User.h"

@interface BHTabBarViewController : UITabBarController <UITabBarDelegate, UITabBarControllerDelegate>
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) NSIndexPath *checklistIndexPath;
@end
