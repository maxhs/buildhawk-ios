//
//  BHMenuViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) User *currentUser;
@end
