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

@interface BHChecklistItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) ChecklistItem *item;
@property (strong, nonatomic) Project *project;
@property int row;

@end
