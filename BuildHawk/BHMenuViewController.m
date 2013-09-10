//
//  BHMenuViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHMenuViewController.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

@interface BHMenuViewController ()
@property (strong, nonatomic) UISwitch *emailPermissionsSwitch;
@property (strong, nonatomic) UISwitch *pushPermissionsSwitch;

-(IBAction)logout;
@end

@implementation BHMenuViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:.15 alpha:1.0];
    self.tableView.backgroundColor = [UIColor colorWithWhite:.15 alpha:1.0];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:.2 alpha:1.0]];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        static NSString *CellIdentifier = @"UserCell";
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 29, cell.frame.size.width-80, cell.frame.size.height)];
        [nameLabel setText:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFullName]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
        [nameLabel setTextColor:[UIColor whiteColor]];
        CGRect textRect = cell.textLabel.frame;
        textRect.origin.x += 80;
        [cell.textLabel setFrame:textRect];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 25, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageView.layer.cornerRadius = 25.f;
        imageView.clipsToBounds = YES;
        [cell addSubview:imageView];
        [cell addSubview:nameLabel];
        [imageView setImageWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPhotoUrl100]]];
        
    } else if (indexPath.row == 1) {
        static NSString *CellIdentifier = @"PermissionsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!self.emailPermissionsSwitch) self.emailPermissionsSwitch = [[UISwitch alloc] init];
        cell.accessoryView = self.emailPermissionsSwitch;
        [cell.textLabel setText:@"Email permissions"];
    } else {
        static NSString *CellIdentifier = @"PermissionsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (!self.pushPermissionsSwitch) self.pushPermissionsSwitch = [[UISwitch alloc] init];
        cell.accessoryView = self.pushPermissionsSwitch;
        [cell.textLabel setText:@"Push permissions"];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 100;
    } else {
        return 80;
    }
}

- (IBAction)logout {
    NSLog(@"should be logging out");
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    NSLog(@"current navigation controller? %@",self.navigationController);
    [self dismissViewControllerAnimated:YES completion:^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        UIViewController *initialVC = [storyboard instantiateInitialViewController];
        [self presentViewController:initialVC animated:YES completion:nil];
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

@end
