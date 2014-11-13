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
#import "Photo+helper.h"
#import "Folder+helper.h"
#import "Project+helper.h"
#import "BHFoldersViewController.h"
#import "UIButton+WebCache.h"
#import "BHPhotosViewController.h"
#import "Flurry.h"
#import "BHAppDelegate.h"
#import "BHUtilities.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    BOOL loading;
    NSArray *photosArray;
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
    NSMutableArray *tasklistArray;
    NSMutableArray *reportsArray;
    NSMutableArray *browserPhotos;
    CGRect screen;
    UIRefreshControl *refreshControl;
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    Project *_project;
}

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad {
    _project = [(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[_project name]];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    if ([BHUtilities isIPhone5]) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    screen = [UIScreen mainScreen].bounds;
    photosArray = [NSMutableArray array];
    userArray = [NSMutableArray array];
    dateArray = [NSMutableArray array];
    sortedByUser = [NSMutableArray array];
    sourceArray = [NSMutableArray array];

    
    sortByDate = NO;
    sortByUser = NO;
    [Flurry logEvent:@"Viewing documents"];
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor blackColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    if (_project.documents.count > 0) [self drawDocuments:_project.documents];
    [self loadPhotos];
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadPhotos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    if (!loading) [self drawDocuments:_project.documents];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CGRect tabFrame = self.tabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight()-tabFrame.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - (delegate.connected ? 0 : kOfflineStatusHeight);
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:tabFrame];
        //self.tabBarController.tabBar.alpha = 1.0;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    if (delegate.connected){
        [ProgressHUD show:@"Fetching documents..."];
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,_project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting %i documents: %@",photosArray.count,responseObject);
            [_project parseDocuments:[responseObject objectForKey:@"photos"]];
            [self drawDocuments:_project.documents];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting photos: %@",error.description);
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            loading = NO;
            [ProgressHUD dismiss];
        }];
    }
}

- (void)drawDocuments:(NSOrderedSet*)set {
    photosArray = set.array;
    if (checklistArray) {
        [checklistArray removeAllObjects];
    } else {
        checklistArray = [NSMutableArray array];
    }
    if (tasklistArray) {
        [tasklistArray removeAllObjects];
    } else {
        tasklistArray = [NSMutableArray array];
    }
    if (reportsArray) {
        [reportsArray removeAllObjects];
    } else {
        reportsArray = [NSMutableArray array];
    }
    if (documentsArray) {
        [documentsArray removeAllObjects];
    } else {
        documentsArray = [NSMutableArray array];
    }
    
    for (Photo *photo in set.array) {
        if ([photo.source isEqualToString:kChecklist]) {
            [checklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kTasklist]) {
            [tasklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kReports]){
            [reportsArray addObject:photo];
        } else if ([photo.source isEqualToString:kDocuments]){
            [documentsArray addObject:photo];
        }
        if (photo.source.length && ![sourceArray containsObject:photo.source]) [sourceArray addObject:photo.source];
        if (photo.userName.length && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.tableView reloadData];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        loading = NO;
        [ProgressHUD dismiss];
    }];
}

