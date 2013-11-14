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
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import "Flurry.h"

@interface BHDashboardDetailViewController () <UIScrollViewDelegate> {
    NSMutableArray *notifications;
    NSMutableArray *recentChecklistItems;
    NSMutableArray *upcomingChecklistItems;
    NSMutableArray *recentlyCompletedWorklistItems;
    NSMutableArray *recentDocuments;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *pendingCategories;
    NSMutableArray *completedCategories;
    UIScrollView *documentsScrollView;
    BOOL iPad;
}

@end

@implementation BHDashboardDetailViewController

@synthesize project;

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
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.title = self.project.name;
    //setup goToProject button
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 66)];
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
    if (!recentChecklistItems) recentChecklistItems = [NSMutableArray array];
    if (!recentDocuments) recentDocuments = [NSMutableArray array];
    if (!recentlyCompletedWorklistItems) recentlyCompletedWorklistItems = [NSMutableArray array];
    if (!notifications) notifications = [NSMutableArray array];
    if (!upcomingChecklistItems) upcomingChecklistItems = [NSMutableArray array];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    }
    [self loadDashboard];
    [Flurry logEvent:[NSString stringWithFormat: @"Viewing dashboard for %@",self.project.name]];
}

- (void)loadDashboard {
    [manager GET:[NSString stringWithFormat:@"%@/dash",kApiBaseUrl] parameters:@{@"pid":self.project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting dashboard: %@",responseObject);
        recentChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"cl_changed"]];
        upcomingChecklistItems = [BHUtilities checklistItemsFromJSONArray:[responseObject objectForKey:@"cl_due_soon"]];
        recentDocuments = [BHUtilities photosFromJSONArray:[responseObject objectForKey:@"recent_docs"]];
        recentlyCompletedWorklistItems = [BHUtilities punchlistItemsFromJSONArray:[responseObject objectForKey:@"wl_completed"]];
        pendingCategories = [responseObject objectForKey:@"cl_pending"];
        completedCategories = [responseObject objectForKey:@"cl_completed"];
        NSLog(@"pending %@ and completed %@",pendingCategories, completedCategories);
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
            return upcomingChecklistItems.count;
            break;
        case 2:
            return recentChecklistItems.count;
            break;
        case 3:
            if (recentDocuments.count > 0) return 1;
            else return 0;
            break;
        case 4:
            return 1;
            break;
        default:
            return 1;
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
        }
            break;
        case 1: {
            static NSString *CellIdentifier = @"UpcomingItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            BHChecklistItem *checklistItem = [upcomingChecklistItems objectAtIndex:indexPath.row];
            [cell.textLabel setText:checklistItem.name];
            if (checklistItem.dueDateString.length) {
                [cell.detailTextLabel setText:[NSString stringWithFormat:@"Deadline: %@",checklistItem.dueDateString]];
                [cell.detailTextLabel setTextColor:[UIColor darkGrayColor]];
            }
            else {
                [cell.detailTextLabel setText:@"No critical date listed"];
                [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            }
        }
        break;
        case 2: {
            static NSString *CellIdentifier = @"RecentItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            BHChecklistItem *checklistItem = [recentChecklistItems objectAtIndex:indexPath.row];
            [cell.textLabel setText:checklistItem.name];
        }
            break;
        case 3: {
            BHRecentDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentPhotosCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHRecentDocumentCell" owner:self options:nil] lastObject];
            }
            if (!documentsScrollView) {
                documentsScrollView = [[UIScrollView alloc] initWithFrame:cell.frame];
                [cell addSubview:documentsScrollView];
            }
            [self showDocuments];
            //have to return this cell on its own because it's not a UITableViewCell like the rest
            return cell;
        }
            break;
        case 4: {
            static NSString *CellIdentifier = @"ProgressCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            [cell.textLabel setText:@"Progress number 1"];
        }
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) return 110;
    else return 66;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView* headerView;
    if (section == 3 && recentDocuments.count == 0) {
        return nil;
    } else if (section == 2 && recentChecklistItems.count == 0) {
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
            [headerLabel setText:@"Synopsis"];
            break;
        case 1:
            [headerLabel setText:@"Upcoming Critical Items"];
            break;
        case 2:
            [headerLabel setText:@"Recent Checklist Items"];
            break;
        case 3:
            [headerLabel setText:@"Recent Documents"];
            break;
        case 4:
            [headerLabel setText:@"Progress"];
            break;
        default:
            return nil;
            break;
    }
        
    // Return the headerView
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
        [eventButton addTarget:self action:@selector(showPhotoDetail) forControlEvents:UIControlEventTouchUpInside];
        [eventButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        index++;
    }
    [documentsScrollView setContentSize:CGSizeMake((recentDocuments.count*105) + 5,documentsScrollView.frame.size.height)];
    documentsScrollView.layer.shouldRasterize = YES;
    documentsScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)showPhotoDetail {
    NSMutableArray *photos = [NSMutableArray new];
    
    for (BHPhoto *photo in recentDocuments) {
        IDMPhoto *idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        [photos addObject:idmPhoto];
    }
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    [self presentViewController:browser animated:YES completion:^{
        
    }];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
