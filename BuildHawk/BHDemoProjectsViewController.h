//
//  BHDemoProjectsViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHDemoProjectsViewController : UIViewController <UITableViewDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) User *currentUser;
@end
