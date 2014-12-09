//
//  BHReportViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHReportTableView.h"
#import "BHReportsCollectionCell.h"

@protocol BHReportDelegate <NSObject>

@required
- (void)newReportCreated:(NSNumber*)reportId;
@end

@interface BHReportViewController : UIViewController
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) BHReportTableView *reportTableView;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSMutableArray *reports;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIView *datePickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) UIBarButtonItem *saveCreateButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

@property (weak, nonatomic) id<BHReportDelegate> delegate;
@end
