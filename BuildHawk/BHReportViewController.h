//
//  BHReportViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHReportTableView.h"

@interface BHReportViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet BHReportTableView *activeTableView;
@property (weak, nonatomic) IBOutlet BHReportTableView *beforeTableView;
@property (weak, nonatomic) IBOutlet BHReportTableView *afterTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSMutableArray *reports;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIView *datePickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (strong, nonatomic) UIPopoverController *popover;
@end
