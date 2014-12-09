//
//  BHReportViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportViewController.h"
#import "BHTabBarViewController.h"
#import "UIButton+WebCache.h"
#import "BHAppDelegate.h"
#import "BHTaskViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHPersonnelPickerViewController.h"
#import "Activity+helper.h"
#import "Project+helper.h"
#import "Photo+helper.h"
#import "SafetyTopic+helper.h"
#import "Address+helper.h"
#import "Report+helper.h"

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    
    NSDateFormatter *formatter;
    NSDateFormatter *timeStampFormatter;
    NSNumberFormatter *numberFormatter;
    NSDateFormatter *commentFormatter;
    
    User *currentUser;
    UIView *overlayBackground;

    UIBarButtonItem *backButton;
    
    CGFloat topInset;
    NSInteger currentPage;
}

@end

@implementation BHReportViewController

@synthesize report = _report;
@synthesize reports = _reports;
@synthesize project = _project;
@synthesize reportTableView = _reportTableView;

- (void)viewDidLoad {
    self.view.backgroundColor = kLighterGrayColor;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    [super viewDidLoad];
    appDelegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [appDelegate manager];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];

    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    [self setUpFormatters];
    [self setUpDatePicker];
    
    [_collectionView.collectionViewLayout invalidateLayout];
    topInset = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    [_collectionView setDirectionalLockEnabled:YES];
    [_collectionView setContentSize:CGSizeMake(width, height-topInset)];
}

- (void)setUpFormatters {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    
    timeStampFormatter = [[NSDateFormatter alloc] init];
    [timeStampFormatter setLocale:[NSLocale currentLocale]];
    [timeStampFormatter setDateFormat:@"MMM d \n h:mm a"];
    
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _reports.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHReportsCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ReportsCollectionCell" forIndexPath:indexPath];
    Report *report = _reports[indexPath.item];
    [cell setReportVC:self];
    [cell configureForReport:report withDateFormatter:formatter andNumberFormatter:numberFormatter withTimeStampFormatter:timeStampFormatter withCommentFormatter:commentFormatter withWidth:width andHeight:height];
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(width,height-topInset);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
    self.navigationItem.rightBarButtonItem = _saveCreateButton;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat pageWidth = scrollView.frame.size.width;
    currentPage = floor((x - pageWidth) / pageWidth) + 1;
    
    _reportTableView = [(BHReportsCollectionCell*)_collectionView.visibleCells.firstObject reportTableView];
    if (_reports.count > currentPage){
        //changing the datasource, which changes as the collectionView is horizontally scrolled
        if (![_report.identifier isEqualToNumber:[(Report*)_reports[currentPage] identifier]]){
            _report = _reports[currentPage];
            self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
        }
    }
}

- (void)loadReport {
    if (_reportTableView.report.identifier){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [_reportTableView.report.dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        [manager GET:[NSString stringWithFormat:@"%@/reports/%@/review_report",kApiBaseUrl,_project.identifier] parameters:@{@"date_string":slashSafeDate} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting report: %@",responseObject);
            //_report = [[Report alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            [ProgressHUD dismiss];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting report: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        [vc setProject:_project];
        [vc setReport:_reportTableView.report];
        [vc setCompany:_project.company];
        if ([sender isKindOfClass:[NSString class]] && [sender isEqualToString:kCompany]){
            [vc setCompanyMode:YES];
        } else {
            [vc setCompanyMode:NO];
        }
    }
}

- (void)setUpDatePicker {
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
}

- (void)back:(UIBarButtonItem*)backBarButton {
    if (backBarButton == backButton){
        if (self.checkForUnsavedChanges){
            
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

- (NSInteger)checkForUnsavedChanges {
    __block NSInteger unsavedCount = 0;
    [_reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.saved isEqualToNumber:@NO]){
            unsavedCount ++;
        }
    }];
    NSLog(@"unsaved changes count: %ld",(long)unsavedCount);
    if (unsavedCount) {
        NSString *message;
        if (unsavedCount == 1){
            message = [NSString stringWithFormat:@"1 report has unsaved changes. Do you want to save this report?"];
        } else {
            message = [NSString stringWithFormat:@"%ld reports have unsaved changed. Do you want to save these changes?",(long)unsavedCount];
        }
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    }
    return unsavedCount;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
