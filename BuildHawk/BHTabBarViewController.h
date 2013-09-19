//
//  BHTabBarViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHProject.h"

@interface BHTabBarViewController : UITabBarController
@property (strong, nonatomic) BHProject *project;
@end
