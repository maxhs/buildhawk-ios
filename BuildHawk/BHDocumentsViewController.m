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
#import "BHFoldersViewController.h"
#import "UIButton+WebCache.h"
#import "BHPhotosViewController.h"
#import "Flurry.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    BOOL loading;
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
    UIRefreshControl *refreshControl;
    AFHTTPRequestOperationManager *manager;
    Project *_project;
}

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad {
    _project = [(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[_project name]];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.875 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
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
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
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
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor whiteColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
}

- (void)handleRefresh:(id)sender {
    [self loadPhotos];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (IDIOM == IPAD){
        [UIView animateWithDuration:.25 animations:^{
            self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
            self.tabBarController.tabBar.alpha = 1.0;
        }];
    } else {
        [UIView animateWithDuration:.25 animations:^{
            self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
            self.tabBarController.tabBar.alpha = 1.0;
        }];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    [ProgressHUD show:@"Fetching documents..."];
    loading = YES;
    
    [manager GET:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        photosArray = [self photosFromJSONArray:[responseObject objectForKey:@"photos"]];
        //NSLog(@"Success getting %i documents: %@",photosArray.count,responseObject);
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        loading = NO;
        [self.tableView reloadData];
        if (photosArray.count == 0)[ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting photos: %@",error.description);
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        loading = NO;
        [ProgressHUD dismiss];
    }];
}

- (NSMutableArray *)photosFromJSONArray:(NSArray *) array {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:array.count];
    if (checklistArray.count) [checklistArray removeAllObjects];
    if (worklistArray.count) [worklistArray removeAllObjects];
    if (reportsArray.count) [reportsArray removeAllObjects];
    if (documentsArray.count) [documentsArray removeAllObjects];
    
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
        if (documentsArray.count) {
            [documentsArray removeObject:[notification.userInfo objectForKey:@"photo"]];
        }
    } else if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kChecklist]){
        if (checklistArray.count) [checklistArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    }
    [[SDImageCache sharedImageCache] clearMemory];
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
            } else if (photosArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)photosArray.lastObject url200]];
            } else {
                imageUrl = nil;
            }
            break;
        case 1:
            if (documentsArray.count == 1) {
                [cell.label setText:@"Project Docs - 1 Item"];
            } else if (documentsArray.count == 0) {
                [cell.label setText:@"Project Docs - No items"];
                cell.userInteractionEnabled = NO;
            } else {
                [cell.label setText:[NSString stringWithFormat:@"Project Docs - %i Items",documentsArray.count]];
            }
            if (iPad){
                imageUrl = [NSURL URLWithString:[(BHPhoto*)documentsArray.lastObject urlLarge]];
            } else if (documentsArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)documentsArray.lastObject url200]];
            } else {
                imageUrl = nil;
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
            } else if (checklistArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)checklistArray.lastObject url200]];
            } else {
                imageUrl = nil;
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
            } else if (worklistArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)worklistArray.lastObject url200]];
            } else {
                imageUrl = nil;
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
            } else if (reportsArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(BHPhoto*)reportsArray.lastObject url200]];
            } else {
                imageUrl = nil;
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
            [UIView animateWithDuration:.25 animations:^{
                [cell.photoButton setAlpha:1.0];
                [cell.label setAlpha:1.0];
            }];
        }];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_256"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:.25 animations:^{
            [cell.label setAlpha:1.0];
            [cell.photoButton setAlpha:1.0];
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        if (photosArray.count && !loading) [ProgressHUD dismiss];
    }
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
    if (indexPath.row == 1){
        [self performSegueWithIdentifier:@"Folders" sender:indexPath];
    } else {
        [self performSegueWithIdentifier:@"Photos" sender:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPhotos {
    [self performSegueWithIdentifier:@"Photos" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (dateArray.count) [dateArray removeAllObjects];
    
    NSIndexPath *indexPath = (NSIndexPath*)sender;
    switch (indexPath.row) {
        case 0:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
            for (BHPhoto *photo in photosArray){
                if (photo.createdDate && ![dateArray containsObject:photo.createdDate]) [dateArray addObject:photo.createdDate];
            }
            [vc setProject:_project];
            [vc setPhotosArray:photosArray];
            [vc setNumberOfSections:1];
            [vc setUserNames:userArray];
            [vc setDates:dateArray];
            [vc setTitle:@"All"];
        }
            break;
        case 1:
        {
            BHFoldersViewController *vc = [segue destinationViewController];
            [vc setTitle:@"Project Docs"];
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in documentsArray){
                if (photo.folder)[titleSet addObject:photo.folder];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *sortedArray = [titleSet sortedArrayUsingDescriptors:@[valueDescriptor]];
            NSMutableSet *photoSet = [NSMutableSet set];
            for (NSString *folder in sortedArray){
                NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"folder like %@",folder];
                NSMutableArray *tempArray = [NSMutableArray array];
                for (BHPhoto *photo in documentsArray){
                    if([photo isKindOfClass:[BHPhoto class]] && [testPredicate evaluateWithObject:photo]) {
                        [tempArray addObject:photo];
                    }
                }
                [photoSet addObject:@{folder:tempArray}];
            }
            [vc setPhotosArray:documentsArray];
            [vc setSectionTitles:sortedArray];
            [vc setPhotoSet:photoSet];
        }
            break;
        case 2:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
            NSMutableSet *titleSet = [NSMutableSet set];
            for (BHPhoto *photo in checklistArray){
                if (photo.phase)[titleSet addObject:photo.phase];
                if (photo.createdDate && ![dateArray containsObject:photo.createdDate]) [dateArray addObject:photo.createdDate];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray * sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setProject:_project];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:checklistArray];
            [vc setChecklistsBool:YES];
            [vc setUserNames:userArray];
            [vc setDates:dateArray];
            [vc setTitle:@"Checklist"];
        }
            break;
        case 3:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
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
            [vc setUserNames:userArray];
            [vc setDates:dateArray];
            [vc setProject:_project];
            [vc setTitle:@"Worklist"];
        }
            break;
        case 4:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
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
            [vc setUserNames:userArray];
            [vc setDates:dateArray];
            [vc setProject:_project];
            [vc setTitle:@"Reports"];
        }
            break;

        default:
            break;
    }
    
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, self.tabBarController.tabBar.frame.size.height);
        self.tabBarController.tabBar.alpha = 0.0;
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [manager.operationQueue cancelAllOperations];
    [ProgressHUD dismiss];
}

@end
