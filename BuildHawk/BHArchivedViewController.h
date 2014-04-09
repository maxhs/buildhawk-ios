//
//  BHArchivedViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 4/9/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHProject.h"

@interface BHArchivedViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *archivedProjects;

@end
