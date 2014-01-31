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
@property (strong, nonatomic) NSMutableArray *userArray;
@property (strong, nonatomic) NSMutableArray *subArray;
@property (strong, nonatomic) NSMutableArray *personnelArray;
@property BOOL countNotNeeded;
@property BOOL phone;
@property BOOL email;

@end
