//
//  BHPunchlistViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistViewController.h"
#import "BHPunchlistItemCell.h"
#import "BHPunchlistItemViewController.h"
#import "BHPunchlistItem.h"
#import "BHPunchlist.h"
#import "BHPhoto.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"
#import "Flurry.h"

@interface BHPunchlistViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *listItems;
    NSDateFormatter *dateFormatter;
    AFHTTPRequestOperationManager *manager;
    BHProject *project;
}
- (IBAction)backToDashboard;
@end

@implementation BHPunchlistViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    project =[(BHTabBarViewController*)self.tabBarController project];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Worklists",project.name];
    self.tableView.tableHeaderView = self.segmentContainerView;
    if (!listItems) listItems = [NSMutableArray array];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [self.segmentedControl setTintColor:kDarkGrayColor];
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    [Flurry logEvent:@"Viewing punchlist"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD showWithStatus:@"Fetching worklists..."];
    [self loadPunchlist];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPunchlist {
    [manager GET:[NSString stringWithFormat:@"%@/punchlists", kApiBaseUrl] parameters:@{@"pid":project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success loading punchlist: %@",responseObject);
        listItems = [BHUtilities punchlistItemsFromJSONArray:[responseObject objectForKey:@"rows"]];
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading worklists: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while loading your worklist. Please try again soon" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return listItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PunchlistItemCell";
    BHPunchlistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPunchlistItemCell" owner:self options:nil] lastObject];
    }
    
    BHPunchlistItem *item = [listItems objectAtIndex:indexPath.row];
    [cell.itemLabel setText:item.name];
    if (item.completedPhotos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.completedPhotos firstObject] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else if (item.createdPhotos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.createdPhotos firstObject] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
    }
    cell.photoButton.imageView.layer.cornerRadius = 3.0;
    [cell.photoButton.imageView setBackgroundColor:[UIColor clearColor]];
    [cell.photoButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
    cell.photoButton.imageView.layer.shouldRasterize = YES;
    cell.photoButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.photoButton.clipsToBounds = YES;
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
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
    [self performSegueWithIdentifier:@"PunchlistItem" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setTitle:@"Create Punchlist Item"];
        [vc setNewItem:YES];
        [vc setPunchlistItem:[NSEntityDescription insertNewObjectForEntityForName:@"PunchlistItem" inManagedObjectContext:self.managedObjectContext]];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setNewItem:NO];
        BHPunchlistItem *item = [listItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        [vc setTitle:[NSString stringWithFormat:@"%@",item.createdOn]];
        [vc setPunchlistItem:item];
        [vc setProject:project];
    }
        
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
