//
//  BHDocumentsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDocumentsViewController.h"
#import "BHPhotoPickerCell.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHPhoto.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHPhotosViewController.h"
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "Flurry.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MWPhotoBrowserDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    NSMutableArray *photosArray;
    NSArray *sortedByDate;
    NSMutableArray *sortedByUser;
    BOOL sortByDate;
    BOOL sortByUser;
    NSString *sortUser;
    UIActionSheet *categoryActionSheet;
    UIActionSheet *userActionSheet;
    NSMutableArray *userArray;
    NSMutableArray *sourceArray;
    NSMutableArray *documentsArray;
    NSMutableArray *checklistArray;
    NSMutableArray *worklistArray;
    NSMutableArray *reportsArray;
    NSMutableArray *browserPhotos;
    CGRect screen;
}

-(IBAction)backToDashboard;

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad
{
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[[(BHTabBarViewController*)self.tabBarController project] name]];
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.tableView setBackgroundColor:kBackgroundBlack];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.2]];
    [self.tableView setScrollEnabled:NO];
    if ([BHUtilities isIPhone5]) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    if ([BHUtilities isIpad]) {
        iPad = YES;
    } else {
        iPad = NO;
    }
    screen = [UIScreen mainScreen].bounds;
    if (!photosArray) photosArray = [NSMutableArray array];
    if (!userArray) userArray = [NSMutableArray array];
    if (!sortedByUser) sortedByUser = [NSMutableArray array];
    if (!sourceArray) sourceArray = [NSMutableArray array];
    if (!checklistArray) checklistArray = [NSMutableArray array];
    if (!reportsArray) reportsArray = [NSMutableArray array];
    if (!worklistArray) worklistArray = [NSMutableArray array];
    if (!documentsArray) documentsArray = [NSMutableArray array];
    [self loadPhotos];
    sortByDate = NO;
    sortByUser = NO;
    [Flurry logEvent:@"Viewing documents"];
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:CGRectMake(0, screen.size.height-113, screen.size.width, 49)];
        self.tabBarController.tabBar.alpha = 1.0;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    [SVProgressHUD showWithStatus:@"Fetching documents..."];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,[[(BHTabBarViewController*)self.tabBarController project] identifier]] parameters:@{@"id":[[(BHTabBarViewController*)self.tabBarController project] identifier]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting documents: %@",responseObject);
        
        photosArray = [self photosFromJSONArray:[responseObject objectForKey:@"photos"]];
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting photos: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (NSMutableArray *)photosFromJSONArray:(NSArray *) array {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *photoDictionary in array) {
        BHPhoto *photo = [[BHPhoto alloc] initWithDictionary:photoDictionary];
        if ([photo.source isEqualToString:kChecklist]) {
            [checklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kWorklist]) {
            [worklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kReports]){
            [reportsArray addObject:photo];
        } else if (![sourceArray containsObject:photo.source]) {
            [sourceArray addObject:photo.source];
            [documentsArray addObject:photo];
        }
        if (photo.userName && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];
        [photos addObject:photo];
    }
    return photos;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    static NSString *CellIdentifier = @"PhotoPickerCell";
    BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
    }

    cell.backgroundColor = kDarkerGrayColor;
    cell.textLabel.numberOfLines = 0;
    
    NSURL *imageUrl;
    switch (indexPath.row) {
        case 0:
            if (photosArray.count == 1) [cell.label setText:@"All - 1 Item"];
            else [cell.label setText:[NSString stringWithFormat:@"All - %i Items",photosArray.count]];
            imageUrl = [NSURL URLWithString:[(BHPhoto*)photosArray.lastObject url200]];
            break;
        case 1:
            if (documentsArray.count == 1) [cell.label setText:@"Documents - 1 Item"];
            else [cell.label setText:[NSString stringWithFormat:@"Documents - %i Items",documentsArray.count]];
            imageUrl = [NSURL URLWithString:[(BHPhoto*)documentsArray.lastObject url200]];
            break;
        case 2:
            if (checklistArray.count == 1) [cell.label setText:@"Checklist - 1 Item"];
            else [cell.label setText:[NSString stringWithFormat:@"Checklist - %i Items",checklistArray.count]];
            imageUrl = [NSURL URLWithString:[(BHPhoto*)checklistArray.lastObject url200]];
            break;
        case 3:
            if (worklistArray.count == 1) [cell.label setText:@"Worklist - 1 Item"];
            else [cell.label setText:[NSString stringWithFormat:@"Worklist - %i Items",worklistArray.count]];
            imageUrl = [NSURL URLWithString:[(BHPhoto*)worklistArray.lastObject url200]];
            break;
        case 4:
            if (reportsArray.count == 1) [cell.label setText:@"Reports - 1 Item"];
            else [cell.label setText:[NSString stringWithFormat:@"Reports - %i Items",reportsArray.count]];
            imageUrl = [NSURL URLWithString:[(BHPhoto*)reportsArray.lastObject url200]];
            break;
        default:
            break;
    }
    
    [cell.mainImageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageUrl] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [cell.mainImageView setImage:image];
        [cell.mainImageView setContentMode:UIViewContentModeScaleAspectFill];
        cell.mainImageView.clipsToBounds = YES;
        UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [imageButton setFrame:cell.mainImageView.frame];
        [imageButton setTag:0];
        [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:imageButton];
        [UIView animateWithDuration:.25 animations:^{
            [cell.mainImageView setAlpha:1.0];
        }];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in photosArray) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        mwPhoto.originalURL = [NSURL URLWithString:photo.orig];
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; // iOS 5 & 6 only: Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    }
    
    [browser setCurrentPhotoIndex:button.tag];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 4.f;
    [button setBackgroundColor:[UIColor clearColor]];
    [button.layer setBackgroundColor:[UIColor colorWithWhite:.1 alpha:1.0].CGColor];
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:.15].CGColor;
    button.layer.borderWidth = 0.5f;
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    /*button.layer.shadowColor = kDarkGrayColor.CGColor;
    button.layer.shadowOpacity =  .5;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);*/
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (iPad) return (screen.size.height-64-56)/5;
    else return (screen.size.height-64-49)/5;
}


