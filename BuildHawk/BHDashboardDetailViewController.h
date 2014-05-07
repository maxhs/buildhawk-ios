//
//  BHDashboardDetailViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Project+helper.h"

@interface BHDashboardDetailViewController : UITableViewController
@property (strong, nonatomic) Project *project;
@end
