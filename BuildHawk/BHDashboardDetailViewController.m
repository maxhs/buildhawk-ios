//
//  BHDashboardDetailViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDashboardDetailViewController.h"
#import "Constants.h"
#import "BHTabBarViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHChecklistItem.h"
#import "BHPhoto.h"
#import "BHUser.h"
#import "BHPunchlistItem.h"
#import "BHRecentDocumentCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import "BHChecklistViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHPunchlistItemViewController.h"
#import "BHProgressCell.h"
#import <LDProgressView/LDProgressView.h>

@interface BHDashboardDetailViewController () <UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    AFHTTPRequestOperationManager *manager;
    UIScrollView *documentsScrollView;
    BOOL iPad;
    CGRect screen;
    NSMutableArray *browserPhotos;
}

@end

@implementation BHDashboardDetailViewController

@synthesize project, categories, recentChecklistItems, recentDocuments, recentlyCompletedWorklistItems, notifications, upcomingChecklistItems;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    }
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.title = self.project.name;
    screen = [UIScreen mainScreen].bounds;
    //setup goToProject button
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 66)];
    [footerView setBackgroundColor:kDarkGrayColor];
    UIButton *goToProjectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goToProjectButton setTitle:@"Go to Project" forState:UIControlStateNormal];
    [goToProjectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [goToProjectButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
    [goToProjectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:goToProjectButton];
    [goToProjectButton setFrame:footerView.frame];
    self.tableView.tableFooterView = footerView;
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    
    //[self loadDashboard];
    [Flurry logEvent:[NSString stringWithFormat: @"Viewing dashboard for %@",self.project.name]];
}

- (void)loadDashboard {
    [manager GET:[NSString stringWithFormat:@"%@/projects/dash",kApiBaseUrl] parameters:@{@"id":self.project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        recentChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"recently_completed"]];
        upcomingChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"cl_due_soon"]];
        recentDocuments = [BHUtilities photosFromJSONArray:[responseObject objectForKey:@"recent_documents"]];
        recentlyCompletedWorklistItems = [BHUtilities punchlistItemsFromJSONArray:[responseObject objectForKey:@"recently_completed"]];
        categories = [responseObject objectForKey:@"cl_categories"];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure getting dashboard: %@",error.description);
    }];
}

