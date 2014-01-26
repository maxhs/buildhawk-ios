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

#import <SDWebImage/UIButton+WebCache.h>
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
    NSMutableArray *dateArray;
    NSMutableArray *sourceArray;
    NSMutableArray *documentsArray;
    NSMutableArray *checklistArray;
    NSMutableArray *worklistArray;
    NSMutableArray *reportsArray;
    NSMutableArray *browserPhotos;
    CGRect screen;
}

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad {
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
    if (!dateArray) dateArray = [NSMutableArray array];
    if (!sortedByUser) sortedByUser = [NSMutableArray array];
    if (!sourceArray) sourceArray = [NSMutableArray array];
    if (!checklistArray) checklistArray = [NSMutableArray array];
    if (!reportsArray) reportsArray = [NSMutableArray array];
    if (!worklistArray) worklistArray = [NSMutableArray array];
    if (!documentsArray) documentsArray = [NSMutableArray array];
    sortByDate = NO;
    sortByUser = NO;
    [Flurry logEvent:@"Viewing documents"];
    [self loadPhotos];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
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
        //NSLog(@"Success getting documents: %@",responseObject);
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
        } else if ([photo.source isEqualToString:kDocuments]){
            [documentsArray addObject:photo];
        }
        if (![sourceArray containsObject:photo.source]) [sourceArray addObject:photo.source];
        if (photo.userName && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];

        [photos addObject:photo];
    }
    return photos;
}

- (void)removePhoto:(NSNotification*)notification {
    [photosArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kReports]){
        if (reportsArray.count) [reportsArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    } else if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kWorklist]){
        if (worklistArray.count) [worklistArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    } else if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kDocuments]){
        if (documentsArray.count) [documentsArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    } else if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kChecklist]){
        if (checklistArray.count) [checklistArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    }
    
    [self.tableView reloadData];
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
    cell.userInteractionEnabled = YES;
    if (iPad) [cell.label setFont:[UIFont systemFontOfSize:18]];
    NSURL *imageUrl;
    switch (indexPath.row) {
        case 0:
            if (photosArray.count == 1) {
                [cell.label setText:@"All - 1 Item"];
            } else if (photosArray.count == 0) {
                [cell.label setText:@"All - No items"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.label setText:[NSString stringWithFormat:@"All - %i Items",photosArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)photosArray.lastObject urlLarge]];
            } else {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)photosArray.lastObject url200]];
            }
            break;
        case 1:
            if (documentsArray.count == 1) {
                [cell.label setText:@"Documents - 1 Item"];
            } else if (documentsArray.count == 0) {
                [cell.label setText:@"Documents - No items"];
                cell.userInteractionEnabled = NO;
            } else {
                [cell.label setText:[NSString stringWithFormat:@"Documents - %i Items",documentsArray.count]];
            }
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)documentsArray.lastObject urlLarge]];
            } else {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)documentsArray.lastObject url200]];
            }
            break;
        case 2:
            if (checklistArray.count == 1) {
                [cell.label setText:@"Checklist - 1 Item"];
            } else if (checklistArray.count == 0) {
                [cell.label setText:@"Checklist - No items"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.label setText:[NSString stringWithFormat:@"Checklist - %i Items",checklistArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)checklistArray.lastObject urlLarge]];
            } else {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)checklistArray.lastObject url200]];
            }
            break;
        case 3:
            if (worklistArray.count == 1) {
                [cell.label setText:@"Worklist - 1 Item"];
            } else if (worklistArray.count == 0) {
                [cell.label setText:@"Worklist - No items"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.label setText:[NSString stringWithFormat:@"Worklist - %i Items",worklistArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)worklistArray.lastObject urlLarge]];
            } else {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)worklistArray.lastObject url200]];
            }
            break;
        case 4:
            if (reportsArray.count == 1) {
                [cell.label setText:@"Reports - 1 Item"];
            } else if (reportsArray.count == 0) {
                [cell.label setText:@"Reports - No items"];
                cell.userInteractionEnabled = NO;
            } else [cell.label setText:[NSString stringWithFormat:@"Reports - %i Items",reportsArray.count]];
            
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)reportsArray.lastObject urlLarge]];
            } else {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)reportsArray.lastObject url200]];
            }
            break;
        default:
            break;
    }
    if (imageUrl) {
        cell.label.transform = CGAffineTransformIdentity;
        [cell.photoButton setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [cell.photoButton setTag:0];
            cell.photoButton.userInteractionEnabled = NO;
            //[cell.photoButton addTarget:self action:@selector(showPhotos) forControlEvents:UIControlEventTouchUpInside];
            [UIView animateWithDuration:.25 animations:^{
                [cell.photoButton setAlpha:1.0];
                [cell.label setAlpha:1.0];
            }];
        }];
    } else if (photosArray.count) {
        cell.label.transform = CGAffineTransformMakeTranslation(-80, 0);
        [UIView animateWithDuration:.25 animations:^{
            [cell.label setAlpha:1.0];
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
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
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (iPad) return (screen.size.height-64-52)/5;
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
    if (dateArray.count) [dateArray removeAllObjects];
    
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
                if (photo.folder)[titleSet addObject:photo.folder];
                if (photo.createdDate && ![dateArray containsObject:photo.createdDate]) [dateArray addObject:photo.createdDate];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setDocumentsBool:YES];
            [vc setPhotosArray:documentsArray];
        }
            break;
        case 2:
        {
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in checklistArray){
                if (photo.phase)[titleSet addObject:photo.phase];
                if (photo.createdDate && ![dateArray containsObject:photo.createdDate]) [dateArray addObject:photo.createdDate];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:checklistArray];
            [vc setChecklistsBool:YES];
        }
            break;
        case 3:
        {
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in worklistArray){
                if (photo.assignee)[titleSet addObject:photo.assignee];
                if (photo.createdDate && ![dateArray containsObject:photo.createdDate]) [dateArray addObject:photo.createdDate];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:worklistArray];
            [vc setWorklistsBool:YES];
        }
            break;
        case 4:
        {
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in reportsArray){
                if (photo.createdDate)[titleSet addObject:photo.createdDate];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:reportsArray];
            [vc setReportsBool:YES];
        }
            break;

        default:
            break;
    }
    [vc setUserNames:userArray];
    [vc setDates:dateArray];
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:CGRectMake(0, screen.size.height-64, screen.size.width, 49)];
        self.tabBarController.tabBar.alpha = 0.0;
    }];
}

@end
