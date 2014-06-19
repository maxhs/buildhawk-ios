//
//  BHChecklistItemViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChecklistItem.h"
#import "Comment.h"
#import "Photo.h"
#import "Project.h"
#import "BHDatePicker.h"

@interface BHChecklistItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) ChecklistItem *item;
@property (strong, nonatomic) Project *project;
@property (weak, nonatomic) IBOutlet UIView *datePickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property int row;
@end
