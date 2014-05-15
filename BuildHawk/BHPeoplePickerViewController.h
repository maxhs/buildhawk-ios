//
//  BHPeoplePickerViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BHPeoplePickerViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *userArray;
@property (strong, nonatomic) NSArray *subArray;
@property (strong, nonatomic) NSMutableOrderedSet *users;
@property BOOL countNotNeeded;
@property BOOL phone;
@property BOOL email;

@end
