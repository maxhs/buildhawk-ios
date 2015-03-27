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
#import "BHSafetyTopicsCell.h"
#import "BHSafetyTopicTransition.h"
#import "BHSafetyTopicViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BHImagePickerController.h"
#import "BHAssetGroupPickerViewController.h"
#import "BHTaskViewController.h"
#import "BHUtilities.h"

@interface BHReportViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate, BHReportCellDelegate, BHImagePickerControllerDelegate, MWPhotoBrowserDelegate, BHPersonnelPickerDelegate> {
    BHAppDelegate *appDelegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    
    NSDateFormatter *formatter;
    NSDateFormatter *timeStampFormatter;
    NSNumberFormatter *numberFormatter;
    NSDateFormatter *commentFormatter;
    UIView *overlayBackground;
    NSMutableArray *_browserPhotos;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *addButton;
    UIBarButtonItem *backButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *refreshButton;
    
    UIAlertView *addOtherAlertView;
    UIAlertView *newTopicAlertView;
    UIActionSheet *typePickerActionSheet;
    UIActionSheet *personnelActionSheet;
    UIActionSheet *topicsActionSheet;
    
    CGFloat topInset;
    NSInteger currentPage;
    ALAssetsLibrary *library;
    BOOL saveToLibrary;
    NSMutableOrderedSet *_reports;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) BHReportTableView *activeTableView;
@end

