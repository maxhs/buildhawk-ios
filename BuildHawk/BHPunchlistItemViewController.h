//
//  BHPunchlistItemViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPunchlistItem.h"
#import "User.h"

@interface BHPunchlistItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) BHPunchlistItem *punchlistItem;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *photoLabelButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *assigneeButton;
@property (weak, nonatomic) IBOutlet UITextView *itemTextView;
@property (weak, nonatomic) IBOutlet UIButton *completionButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) User *savedUser;
@property (strong, nonatomic) BHProject *project;
@property (strong, nonatomic) NSSet *locationSet;
@property BOOL newItem;
-(IBAction)completionTapped;
-(IBAction)photoButtonTapped;
@end
