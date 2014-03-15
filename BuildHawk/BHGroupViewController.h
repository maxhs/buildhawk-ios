//
//  BHGroupViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/15/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHProject.h"

@interface BHGroupViewController : UIViewController <UITableViewDelegate, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) BHProject *project;
@end
