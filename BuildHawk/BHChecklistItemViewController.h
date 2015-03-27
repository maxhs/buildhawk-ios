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

@protocol BHChecklistItemDelegate <NSObject>

@required
- (void)itemCreated:(NSNumber*)itemId;
- (void)itemUpdated:(NSNumber*)itemId;
@end

@interface BHChecklistItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) ChecklistItem *item;
@property (strong, nonatomic) Project *project;
@property (weak, nonatomic) IBOutlet UIView *datePickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) id<BHChecklistItemDelegate> itemDelegate;
@property int row;
@end
