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
#import "MWPhotoBrowser.h"

@protocol BHReportCellDelegate <NSObject>

@required
- (void)beginEditing;
- (void)doneEditing;
- (void)post;
@optional
- (void)chooseCompany;
- (void)choosePersonnel;
- (void)showSafetyTopic;
- (void)showDatePicker;
- (void)prefill;
- (void)choosePhoto;
- (void)takePhoto;
- (void)showPhotoBrowserWithPhotos:(NSMutableArray*)browserPhotos withCurrentIndex:(NSUInteger)idx;
@end

@interface BHReportsCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet BHReportTableView *reportTableView;
@property (weak, nonatomic) id <BHReportCellDelegate> delegate;
@property BOOL canPrefill;

- (void)configureForReport:(NSNumber*)reportId withDateFormatter:(NSDateFormatter*)dateFormatter andNumberFormatter:(NSNumberFormatter*)numberFormatter withTimeStampFormatter:(NSDateFormatter*)timeStampFormatter withCommentFormatter:(NSDateFormatter*)commentFormatter withWidth:(CGFloat)width andHeight:(CGFloat)height;
@end