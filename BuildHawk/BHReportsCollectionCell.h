//
//  BHReportsCollectionCell.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 12/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHReportViewController.h"
#import "BHReportTableView.h"
#import "Report+helper.h"

@interface BHReportsCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet BHReportTableView *reportTableView;
@property (strong, nonatomic) UIViewController *reportVC;
@property (strong, nonatomic) Report *report;

- (void)configureForReport:(Report*)report withDateFormatter:(NSDateFormatter*)dateFormatter andNumberFormatter:(NSNumberFormatter*)numberFormatter withTimeStampFormatter:(NSDateFormatter*)timeStampFormatter withCommentFormatter:(NSDateFormatter*)commentFormatter withWidth:(CGFloat)width andHeight:(CGFloat)height;
@end
