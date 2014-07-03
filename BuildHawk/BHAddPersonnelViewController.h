//
//  BHAddPersonnelViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Company+helper.h"

@interface BHAddPersonnelViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Company *company;
@property (strong, nonatomic) WorklistItem *task;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSString *name;
@property BOOL companyMode;

@end
