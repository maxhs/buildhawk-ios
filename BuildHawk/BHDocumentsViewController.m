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
#import "BHAppDelegate.h"
#import "BHUtilities.h"
#import "BHCollectionPhotoCell.h"
#import "MWPhotoBrowser.h"
#import "BHPhotosHeaderView.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MWPhotoBrowserDelegate> {
    BOOL iPad;
    BOOL loading;
    NSArray *sortedByDate;
    NSMutableArray *sortedByUser;
    BOOL sortByDate;
    BOOL sortByUser;
    NSString *sortUser;
    UIActionSheet *categoryActionSheet;
    UIActionSheet *userActionSheet;
    NSMutableArray *photosArray;
    NSMutableArray *userArray;
    NSMutableArray *dateArray;
    NSMutableArray *sourceArray;
    NSMutableArray *folderArray;
    NSMutableArray *documentsArray;
    NSMutableArray *checklistArray;
    NSMutableArray *tasklistArray;
    NSMutableArray *reportsArray;
    NSMutableArray *browserPhotos;
    CGRect screen;
    UIRefreshControl *refreshControl;
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat height;
    CGFloat width;
    CGFloat rowHeight;
    
    BOOL showChecklistPhotos;
    BOOL showTaskPhotos;
    BOOL showReportPhotos;
    BOOL showFolderPhotos;
    NSMutableArray *sectionArray;
    NSMutableArray *compositePhotos;
    NSMutableArray *browserArray; // for Photo objects
    UIActionSheet *sortSheet;
}
@property (strong, nonatomic) Project *project;
@end

@implementation BHDocumentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.project = [[(BHTabBarViewController*)self.tabBarController project] MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.tabBarController.navigationController.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",self.project.name];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }

    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = [delegate manager];
    screen = [UIScreen mainScreen].bounds;
    photosArray = [NSMutableArray array];
    folderArray = [NSMutableArray array];
    userArray = [NSMutableArray array];
    dateArray = [NSMutableArray array];
    sortedByUser = [NSMutableArray array];
    sourceArray = [NSMutableArray array];
    browserArray = [NSMutableArray array];
    browserPhotos = [NSMutableArray array];

    rowHeight = (height - self.navigationController.navigationBar.frame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.tabBarController.tabBar.frame.size.height)/5;
    self.tableView.rowHeight = rowHeight;
    self.splitTableView.rowHeight = 66.f;
    
    sortByDate = NO;
    sortByUser = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor blackColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    if (IDIOM == IPAD){
        [self.splitTableView addSubview:refreshControl];
    } else {
        [self.tableView addSubview:refreshControl];
    }
    if (self.project.documents.count > 0) [self drawDocuments:self.project.documents];
}