- (void)goToProject:(UIButton*)button {
    [self performSegueWithIdentifier:@"Project" sender:button];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:self.project];
    } else if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        BHChecklistItemViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[BHChecklistItem class]])
            [vc setItem:(BHChecklistItem*)sender];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[BHPunchlistItem class]])
            [vc setPunchlistItem:(BHPunchlistItem*)sender];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return categories.count;
            break;
        case 2:
            if (recentDocuments.count > 0) return 1;
            else return 0;
            break;
        case 3:
            return upcomingChecklistItems.count;
            break;
        case 4:
        {
            return recentChecklistItems.count;
        }
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0: {
            static NSString *CellIdentifier = @"SynopsisCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            [cell.textLabel setText:self.project.address.formattedAddress];
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"Number of personnel: %i",self.project.users.count]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
            break;
        case 1: {
            BHProgressCell *progressCell = [tableView dequeueReusableCellWithIdentifier:@"ProgressCell"];
            [progressCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            progressCell = [[[NSBundle mainBundle] loadNibNamed:@"BHProgressCell" owner:self options:nil] lastObject];
            
            NSDictionary *dict = [categories objectAtIndex:indexPath.row];
            [progressCell.itemLabel setText:[dict objectForKey:@"name"]];
            CGFloat completed = [[dict objectForKey:@"completed_count"] floatValue];
            CGFloat all = [[dict objectForKey:@"item_count"] floatValue];
            [progressCell.progressLabel setText:[NSString stringWithFormat:@"%.1f%%",(100*completed/all)]];
            LDProgressView *progressView;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                progressView = [[LDProgressView alloc] initWithFrame:CGRectMake(415, 25, 300, 16)];
                progressCell.progressLabel.transform = CGAffineTransformMakeTranslation(140, 0);
            } else {
                progressView = [[LDProgressView alloc] initWithFrame:CGRectMake(215, 25, 100, 16)];
            }
            progressView.progress = (completed/all);
            progressView.color = kBlueColor;
            progressView.showText = @NO;
            progressView.type = LDProgressSolid;
            [progressCell addSubview:progressView];
            
            progressCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return progressCell;
            
        }
        break;
        case 2: {
            BHRecentDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentPhotosCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHRecentDocumentCell" owner:self options:nil] lastObject];
            }
            CGRect frame = cell.frame;
            frame.size.width = screen.size.width;
            [cell setFrame:frame];
            if (!documentsScrollView) {
                documentsScrollView = [[UIScrollView alloc] initWithFrame:cell.frame];
                [cell addSubview:documentsScrollView];
            }
            [self showDocuments];
            //have to return this cell on its own because it's not a UITableViewCell like the rest
            return cell;
        }
            break;
        case 3: {
            static NSString *CellIdentifier = @"UpcomingItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            BHChecklistItem *checklistItem = [upcomingChecklistItems objectAtIndex:indexPath.row];
            [cell.textLabel setText:checklistItem.body];
            if (checklistItem.dueDateString.length) {
                [cell.detailTextLabel setText:[NSString stringWithFormat:@"Deadline: %@",checklistItem.dueDateString]];
                [cell.detailTextLabel setTextColor:[UIColor darkGrayColor]];
            }
            else {
                [cell.detailTextLabel setText:@"No critical date listed"];
                [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            }
            if ([[checklistItem type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
            } else if ([[checklistItem type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
            }
        }
            break;
        case 4: {
            static NSString *CellIdentifier = @"RecentItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            BHChecklistItem *checklistItem = [recentChecklistItems objectAtIndex:indexPath.row];
            [cell.textLabel setText:checklistItem.body];
            if ([[checklistItem type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
            } else if ([[checklistItem type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
            }
        }
        default:
            break;
    }
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:16]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) return 110;
    else return 66;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 2:
            if (recentDocuments.count){
                return 30;
            } else {
                return 0;
            }
            break;
        case 3:
            if (upcomingChecklistItems.count){
                return 30;
            } else {
                return 0;
            }
            break;
        case 4:
            if (recentChecklistItems.count){
                return 30;
            } else {
                return 0;
            }
            break;
        default:
            return 30;
            break;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView* headerView;
    if (section == 2 && recentDocuments.count == 0) {
        return nil;
    } else if (section == 4 && recentChecklistItems.count == 0) {
        return nil;
    } else if (section == 3 && upcomingChecklistItems.count == 0) {
        return nil;
    } else {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, 54.0)];
    }
    
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    // Add the label
    UILabel *headerLabel;
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, screenRect.size.width, 30.0)];
    headerLabel.backgroundColor = kLighterGrayColor;
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.font = [UIFont fontWithName:kHelveticaNeueLight size:16];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:headerLabel];
    
    switch (section) {
        case 0:
            [headerLabel setText:@"Project Synopsis"];
            break;
        case 1:
            [headerLabel setText:@"Progress"];
            break;
        case 2:
            [headerLabel setText:@"Recent Documents"];
            break;
        case 3:
            [headerLabel setText:@"Upcoming Critical Items"];
            break;
        case 4:
            [headerLabel setText:@"Recent Checklist Items"];
            break;
        default:
            return nil;
            break;
    }
    return headerView;
}

#pragma mark - Display events

- (void)showDocuments {
    [documentsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    documentsScrollView.showsHorizontalScrollIndicator = NO;
    documentsScrollView.pagingEnabled = YES;
    documentsScrollView.delegate = self;
    int index = 0;
    int width = 105;
    CGRect photoRect = CGRectMake(5,5,100,100);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    for (BHPhoto *photo in recentDocuments) {
        if (index > 0) photoRect.origin.x += width;
        __weak UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [documentsScrollView addSubview:eventButton];
        [eventButton setFrame:photoRect];
        [eventButton setTag:index];
        if (photo.url200) [eventButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal];
        else if (photo.url100) [eventButton setImageWithURL:[NSURL URLWithString:photo.url100] forState:UIControlStateNormal];
        [eventButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        eventButton.imageView.clipsToBounds = YES;
        [eventButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        [eventButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        index++;
    }
    [documentsScrollView setContentSize:CGSizeMake((recentDocuments.count*105) + 5,documentsScrollView.frame.size.height)];
    documentsScrollView.layer.shouldRasterize = YES;
    documentsScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in recentDocuments) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setBhphoto:photo];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1){
        [self performSegueWithIdentifier:@"Project" sender:indexPath];
    } else if (indexPath.section == 3){
        BHChecklistItem *item = [upcomingChecklistItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    } else if (indexPath.section == 4){
        BHChecklistItem *item = [recentChecklistItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
