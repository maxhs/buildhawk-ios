//
//  BHAddressBookPickerViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/18/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Subcontractor+helper.h"

@interface BHAddressBookPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *peopleArray;
@property (strong, nonatomic) Subcontractor *subcontractor;
@property (strong, nonatomic) WorklistItem *task;
@end