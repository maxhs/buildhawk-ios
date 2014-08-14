//
//  BHTaskViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WorklistItem+helper.h"
#import "Project+helper.h"

@interface BHTaskViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) WorklistItem *task;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *assigneeButton;
@property (weak, nonatomic) IBOutlet UITextView *itemTextView;
@property (weak, nonatomic) IBOutlet UIButton *completionButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSSet *locationSet;
@property BOOL connectMode;
-(IBAction)completionTapped;
-(IBAction)takePhoto;
-(IBAction)choosePhoto;
- (void)drawItem;
@end
