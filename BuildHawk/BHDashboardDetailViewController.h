//
//  BHDashboardDetailViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHProject.h"

@interface BHDashboardDetailViewController : UITableViewController
@property (strong, nonatomic) BHProject *project;
@property (strong, nonatomic) NSMutableArray *notifications;
@property (strong, nonatomic) NSMutableArray *recentChecklistItems;
@property (strong, nonatomic) NSMutableArray *upcomingChecklistItems;
@property (strong, nonatomic) NSMutableArray *recentlyCompletedWorklistItems;
@property (strong, nonatomic) NSMutableArray *recentDocuments;
@property (strong, nonatomic) NSMutableArray *categories;
@end
