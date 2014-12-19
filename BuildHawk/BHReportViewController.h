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
@property (strong, nonatomic) NSString *reportDateString;
@property (strong, nonatomic) NSString *reportType;
@property (strong, nonatomic) NSNumber *initialReportId;
@property (strong, nonatomic) NSNumber *projectId;
@property (strong, nonatomic) NSArray *reports;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIView *datePickerContainer;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (strong, nonatomic) UIPopoverController *popover;
@property (weak, nonatomic) id<BHReportDelegate> reportDelegate;

@end
