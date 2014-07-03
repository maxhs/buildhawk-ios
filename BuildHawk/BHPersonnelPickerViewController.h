//
//  BHPersonnelPickerViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Company.h"
#import "Project.h"
#import "WorklistItem.h"

@interface BHPersonnelPickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *addressBookButton;
@property (strong, nonatomic) Company *company;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) WorklistItem *task;
@property (strong, nonatomic) NSMutableOrderedSet *orderedUsers;
@property (strong, nonatomic) NSMutableOrderedSet *orderedSubs;
@property BOOL companyMode;
@property BOOL phone;
@property BOOL email;

@end