- (void)removePhoto:(NSNotification*)notification {
    [_project removePhoto:[notification.userInfo objectForKey:@"photo"]];
    if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kReports]){
        if (reportsArray.count) [reportsArray removeObject:[notification.userInfo objectForKey:@"photo"]];
    } else if ([[notification.userInfo objectForKey:@"type"] isEqualToString:kTasklist]){
        if (tasklistArray.count) [tasklistArray removeObject:[notification.userInfo objectForKey:@"photo"]];
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

    cell.backgroundColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    
    if (IDIOM == IPAD){
        [cell.bucketLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
    } else {
        [cell.bucketLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
    }
    [cell.countLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredMyriadProFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
    
    NSURL *imageUrl;
    switch (indexPath.row) {
        case 0:
            [cell.bucketLabel setText:@"All"];
            if (photosArray.count == 1) {
                [cell.countLabel setText:@"1 Item"];
            } else if (photosArray.count == 0) {
                [cell.countLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.countLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)
                                           photosArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(Photo*)photosArray.lastObject urlLarge]];
            } else if (photosArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(Photo*)photosArray.lastObject urlSmall]];
            } else {
                imageUrl = nil;
            }
            break;
        case 1:
            [cell.bucketLabel setText:@"Project Docs"];
            if (documentsArray.count == 1) {
                [cell.countLabel setText:@"1 Item"];
            } else if (documentsArray.count == 0) {
                [cell.countLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            } else {
                [cell.countLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)documentsArray.count]];
            }
            if (iPad){
                imageUrl = [NSURL URLWithString:[(Photo*)documentsArray.lastObject urlLarge]];
            } else if (documentsArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(Photo*)documentsArray.lastObject urlSmall]];
            } else {
                imageUrl = nil;
            }
            break;
        case 2:
            [cell.bucketLabel setText:@"Checklist Pictures"];
            if (checklistArray.count == 1) {
                [cell.countLabel setText:@"1 Item"];
            } else if (checklistArray.count == 0) {
                [cell.countLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.countLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)checklistArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(Photo*)checklistArray.lastObject urlLarge]];
            } else if (checklistArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(Photo*)checklistArray.lastObject urlSmall]];
            } else {
                imageUrl = nil;
            }
            break;
        case 3:
            [cell.bucketLabel setText:@"Task Pictures"];
            if (tasklistArray.count == 1) {
                [cell.countLabel setText:@"1 Item"];
            } else if (tasklistArray.count == 0) {
                [cell.countLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            }
            else [cell.countLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)tasklistArray.count]];
            if (iPad){
                imageUrl = [NSURL URLWithString:[(Photo*)tasklistArray.lastObject urlLarge]];
            } else if (tasklistArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(Photo*)tasklistArray.lastObject urlSmall]];
            } else {
                imageUrl = nil;
            }
            break;
        case 4:
            [cell.bucketLabel setText:@"Report Pictures"];
            if (reportsArray.count == 1) {
                [cell.countLabel setText:@"1 Item"];
            } else if (reportsArray.count == 0) {
                [cell.countLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            } else [cell.countLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)reportsArray.count]];
            
            if (iPad){
                imageUrl = [NSURL URLWithString:[(Photo*)reportsArray.lastObject urlLarge]];
            } else if (reportsArray.count > 0) {
                imageUrl = [NSURL URLWithString:[(Photo*)reportsArray.lastObject urlSmall]];
            } else {
                imageUrl = nil;
            }
            break;
        default:
            break;
    }
    if (imageUrl) {
        cell.countLabel.transform = CGAffineTransformIdentity;
        cell.bucketLabel.transform = CGAffineTransformIdentity;
        [cell.photoButton sd_setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
            [cell.photoButton setTag:0];
            cell.photoButton.userInteractionEnabled = NO;
            [UIView animateWithDuration:.25 animations:^{
                [cell.photoButton setAlpha:1.0];
                [cell.countLabel setAlpha:1.0];
                [cell.bucketLabel setAlpha:1.0];
            }];
        }];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"whiteIcon"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:.25 animations:^{
            [cell.bucketLabel setAlpha:1.0];
            [cell.countLabel setAlpha:1.0];
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
            for (Photo *photo in photosArray){
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
    [super prepareForSegue:segue sender:sender];
    
    if (dateArray.count) [dateArray removeAllObjects];
    
    NSIndexPath *indexPath = (NSIndexPath*)sender;
    switch (indexPath.row) {
        case 0:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
            for (Photo *photo in photosArray){
                if (photo.dateString && ![dateArray containsObject:photo.dateString]) [dateArray addObject:photo.dateString];
            }
            [vc setProject:_project];
            [vc setPhotosArray:photosArray.mutableCopy];
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
            for (Photo *photo in _project.documents){
                if (photo.folder.name.length > 0)[titleSet addObject:photo.folder.name];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *sortedArray = [titleSet sortedArrayUsingDescriptors:@[valueDescriptor]];
            NSMutableSet *photoSet = [NSMutableSet set];
            for (NSString *folderName in sortedArray){
                NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"folder.name like %@",folderName];
                NSMutableArray *tempArray = [NSMutableArray array];
                for (Photo *photo in _project.documents){
                    if([photo isKindOfClass:[Photo class]] && [testPredicate evaluateWithObject:photo]) {
                        [tempArray addObject:photo];
                    }
                }
                [photoSet addObject:@{folderName:tempArray}];
            }
            [vc setPhotosArray:_project.documents.array.mutableCopy];
            [vc setSectionTitles:sortedArray];
            [vc setPhotoSet:photoSet];
        }
            break;
        case 2:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
            NSMutableSet *titleSet = [NSMutableSet set];
            for (Photo *photo in checklistArray){
                if (photo.photoPhase)[titleSet addObject:photo.photoPhase];
                if (photo.dateString && ![dateArray containsObject:photo.dateString]) [dateArray addObject:photo.dateString];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray *sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
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
            for (Photo *photo in tasklistArray){
                if (photo.userName.length)[titleSet addObject:photo.userName];
                if (photo.dateString.length && ![dateArray containsObject:photo.dateString]) [dateArray addObject:photo.dateString];
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray *sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
            [vc setSectionTitles:sortedArray];
            [vc setNumberOfSections:titleSet.count];
            [vc setPhotosArray:tasklistArray];
            [vc setTasklistsBool:YES];
            [vc setUserNames:userArray];
            [vc setDates:dateArray];
            [vc setProject:_project];
            [vc setTitle:@"Tasks"];
        }
            break;
        case 4:
        {
            BHPhotosViewController *vc = [segue destinationViewController];
            NSMutableSet *titleSet = [NSMutableSet set];
            for (Photo *photo in reportsArray){
                if (photo.dateString.length){
                    [titleSet addObject:photo.dateString];
                    if (![dateArray containsObject:photo.dateString]) [dateArray addObject:photo.dateString];
                }
            }
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:NO];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            NSArray *sortedArray = [titleSet sortedArrayUsingDescriptors:descriptors];
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
    
    CGRect tabFrame = self.tabBarController.tabBar.frame;
    tabFrame.origin.y = screenHeight();
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:tabFrame];
        //self.tabBarController.tabBar.alpha = 0.0;
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [ProgressHUD dismiss];
}

@end