@implementation BHReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kLighterGrayColor;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }
    
    [self registerForKeyboardNotifications];
    appDelegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [appDelegate manager];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    self.currentUser = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];

    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshReport)];
    
    if (self.navigationController.viewControllers.firstObject == self){
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        self.navigationItem.leftBarButtonItems = @[backButton, refreshButton];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    
    self.project = [self.project MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    _reports = self.project.reports.mutableCopy;
    
    if (_reportDateString) {
        self.report = [Report MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        self.report.author.identifier = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId];
        self.report.project = self.project;
        self.report.dateString = _reportDateString;
        self.report.type = _reportType;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [_reports insertObject:self.report atIndex:0];
    } else if (self.report) {
        self.report = [self.report MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    [self setUpFormatters];
    [self setUpDatePicker];
    
    topInset = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
    [self.collectionView setDirectionalLockEnabled:YES];
    [self.collectionView setContentSize:CGSizeMake(width, height - topInset)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.report.identifier isEqualToNumber:@0]){
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    //make sure we're showing the right report, at the right index
    self.title = [NSString stringWithFormat:@"%@ - %@",self.report.type, self.report.dateString];
    NSInteger idx = [_reports indexOfObject:self.report];
    [self.collectionView setContentOffset:CGPointMake(width * idx, 0)];
    [self.collectionView reloadData];
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

- (void)refreshReport {
    [manager GET:[NSString stringWithFormat:@"%@/reports/%@",kApiBaseUrl,self.report.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success fetching report after refresh: %@",responseObject);
        [self.report populateFromDictionary:[responseObject objectForKey:@"report"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.collectionView reloadData];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching report: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to refresh this report." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
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
    cell.projectId = self.project.identifier;
    Report *report = _reports[indexPath.item];
    [cell configureForReport:report withDateFormatter:formatter andNumberFormatter:numberFormatter withTimeStampFormatter:timeStampFormatter withCommentFormatter:commentFormatter withWidth:width andHeight:height];
    [cell setCollectionView:self.collectionView];
    
    cell.canPrefill = indexPath.row == _reports.count ? NO : YES; // set the prefill accordingly
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
        self.report = _reports[currentPage];
        if ([self.report.identifier isEqualToNumber:@0]){
            //ensure the report has been properly fetched
            self.navigationItem.rightBarButtonItem = addButton;
            self.report = (Report*)[[NSManagedObjectContext MR_defaultContext] objectWithID:self.report.objectID];
        } else {
            self.navigationItem.rightBarButtonItem = saveButton;
            NSNumber *identifier = self.report.identifier;
            self.report = [Report MR_findFirstByAttribute:@"identifier" withValue:identifier inContext:[NSManagedObjectContext MR_defaultContext]];
        }
        self.title = [NSString stringWithFormat:@"%@ - %@",self.report.type, self.report.dateString];
    }
    BHReportsCollectionCell *activeCell = (BHReportsCollectionCell*)self.collectionView.visibleCells.firstObject;
    _activeTableView = activeCell.reportTableView;
}

- (void)loadReport {
    if (![self.report.identifier isEqualToNumber:@0]){
        [ProgressHUD show:@"Fetching report..."];
        NSString *slashSafeDate = [self.report.dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        [manager GET:[NSString stringWithFormat:@"%@/reports/%@/review_report",kApiBaseUrl,self.project.identifier] parameters:@{@"date_string":slashSafeDate} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting report: %@",responseObject);
            //self.report = [[Report alloc] initWithDictionary:[responseObject objectForKey:@"report"]];
            [ProgressHUD dismiss];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting report: %@",error.description);
            [ProgressHUD dismiss];
        }];
    }
}

- (void)reportUserAdded:(ReportUser *)reportUser {
    [self.report addReportUser:reportUser];
    NSLog(@"user added");
    [self.activeTableView reloadData];
    [self.collectionView reloadData];
}

- (void)reportUserRemoved:(ReportUser *)reportUser {
    [self.report removeReportUser:reportUser];
    [self.activeTableView reloadData];
}

- (void)reportSubAdded:(ReportSub *)reportSub {
    [self.report addReportSubcontractor:reportSub];
    [self.activeTableView reloadData];
    //[_activeTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reportSubRemoved:(ReportSub *)reportSub {
    [self.report removeReportSubcontractor:reportSub];
    [self.activeTableView reloadData];
    //[_activeTableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        BHPersonnelPickerViewController *vc = [segue destinationViewController];
        vc.personnelDelegate = self;
        [vc setProjectId:self.project.identifier];
        [vc setReportId:self.report.identifier];
        [vc setCompanyId:self.project.company.identifier];
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
- (void)showActivity:(Activity *)a {
    Activity *activity = [a MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (activity.task){
        [ProgressHUD show:@"Loading..."];
        BHTaskViewController *taskVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Task"];
        [taskVC setTaskId:activity.task.objectID];
        [taskVC setProject:activity.task.project];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:taskVC];
        [self presentViewController:nav animated:YES completion:nil];
    } else if (activity.report){
//        if (![activity.report.identifier isEqualToNumber:_report.identifier]){
//            [ProgressHUD show:@"Loading..."];
//            BHReportViewController *singleReportVC = [[self storyboard] instantiateViewControllerWithIdentifier:@"Report"];
//            [singleReportVC setInitialReportId:activity.report.identifier];
//            //set the reports so that the check for unsaved changes method catches
//            //[singleReportVC setReports:@[activity.report].mutableCopy];
//            [singleReportVC setProjectId:activity.report.project.identifier];
//            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:singleReportVC];
//            [self presentViewController:nav animated:YES completion:NULL];
//        }
    } else if (activity.checklistItem){
        [ProgressHUD show:@"Loading..."];
        BHChecklistItemViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ChecklistItem"];
        [vc setItem:activity.checklistItem];
        [vc setProject:self.project];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:NULL];
    }
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

//for taking a photo
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:NULL];
    UIImage *image = [BHUtilities fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
    Photo *photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [photo setTakenAt:[NSDate date]];
    [photo setImage:image];
    [self.report addPhoto:photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.collectionView reloadData];
    [self saveImage:image forPhoto:photo];
}

// for choosing a photo
- (void)choosePhoto {
    saveToLibrary = NO;
    [self performSegueWithIdentifier:@"AssetGroupPicker" sender:nil];
}

- (void)didFinishPickingPhotos:(NSOrderedSet *)selectedPhotos {
    for (Photo *p in selectedPhotos){
        Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self.report addPhoto:photo];
        [self saveImage:photo.image forPhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.collectionView reloadData];
    [self.navigationController popToViewController:self animated:YES];
    [ProgressHUD dismiss];
}

- (void)saveImage:(UIImage*)image forPhoto:(Photo*)photo {
    [self saveImageToLibrary:image];
    if (![self.report.identifier isEqualToNumber:@0]){
        [self uploadPhoto:photo forReport:self.report];
    }
}

- (void)saveImageToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        if (!library) library = [[ALAssetsLibrary alloc] init];
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
        [library addAssetsGroupAlbumWithName:albumName
                                 resultBlock:^(ALAssetsGroup *group) { }
                                failureBlock:^(NSError *error) {
                                    NSLog(@"error adding album");
                                }];
        
        __block ALAssetsGroup* groupToAddTo;
        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                   if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                       groupToAddTo = group;
                                   }
                               }
                             failureBlock:^(NSError* error) {
                                 NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                             }];
        
        [library writeImageToSavedPhotosAlbum:imageToSave.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error.code == 0) {
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             [groupToAddTo addAsset:asset];
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            } else {
                //NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
            }
        }];
    }
}

