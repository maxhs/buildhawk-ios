//
//  BHActivitiesViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/2/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+helper.h"

@interface BHActivitiesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) Project *project;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSOrderedSet *activities;
@property (strong, nonatomic) NSMutableOrderedSet *reminders;
@property (strong, nonatomic) NSOrderedSet *deadlineItems;

@end
