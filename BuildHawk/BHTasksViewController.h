//
//  BHTasksViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHDeselectableSegmentedControl.h"
#import "Project.h"

@interface BHTasksViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet BHDeselectableSegmentedControl *segmentedControl;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSMutableArray *worklistItems;
@property BOOL connectMode;

@end
