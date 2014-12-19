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
#import <CTAssetsPickerController/CTAssetsPickerController.h>

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BHReportCellDelegate, CTAssetsPickerControllerDelegate, MWPhotoBrowserDelegate> {
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    
    NSDateFormatter *formatter;
    NSDateFormatter *timeStampFormatter;
    NSNumberFormatter *numberFormatter;
    NSDateFormatter *commentFormatter;
    
    Report *_report;
    Project *_project;
    User *currentUser;
    UIView *overlayBackground;
    NSMutableArray *_browserPhotos;
    
    UIBarButtonItem *saveButton;
    UIBarButtonItem *addButton;
    UIBarButtonItem *backButton;
    UIBarButtonItem *doneButton;
    
    CGFloat topInset;
    NSInteger currentPage;
}

@end

@implementation BHReportViewController

@synthesize initialReportId = _initialReportId;
@synthesize reports = _reports;
@synthesize projectId = _projectId;
@synthesize reportDateString = _reportDateString;
@synthesize reportType = _reportType;

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

    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"ReportPersonnel" object:nil];
    
    _project = [Project MR_findFirstByAttribute:@"identifier" withValue:_projectId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (_reportDateString.length){
        _report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [_report setDateString:_reportDateString];
        [_report setProject:_project];
        [_report setType:_reportType];
        _reports = [NSArray arrayWithObject:_report];
    } else {
        _report = [Report MR_findFirstByAttribute:@"identifier" withValue:_initialReportId inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    [self setUpFormatters];
    [self setUpDatePicker];
    
    [_collectionView.collectionViewLayout invalidateLayout];
    topInset = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    [_collectionView setDirectionalLockEnabled:YES];
    [_collectionView setContentSize:CGSizeMake(width, height-topInset)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([_report.identifier isEqualToNumber:@0]){
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    
    //make sure we're showing the right report, at the right index
    self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
    NSInteger idx = [_reports indexOfObject:_report];
    [self.collectionView setContentOffset:CGPointMake(width*idx, 0)];
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
    cell.delegate = self;
    Report *report = _reports[indexPath.item];
    _report = report;
    [cell configureForReport:report.identifier withDateFormatter:formatter andNumberFormatter:numberFormatter withTimeStampFormatter:timeStampFormatter withCommentFormatter:commentFormatter withWidth:width andHeight:height];
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(width,height-topInset);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat pageWidth = scrollView.frame.size.width;
    currentPage = floor((x - pageWidth) / pageWidth) + 1;
    
    if (_reports.count > currentPage){
        //changing the datasource, which changes as the collectionView is horizontally scrolled
        _report = _reports[currentPage];
        if ([_report.identifier isEqualToNumber:@0]){
            self.navigationItem.rightBarButtonItem = addButton;
        } else {
            self.navigationItem.rightBarButtonItem = saveButton;
        }
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
    }
}

- (void)loadReport {
    if (![_report.identifier isEqualToNumber:@0]){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [_report.dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
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

- (void)updatePersonnel:(NSNotification*)notification {
    //NSDictionary *info = [notification userInfo];
    [_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        [vc setProjectId:_project.identifier];
        [vc setReportId:_report.identifier];
        [vc setCompanyId:_project.company.identifier];
        if ([sender isKindOfClass:[NSString class]] && [sender isEqualToString:kCompany]){
            [vc setCompanyMode:YES];
        } else {
            [vc setCompanyMode:NO];
        }
    }
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

#pragma mark - BHReportCellDelegate Methods

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset {
    if (picker.selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:nil message:@"We're unable to select more than 10 photos per batch." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}

- (void)takePhoto {
    //saveToLibrary = YES;
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
        [vc setDelegate:self];
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to access a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)choosePhoto {
    //saveToLibrary = NO;
    CTAssetsPickerController *controller = [[CTAssetsPickerController alloc] init];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:NULL];
}

//for taking a photo
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:NULL];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newPhoto setTakenAt:[NSDate date]];
    [newPhoto setImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
    [_report addPhoto:newPhoto];
    [_collectionView reloadData];
    
    //[self saveImage:newPhoto];
}

// for choosing a photo
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [self dismissViewControllerAnimated:YES completion:NULL];
    for (id asset in assets) {
        if (asset != nil) {
            ALAssetRepresentation* representation = [asset defaultRepresentation];
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil)
                orientation = [orientationValue intValue];
            
            UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                 scale:[UIScreen mainScreen].scale orientation:orientation];
            
            Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [newPhoto setTakenAt:[asset valueForProperty:ALAssetPropertyDate]];
            [newPhoto setImage:[self fixOrientation:image]];
            [_report addPhoto:newPhoto];
            //[self saveImage:newPhoto];
        }
    }
    [_collectionView reloadData];
    //[self redrawScrollView:_reportTableView];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *correctedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return correctedImage;
}

- (void)beginEditing {
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneEditing {
    if ([_report.identifier isEqualToNumber:@0]){
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    [self.view endEditing:YES];
}

- (void)showPhotoBrowserWithPhotos:(NSMutableArray *)browserPhotos withCurrentIndex:(NSUInteger)idx {
    _browserPhotos = browserPhotos;
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo isEqualToNumber:@YES]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:idx];
    [self.navigationController pushViewController:browser animated:YES];
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    [_report removePhoto:photoToRemove];
    [_collectionView reloadData];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _browserPhotos.count)
        return [_browserPhotos objectAtIndex:index];
    return nil;
}

- (void)post {
    if ([_project.demo isEqualToNumber:@YES]){
        if ([_report.identifier isEqualToNumber:@0]){
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        
    } else if (appDelegate.connected) {
        
        if ([_report.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [ProgressHUD show:@"Creating report..."];
            [_report synchWithServer:^(BOOL complete) {
                if (complete){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [ProgressHUD showSuccess:@"Report Added"];
                        //[_parentVC.navigationController popViewControllerAnimated:YES];
                    }];
                } else {
                    [ProgressHUD dismiss];
                }
            }];
            
        } else {
            [ProgressHUD show:@"Saving report..."];
            [_report synchWithServer:^(BOOL complete) {
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    if (complete){
                        [ProgressHUD showSuccess:@"Report saved"];
                    } else {
                        //increment the status
                        [appDelegate.syncController update];
                        [ProgressHUD dismiss];
                    }
                }];
            }];
        }
    } else {
        [_report setSaved:@NO];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD showSuccess:@"Report saved"];
            [appDelegate.syncController update];
        }];
    }
}