- (void)sortByDate {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdOn" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    sortedByDate = [photosArray sortedArrayUsingDescriptors:sortDescriptors];
    sortByDate = YES;
    sortByUser = NO;
    [self showPhotos];
}

- (void)sortByUser {
    userActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by user" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *name in userArray) {
        [userActionSheet addButtonWithTitle:name];
    }
    userActionSheet.cancelButtonIndex = [userActionSheet addButtonWithTitle:@"Cancel"];
    [userActionSheet showFromTabBar:self.tabBarController.tabBar];
    sortByDate = NO;
    sortByUser = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == userActionSheet) {
        if (![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
            sortUser = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSPredicate *testForuser = [NSPredicate predicateWithFormat:@"userName contains[cd] %@",sortUser];
            [sortedByUser removeAllObjects];
            for (BHPhoto *photo in photosArray){
                if([testForuser evaluateWithObject:photo]) {
                    [sortedByUser addObject:photo];
                }
            }
            [self showPhotos];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Photos" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPhotos {
    [self performSegueWithIdentifier:@"Photos" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BHPhotosViewController *vc = [segue destinationViewController];
    NSIndexPath *indexPath = (NSIndexPath*)sender;
    switch (indexPath.row) {
        case 0:
            [vc setPhotosArray:photosArray];
            [vc setNumberOfSections:1];
            break;
        case 1:
        {
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in documentsArray){
                if (photo.source)[titleSet addObject:photo.source];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            NSLog(@"titleset count: %i %i",titleSet.count, documentsArray.count);
            [vc setPhotosArray:documentsArray];
        }
            break;
        case 2:
        {
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in checklistArray){
                if (photo.phase)[titleSet addObject:photo.phase];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:checklistArray];
        }
            break;
        case 3:
            [vc setPhotosArray:worklistArray];
            [vc setNumberOfSections:1];
            break;
        case 4:
            [vc setPhotosArray:reportsArray];
            [vc setNumberOfSections:1];
            break;
            
        default:
            break;
    }
    /*if ([[segue identifier] isEqualToString:@"ByLabel"]){
        if ([sender isKindOfClass:[NSIndexPath class]]){
            
            NSString *sourceLabel = [sourceArray objectAtIndex:indexPath.row];
            NSPredicate *testForSource = [NSPredicate predicateWithFormat:@"source like %@",sourceLabel];
            [sortedByUser removeAllObjects];
            NSMutableArray *tempArray = [NSMutableArray array];
            for (BHPhoto *photo in photosArray){
                if([testForSource evaluateWithObject:photo]) {
                    [tempArray addObject:photo];
                }
            }
            [vc setNumberOfSections:1];
            [vc setPhotosArray:tempArray];
            [vc setTitle:sourceLabel];
        }
    } else {
        if (sortByUser) {
            [vc setNumberOfSections:1];
            [vc setPhotosArray:sortedByUser];
            [vc setTitle:[NSString stringWithFormat:@"Taken by: %@",sortUser]];
        } else if (sortByDate) {
            [vc setNumberOfSections:1];
            [vc setPhotosArray:sortedByDate];
        } else if (sortByCategory) {
            
     
        }
    }*/
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:CGRectMake(0, screen.size.height-64, screen.size.width, 49)];
        self.tabBarController.tabBar.alpha = 0.0;
    }];
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