- (void)uploadPhoto:(Photo*)photo forReport:(Report*)report {
    if (![self.project.demo isEqualToNumber:@YES]){
        [report setSaved:@NO];
        [photo setProject:self.project];
        [photo setSaved:@NO];
        [photo synchWithServer:^(BOOL completed) {
            [appDelegate.syncController update];
        }];
    }
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (notification) {
        self.navigationItem.rightBarButtonItem = doneButton;
        NSDictionary* info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
        CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
        CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
        [UIView animateWithDuration:duration
                              delay:0
                            options:curve | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             _activeTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                             _activeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         }
                         completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (notification) {
        NSDictionary* info = [notification userInfo];
        NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
        [UIView animateWithDuration:duration
                              delay:0
                            options:curve | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             _activeTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                             _activeTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                         }
                         completion:^(BOOL finished) {
                             [self doneEditing];
                         }];
    }
}

- (void)doneEditing {
    if ([self.report.identifier isEqualToNumber:@0]){
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    [self.view endEditing:YES];
}

- (void)showPhotoBrowserWithPhotos:(NSMutableArray *)browserPhotos withCurrentIndex:(NSUInteger)idx {
    _browserPhotos = browserPhotos;
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([self.project.demo isEqualToNumber:@YES]) {
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
    [browser setProject:self.project];
    [self.navigationController pushViewController:browser animated:YES];
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    [self.report removePhoto:photoToRemove];
    [self.collectionView reloadData];
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
    if ([self.project.demo isEqualToNumber:@YES]){
        if ([self.report.identifier isEqualToNumber:@0]){
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new reports for demo projects." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if (appDelegate.connected) {
        
        if ([self.report.identifier isEqualToNumber:@0]){
            [ProgressHUD show:@"Creating report..."];
            [self.report synchWithServer:^(BOOL complete) {
                if (complete){
                    [self.report setSaved:@YES];
                    self.navigationItem.rightBarButtonItem = saveButton;
                    [ProgressHUD showSuccess:@"Report Added"];
                } else {
                    [self.report setSaved:@NO];
                    [appDelegate.syncController update];
                    [ProgressHUD dismiss];
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                [self.collectionView reloadData];
            }];
        } else {
            [ProgressHUD show:@"Saving report..."];
            [self.report synchWithServer:^(BOOL complete) {
                if (complete){
                    [self.report setSaved:@YES];
                    [ProgressHUD showSuccess:@"Report saved"];
                } else {
                    [self.report setSaved:@NO];
                    [appDelegate.syncController update]; //increment the status
                    [ProgressHUD dismiss];
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                [self.collectionView reloadData];
            }];
        }
    } else {
        [self.report setSaved:@NO];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD showSuccess:@"Report saved"];
            [self.activeTableView reloadData];
            [appDelegate.syncController update];
        }];
    }
}

#pragma mark - UIActionSheet Delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.report setSaved:@NO];
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        //let the action sheet dismiss itself
    } else if (actionSheet == typePickerActionSheet){
        BOOL duplicate = NO;
        for (Report *report in self.project.reports){
            if ([report.type isEqualToString:buttonTitle] && [report.dateString isEqualToString:self.report.dateString]) duplicate = YES;
        }
        if (!duplicate){
            self.report.type = buttonTitle;
            self.title = [NSString stringWithFormat:@"%@ - %@",self.report.type, self.report.dateString];
            [self.collectionView reloadData];
            if ([self.report.type isEqualToString:kDaily]){
                //[self loadWeather:[formatter dateFromString:_report.dateString] forTableView:self.beforeTableView];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    } else if (actionSheet == personnelActionSheet){
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kCompany]){
            [self chooseCompany];
        } else {
            [self choosePersonnel];
        }
    } else if (actionSheet == topicsActionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Cancel"]){
            
        } else if ([title isEqualToString:kAddNew]){
            newTopicAlertView = [[UIAlertView alloc] initWithTitle:@"Custom safety topic:" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            newTopicAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [[newTopicAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [newTopicAlertView show];
        } else {
            SafetyTopic *newTopic = [SafetyTopic MR_findFirstByAttribute:@"title" withValue:buttonTitle inContext:[NSManagedObjectContext MR_defaultContext]];
            [self.report addSafetyTopic:newTopic];
            [self.collectionView reloadData];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            ReportUser *user = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [user setFullname:[[alertView textFieldAtIndex:0] text]];
            user.hours = [NSNumber numberWithFloat:0.f];
            if (![self.report.reportUsers containsObject:user]) {
                user.report = self.report;
                [self.report addReportUser:user];
                [self.collectionView reloadData];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Already added!" message:@"Personnel already included" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (alertView == newTopicAlertView) {
        SafetyTopic *topic = [SafetyTopic MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [topic setTitle:[[alertView textFieldAtIndex:0] text]];
        if (![self.report.safetyTopics containsObject:topic]) {
            [self.report addSafetyTopic:topic];
            [self.collectionView reloadData];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Safety topic already added." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }
}

- (void)showReportTypePicker {
    typePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kDaily,kWeekly,kSafety, nil];
    [typePickerActionSheet showInView:self.view];
}

#pragma mark - Personnel Section
- (void)showPersonnelActionSheet {
    personnelActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to add?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kIndividual,kCompany, nil];
    [personnelActionSheet showInView:self.view];
}

- (void)prefill {
    NSDate *currentReportDate = [formatter dateFromString:self.report.dateString];
    if ([self.report.identifier isEqualToNumber:@0]){ // if it's a new report
        NSMutableOrderedSet *orderedReports = [NSMutableOrderedSet orderedSetWithOrderedSet:_reports];
        [_reports enumerateObjectsUsingBlock:^(Report *thisReport, NSUInteger index, BOOL *stop) {
            NSDate *thisReportDate = [formatter dateFromString:thisReport.dateString];
            if ([currentReportDate compare:thisReportDate] == NSOrderedDescending) {
                [orderedReports insertObject:self.report atIndex:index];
                _reports = orderedReports.mutableCopy;
                *stop = YES;
            }
        }];
    }
    
    [_reports enumerateObjectsUsingBlock:^(Report *report, NSUInteger idx, BOOL *stop) {
        if ([report.type isEqualToString:self.report.type] && [currentReportDate compare:report.reportDate] == NSOrderedDescending){
            NSMutableOrderedSet *reportUsers = [NSMutableOrderedSet orderedSet];
            for (ReportUser *reportUser in report.reportUsers){
                ReportUser *newReportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                newReportUser.fullname = reportUser.fullname;
                newReportUser.userId = reportUser.userId;
                newReportUser.hours = reportUser.hours;
                [reportUsers addObject:newReportUser];
            }
            self.report.reportUsers = reportUsers;
            
            NSMutableOrderedSet *reportSubs = [NSMutableOrderedSet orderedSet];
            for (ReportSub *reportSub in report.reportSubs){
                ReportSub *newReportSub = [ReportSub MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                newReportSub.name = reportSub.name;
                newReportSub.companyId = reportSub.companyId;
                newReportSub.count = reportSub.count;
                [reportSubs addObject:newReportSub];
            }
            self.report.reportSubs = reportSubs;
            [self.collectionView reloadData];
            *stop = YES;
        }
    }];
}

#pragma mark - Safety Topic Section
- (void)showSafetyTopic:(SafetyTopic*)topic fromCellRect:(CGRect)cellRect{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD show:@"Fetching safety topic..."];
    });
    if (IDIOM == IPAD){
        BHSafetyTopicViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
        [vc setTitle:[NSString stringWithFormat:@"%@ - %@", self.report.type, self.report.dateString]];
        [vc setSafetyTopic:topic];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromRect:cellRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        [self showSafetyTopic:topic forReport:self.report];
    }
}

-(void)showSafetyTopic:(SafetyTopic*)safetyTopic forReport:(Report*)report {
    BHSafetyTopicViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SafetyTopic"];
    [vc setSafetyTopic:safetyTopic];
    [vc setTitle:[NSString stringWithFormat:@"%@ - %@", report.type, report.dateString]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showTopicsActionSheet {
    topicsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Safety Topics" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (SafetyTopic *topic in self.project.company.safetyTopics){
        [topicsActionSheet addButtonWithTitle:topic.title];
    }
    [topicsActionSheet addButtonWithTitle:kAddNew];
    topicsActionSheet.cancelButtonIndex = [topicsActionSheet addButtonWithTitle:@"Cancel"];
    [topicsActionSheet showInView:self.view];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    BHSafetyTopicTransition *animator = [BHSafetyTopicTransition new];
    return animator;
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
            
            if (IDIOM == IPAD){
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 56);
            } else {
                self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
            }
            
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
    for (Report *report in self.project.reports){
        if ([report.type isEqualToString:self.report.type] && [report.dateString isEqualToString:dateString]) duplicate = YES;
    }
    if (duplicate){
        [[[UIAlertView alloc] initWithTitle:@"Duplicate Report" message:@"A report with that date and type already exists." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        self.report.dateString = dateString;
        self.title = [NSString stringWithFormat:@"%@ - %@",self.report.type, self.report.dateString];
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
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