- (void)prefill {
    NSLog(@"Prefilling from reportview vc");
}

#pragma mark - Date Picker

- (void)setUpDatePicker {
    [_datePickerContainer setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [_cancelButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"wideButton"] forState:UIControlStateNormal];
    [_selectButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProSemibold] size:0]];
}

- (void)showDatePicker{
    if (overlayBackground == nil){
        overlayBackground = [appDelegate addOverlayUnderNav:YES];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelDatePicker)];
        tapGesture.numberOfTapsRequired = 1;
        [overlayBackground addGestureRecognizer:tapGesture];
        [self.view insertSubview:overlayBackground belowSubview:_datePickerContainer];
        [self.view bringSubviewToFront:_datePickerContainer];
        [UIView animateWithDuration:0.75 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _datePickerContainer.transform = CGAffineTransformMakeTranslation(0, -_datePickerContainer.frame.size.height);
            
            if (IDIOM == IPAD)
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 56);
            else
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [self cancelDatePicker];
    }
}

- (IBAction)selectDate {
    [self cancelDatePicker];
    NSString *dateString = [formatter stringFromDate:self.datePicker.date];
    BOOL duplicate = NO;
    for (Report *report in _project.reports){
        if ([report.type isEqualToString:_report.type] && [report.dateString isEqualToString:dateString]) duplicate = YES;
    }
    if (duplicate){
        [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        _report.dateString = dateString;
        self.title = [NSString stringWithFormat:@"%@ - %@",_report.type, _report.dateString];
        [self.collectionView reloadData];
    }
}

- (IBAction)cancelDatePicker{
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _datePickerContainer.transform = CGAffineTransformIdentity;
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
        [overlayBackground setAlpha:0];
    } completion:^(BOOL finished) {
        overlayBackground = nil;
        [overlayBackground removeFromSuperview];
    }];
}

- (void)choosePersonnel {
    [self performSegueWithIdentifier:@"PersonnelPicker" sender:kIndividual];
}

- (void)chooseCompany {
    [self performSegueWithIdentifier:@"PersonnelPicker" sender:kCompany];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
