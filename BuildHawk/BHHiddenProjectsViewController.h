//
//  BHHiddenProjectsViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+helper.h"

@interface BHHiddenProjectsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
