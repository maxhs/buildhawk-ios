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
    NSMutableArray *photosArray;
    NSArray *sortedByDate;
    NSMutableArray *sortedByUser;
    BOOL sortByDate;
    BOOL sortByUser;
    BOOL sortByCategory;
    NSString *sortUser;
    NSString *sortCategory;
    UIActionSheet *categoryActionSheet;
    UIActionSheet *userActionSheet;
    NSMutableArray *userArray;
    NSMutableArray *sourceArray;
    NSMutableArray *browserPhotos;
}

-(IBAction)backToDashboard;

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[[(BHTabBarViewController*)self.tabBarController project] name]];

    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    if (!photosArray) photosArray = [NSMutableArray array];
    if (!userArray) userArray = [NSMutableArray array];
    if (!sourceArray) sourceArray = [NSMutableArray array];
    if (!sortedByUser) sortedByUser = [NSMutableArray array];
    [self loadPhotos];
    sortByCategory = NO;
    sortByDate = NO;
    sortByUser = NO;
    [Flurry logEvent:@"Viewing documents"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
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
        if (![sourceArray containsObject:photo.source]) [sourceArray addObject:photo.source];
        if (photo.userName && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];
        [photos addObject:photo];
    }
    return photos;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return sourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"PhotoPickerCell";
        BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
        }
        [cell.categoryButton addTarget:self action:@selector(sortByCategory) forControlEvents:UIControlEventTouchUpInside];
        [cell.dateButton addTarget:self action:@selector(sortByDate) forControlEvents:UIControlEventTouchUpInside];
        [cell.userButton addTarget:self action:@selector(sortByUser) forControlEvents:UIControlEventTouchUpInside];
        cell.backgroundColor = kDarkerGrayColor;
        if (photosArray.count > 0){
            int photoIdx = 0;
            [cell.mainImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[(BHPhoto*)[photosArray objectAtIndex:photoIdx] url200]]] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                [cell.mainImageView setImage:image];
                [cell.mainImageView setContentMode:UIViewContentModeScaleAspectFill];
                cell.mainImageView.clipsToBounds = YES;
                UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [imageButton setFrame:cell.mainImageView.frame];
                [imageButton setTag:photoIdx];
                [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
                [cell addSubview:imageButton];
                [UIView animateWithDuration:.25 animations:^{
                    [cell.mainImageView setAlpha:1.0];
                }];
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                
            }];
        }
        [self buttonTreatment:cell.categoryButton];
        [self buttonTreatment:cell.dateButton];
        [self buttonTreatment:cell.userButton];
        if (photosArray.count) {
            [cell.countLabel setText:[NSString stringWithFormat:@"%i documents",photosArray.count]];
            [cell.countLabel setAlpha:1.0];
        }
        else {
            [cell.countLabel setAlpha:0.0];
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DocumentFolder"];
        [cell.textLabel setText:[sourceArray objectAtIndex:indexPath.row]];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
        return cell;
    }
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in photosArray) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
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
    button.layer.cornerRadius = 3.f;
    [button setBackgroundColor:[UIColor clearColor]];
    [button.layer setBackgroundColor:[UIColor colorWithWhite:.96 alpha:1.0].CGColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = kDarkGrayColor.CGColor;
    button.layer.shadowOpacity =  .5;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button.titleLabel setTextColor:[UIColor darkGrayColor]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)return 200;
    else return 88;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) return [UIView new];
    else return nil;
}

- (void)sortByCategory {
    sortByDate = NO;
    sortByUser = NO;
    sortByCategory = YES;
    [self showPhoto];
}

- (void)sortByDate {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdOn" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    sortedByDate = [photosArray sortedArrayUsingDescriptors:sortDescriptors];
    sortByDate = YES;
    sortByUser = NO;
    sortByCategory = NO;
    [self showPhoto];
}

- (void)sortByUser {
    userActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by user" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *name in userArray) {
        [userActionSheet addButtonWithTitle:name];
    }
    userActionSheet.cancelButtonIndex = [userActionSheet addButtonWithTitle:@"Cancel"];
    [userActionSheet showFromTabBar:self.tabBarController.tabBar];
    sortByDate = NO;
    sortByCategory = NO;
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
            [self showPhoto];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1){
        [self performSegueWithIdentifier:@"ByLabel" sender:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPhoto {
    [self performSegueWithIdentifier:@"ByPhase" sender:self];
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BHPhotosViewController *vc = [segue destinationViewController];
    if ([[segue identifier] isEqualToString:@"ByLabel"]){
        if ([sender isKindOfClass:[NSIndexPath class]]){
            NSIndexPath *indexPath = (NSIndexPath*)sender;
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
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"phase" ascending:YES];
            NSArray * descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [photosArray sortedArrayUsingDescriptors:descriptors];
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in sortedArray){
                if (photo.phase)[titleSet addObject:photo.phase];
            }
            [vc setSectionTitles:[[[titleSet allObjects] reverseObjectEnumerator] allObjects]];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:photosArray];
            [vc setTitle:sortCategory];
        }
    }
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
