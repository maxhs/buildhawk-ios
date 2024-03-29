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
#import "SafetyTopic+helper.h"
#import "MWPhotoBrowser.h"
#import "Activity+helper.h"
#import "BHReportPhotoScrollView.h"

@protocol BHReportCellDelegate <NSObject>
@required
- (void)post;
@optional
- (void)showReportTypePicker;
- (void)chooseCompany;
- (void)showPersonnelActionSheet;
- (void)showTopicsActionSheet;
- (void)showSafetyTopic:(SafetyTopic*)topic fromCellRect:(CGRect)cellRect;
- (void)showDatePicker;
- (void)prefill;
- (void)choosePhoto;
- (void)takePhoto;
- (void)showPhotoBrowserWithPhotos:(NSMutableArray*)browserPhotos withCurrentIndex:(NSUInteger)idx;
- (void)showActivity:(Activity *)activity;
@end

@interface BHReportsCollectionCell : UICollectionViewCell

@property (strong, nonatomic) NSNumber *projectId;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet BHReportTableView *reportTableView;
@property (weak, nonatomic) id <BHReportCellDelegate> delegate;
@property BOOL canPrefill;

- (void)configureForReport:(Report*)report withDateFormatter:(NSDateFormatter*)dateFormatter andNumberFormatter:(NSNumberFormatter*)numberFormatter withTimeStampFormatter:(NSDateFormatter*)timeStampFormatter withCommentFormatter:(NSDateFormatter*)commentFormatter withWidth:(CGFloat)width andHeight:(CGFloat)height;
@end
