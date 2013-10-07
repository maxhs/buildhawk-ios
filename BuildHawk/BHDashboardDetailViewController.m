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

@interface BHDashboardDetailViewController () {
    NSMutableArray *notifications;
    NSMutableArray *recentItems;
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
    [footerView setBackgroundColor:kBlueColor];
    UIButton *goToProjectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goToProjectButton setTitle:@"Go to Project" forState:UIControlStateNormal];
    [goToProjectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [goToProjectButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
    [goToProjectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:goToProjectButton];
    [goToProjectButton setFrame:footerView.frame];
    self.tableView.tableFooterView = footerView;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0: {
            static NSString *CellIdentifier = @"NotificationCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            [cell.textLabel setText:@"Notification number 1"];
        }
        break;
        case 1: {
            static NSString *CellIdentifier = @"RecentItemCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            [cell.textLabel setText:@"Recent Item 1"];
        }
            break;
        case 2: {
            static NSString *CellIdentifier = @"DocumentCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            [cell.textLabel setText:@"Document number 1"];
        }
            break;
        case 3: {
            static NSString *CellIdentifier = @"ProgressCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            [cell.textLabel setText:@"Progress number 1"];
        }
        default:
            break;
    }
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Updates";
            break;
        case 1:
            return @"Recent Items";
            break;
        case 2:
            return @"Recent Documents";
            break;
        case 3:
            return @"Progress";
            break;
        default:
            return nil;
            break;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, 54.0)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    // Add the label
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 30.0)];
    headerLabel.backgroundColor = [UIColor colorWithWhite:.5 alpha:.10];
    headerLabel.textColor = [UIColor lightGrayColor];
    headerLabel.font = [UIFont fontWithName:kHelveticaNeueLight size:16];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    [headerView addSubview:headerLabel];
    
    switch (section) {
        case 0:
            [headerLabel setText:@"Notifications"];
            break;
        case 1:
            [headerLabel setText:@"Recent Checklist Items"];
            break;
        case 2:
            [headerLabel setText:@"Recent Documents"];
            break;
        case 3:
            [headerLabel setText:@"Progress"];
            break;
        default:
            return nil;
            break;
    }
        
    // Return the headerView
    return headerView;
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

@end