- (void)handleRefresh {
    if (delegate.connected){
        [ProgressHUD show:@"Refreshing..."];
        [self loadPhotos];
    } else {
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    if (!loading) {
        [self drawDocuments:self.project.documents];
    }
    if (delegate.connected && !self.project.documents.count){
        [self loadPhotos];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CGRect tabFrame = self.tabBarController.tabBar.frame;
    tabFrame.origin.y = height-tabFrame.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - (delegate.connected ? 0 : kOfflineStatusHeight);
    [UIView animateWithDuration:.25 animations:^{
        [self.tabBarController.tabBar setFrame:tabFrame];
    }];
}

- (void)loadPhotos {
    if (delegate.connected){
        [ProgressHUD show:@"Fetching documents..."];
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,self.project.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting %i documents: %@",photosArray.count,responseObject);
            [self.project parseDocuments:[responseObject objectForKey:@"photos"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self drawDocuments:self.project.documents];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting photos: %@",error.description);
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            loading = NO;
            [ProgressHUD dismiss];
        }];
    }
}

- (void)drawDocuments:(NSOrderedSet*)set {
    photosArray = set.array.mutableCopy;
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
    
    for (Photo *photo in set) {
        if ([photo.source isEqualToString:kChecklist]) {
            [checklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kTasklist] || [photo.source isEqualToString:kTask]) {
            [tasklistArray addObject:photo];
        } else if ([photo.source isEqualToString:kReports]){
            [reportsArray addObject:photo];
        } else if ([photo.source isEqualToString:kDocuments]){
            [documentsArray addObject:photo];
        }
        if (photo.source.length && ![sourceArray containsObject:photo.source]) [sourceArray addObject:photo.source];
        if (photo.userName.length && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];
    }
    
    [self.tableView reloadData];
    if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    loading = NO;
    [ProgressHUD dismiss];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.splitTableView){
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.splitTableView){
        if (section == 0){
            return self.project.folders.count;
        } else {
            return 4;
        }
    } else {
        return 5;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.splitTableView){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Folder"];
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
        [cell.detailTextLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
        if (indexPath.section == 0){
            Folder *folder = self.project.folders[indexPath.row];
            [cell.textLabel setText:folder.name];
            if (folder.photos.count == 1) {
                [cell.detailTextLabel setText:@"1 Item"];
            } else if (folder.photos.count == 0) {
                [cell.detailTextLabel setText:@"No documents"];
                cell.userInteractionEnabled = NO;
            } else {
                [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)
                                               folder.photos.count]];
            }
        } else {
            switch (indexPath.row) {
                case 0:
                    [cell.textLabel setText:@"All"];
                    if (photosArray.count == 1) {
                        [cell.detailTextLabel setText:@"1 Item"];
                    } else if (photosArray.count == 0) {
                        [cell.detailTextLabel setText:@"No documents"];
                        cell.userInteractionEnabled = NO;
                    } else {
                        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)
                                                   photosArray.count]];
                    }
                    break;
                case 1:
                    [cell.textLabel setText:@"Checklist Pictures"];
                    if (checklistArray.count == 1) {
                        [cell.detailTextLabel setText:@"1 Item"];
                    } else if (checklistArray.count == 0) {
                        [cell.detailTextLabel setText:@"No documents"];
                        cell.userInteractionEnabled = NO;
                    } else {
                        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)checklistArray.count]];
                    }
                    break;
                case 2:
                    [cell.textLabel setText:@"Task Pictures"];
                    if (tasklistArray.count == 1) {
                        [cell.detailTextLabel setText:@"1 Item"];
                    } else if (tasklistArray.count == 0) {
                        [cell.detailTextLabel setText:@"No documents"];
                        cell.userInteractionEnabled = NO;
                    } else {
                        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)tasklistArray.count]];
                    }
                    break;
                case 3:
                    [cell.textLabel setText:@"Report Pictures"];
                    if (reportsArray.count == 1) {
                        [cell.detailTextLabel setText:@"1 Item"];
                    } else if (reportsArray.count == 0) {
                        [cell.detailTextLabel setText:@"No documents"];
                        cell.userInteractionEnabled = NO;
                    } else [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu Items",(unsigned long)reportsArray.count]];
                    break;
                    
                default:
                    break;
            }
        }
        return cell;
    } else {
        static NSString *CellIdentifier = @"PhotoPickerCell";
        BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
        }
        cell.backgroundColor = [UIColor whiteColor];
        cell.userInteractionEnabled = YES;
        
        CGRect photoFrame = cell.photoButton.frame;
        photoFrame.origin.y = 4;
        photoFrame.origin.x = 4;
        photoFrame.size.width = rowHeight - 8;
        photoFrame.size.height = rowHeight - 8;
        [cell.photoButton setFrame:photoFrame];
        
        CGRect bucketLabelFrame = cell.bucketLabel.frame;
        bucketLabelFrame.origin.x = cell.photoButton.frame.size.width + 14.f;
        [cell.bucketLabel setFrame:bucketLabelFrame];
        
        CGRect countLabelFrame = cell.countLabel.frame;
        countLabelFrame.origin.x = cell.photoButton.frame.size.width + 14.f;
        [cell.countLabel setFrame:countLabelFrame];
        
        if (IDIOM == IPAD){
            [cell.bucketLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMyriadProLight] size:0]];
        } else {
            [cell.bucketLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProLight] size:0]];
        }
        [cell.countLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProLight] size:0]];
        
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
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && tableView == self.tableView){
        //end of loading
        
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.splitTableView){
        if (indexPath.section == 0){
            Folder *folder = self.project.folders[indexPath.row];
            NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"folder.name like %@",folder.name];
            NSMutableArray *tempArray = [NSMutableArray array];
            for (Photo *photo in photosArray){
                if([photo isKindOfClass:[Photo class]] && [testPredicate evaluateWithObject:photo]) {
                    [tempArray addObject:photo];
                }
            }
            [self resetCollectionPhotos];
            showFolderPhotos = YES;
            folderArray = tempArray;
            [self.tabBarController.navigationItem setTitle:folder.name];
            [self.photosCollectionView reloadData];
        } else {
            switch (indexPath.row) {
                case 0:
                    self.tabBarController.navigationItem.title = self.project.name;
                    [self resetCollectionPhotos];
                    break;
                case 1:
                    [self resetCollectionPhotos];
                    self.tabBarController.navigationItem.title = @"Checklist Files";
                    showChecklistPhotos = YES;
                    break;
                case 2:
                    [self resetCollectionPhotos];
                    self.tabBarController.navigationItem.title = @"Task Files";
                    showTaskPhotos = YES;
                    break;
                case 3:
                    [self resetCollectionPhotos];
                    self.tabBarController.navigationItem.title = @"Report Files";
                    showReportPhotos = YES;
                    break;
                default:
                    break;
            }
            [self.photosCollectionView reloadData];
        }
    } else {
        if (indexPath.row == 1){
            [self performSegueWithIdentifier:@"Folders" sender:indexPath];
        } else {
            [self performSegueWithIdentifier:@"Photos" sender:indexPath];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)resetCollectionPhotos {
    showReportPhotos = NO;
    showTaskPhotos = NO;
    showChecklistPhotos = NO;
    showFolderPhotos = NO;
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
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (showChecklistPhotos){
        browserArray = checklistArray;
        return checklistArray.count;
    } else if (showTaskPhotos) {
        browserArray = tasklistArray;
        return tasklistArray.count;
    } else if (showReportPhotos) {
        browserArray = reportsArray;
        return reportsArray.count;
    } else if (showFolderPhotos) {
        browserArray = folderArray;
        return folderArray.count;
    } else {
        browserArray = photosArray.mutableCopy;
        return photosArray.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHCollectionPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo;
    if (sortByUser || sortByDate) {
        NSMutableArray *tempArray = [sectionArray objectAtIndex:indexPath.section];
        photo = [tempArray objectAtIndex:indexPath.row];
    } else if (showChecklistPhotos) {
        photo = [checklistArray objectAtIndex:indexPath.row];
    } else if (showTaskPhotos){
        photo = [tasklistArray objectAtIndex:indexPath.row];
    } else if (showReportPhotos){
        photo = [reportsArray objectAtIndex:indexPath.row];
    } else if (showFolderPhotos){
        photo = [folderArray objectAtIndex:indexPath.row];
    } else {
        photo = [photosArray objectAtIndex:indexPath.row];
    }
    [cell.photoButton setTag:[browserArray indexOfObject:photo]];
    [cell configureForPhoto:photo];
    [cell.photoButton addTarget:self action:@selector(showBrowser:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)showBrowser:(UIButton*)button {
    [browserPhotos removeAllObjects];
    for (Photo *photo in browserArray) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
        if (photo.caption.length) mwPhoto.caption = photo.caption;
    }
    
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
    [browser setProject:_project];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:button.tag];
    
 }

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

- (void)deletedPhoto:(Photo *)p {
    Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [photosArray removeObject:photo];
    [checklistArray removeObject:photo];
    [reportsArray removeObject:photo];
    [tasklistArray removeObject:photo];
    [checklistArray removeObject:photo];
    [self.photosCollectionView reloadData];
    [self.tableView reloadData];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        BHPhotosHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        NSString *title;
//        if (sortByUser){
//            title = [_userNames objectAtIndex:indexPath.section];
//        } else if (sortByDate){
//            title = [_dates objectAtIndex:indexPath.section];
//        } else {
//            title = [_sectionTitles objectAtIndex:indexPath.section];
//        }
        if ([title isKindOfClass:[NSString class]] && title.length){
            [headerView configureForTitle:title];
        }
        [headerView setBackgroundColor:[UIColor clearColor]];
        return headerView;
    } else {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        return footerView;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (sortByDate || sortByUser) return CGSizeMake(screen.size.width, 30);
    else return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(collectionView.frame.size.width/4,collectionView.frame.size.width/4);
    } else {
        return CGSizeMake(width/3,width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

@end
