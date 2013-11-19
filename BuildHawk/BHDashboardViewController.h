//
//  BHDashboardViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWRevealViewController/SWRevealViewController.h>
#import "BHUser.h"

@interface BHDashboardViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *searchContainerView;
-(IBAction)revealMenu;

@end
