//
//  BHPersonnelPickerViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHPersonnelPickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Company *company;
@property (strong, nonatomic) NSMutableOrderedSet *users;
@property (strong, nonatomic) NSMutableOrderedSet *orderedUsers;
@property (strong, nonatomic) NSMutableOrderedSet *orderedSubs;
@property BOOL companyMode;
@property BOOL countNotNeeded;
@property BOOL phone;
@property BOOL email;

@end
