//
//  BHMenuViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/31/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHMenuViewController.h"
#import "Constants.h"
#import "BHLoginViewController.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "BHAppDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHUser.h"
#import "User.h"
#import <CoreData+MagicalRecord.h>
#import <MessageUI/MessageUI.h>

static NSString *callPlaceholder = @"Call";
static NSString *emailPlaceholder = @"Email";
static NSString *textPlaceholder = @"Text Message";

@interface BHMenuViewController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    BHUser *selectedCoworker;
    User *user;
    CGRect screen;
    BOOL iPhone5;
    BOOL iPad;
}
@property (strong, nonatomic) UISwitch *emailPermissionsSwitch;
@property (strong, nonatomic) UISwitch *pushPermissionsSwitch;

-(IBAction)logout;
@end

@implementation BHMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = kDarkGrayColor;
    self.tableView.backgroundColor = kDarkGrayColor;
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:.2 alpha:1.0]];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
    user = [User MR_findFirstWithPredicate:predicate inContext:localContext];
    //NSLog(@"user coworkers from menu? %@",user.coworkers);
    screen = [UIScreen mainScreen].bounds;
    [self.logoutButton setFrame:CGRectMake(0, screen.size.height-88, self.tableView.frame.size.width, 88)];
    [self.logoutButton setBackgroundColor:kDarkGrayColor];
    if (screen.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = NO;
    } else {
        iPad = YES;
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return [(NSArray*)user.coworkers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"UserCell";
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 32, cell.frame.size.width-80, cell.frame.size.height)];
        [nameLabel setText:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFullName]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setFont:[UIFont systemFontOfSize:19]];
        [nameLabel setTextColor:[UIColor whiteColor]];
        [nameLabel setNumberOfLines:0];
        CGRect textRect = cell.textLabel.frame;
        textRect.origin.x += 80;
        [cell.textLabel setFrame:textRect];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 30, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageView.layer.cornerRadius = 2.f;
        imageView.clipsToBounds = YES;
        [cell addSubview:imageView];
        [cell addSubview:nameLabel];
        [imageView setImageWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPhotoUrl100]]];
    } else {
        static NSString *CellIdentifier = @"PermissionsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        BHUser *coworker = [user.coworkers objectAtIndex:indexPath.row];
        [cell.textLabel setText:coworker.fullname];
        if (coworker.formatted_phone) {
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ \n%@",coworker.formatted_phone, coworker.email]];
        } else if (coworker.phone) {
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ \n%@",coworker.phone, coworker.email]];
        } else {
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@", coworker.email]];
        }
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        if (iPhone5 || iPad){
            return 100;
        } else {
            return 90;
        }
    } else {
        if (iPhone5 || iPad){
            return 88;
        } else {
            return 66;
        }
    }
}

- (IBAction)logout {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    if ([self.presentingViewController isKindOfClass:[BHLoginViewController class]]){
        [(BHLoginViewController*)self.presentingViewController adjustLoginContainer];
        [self dismissViewControllerAnimated:YES completion:^{}];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        BHLoginViewController *initialVC = [storyboard instantiateInitialViewController];
        [initialVC adjustLoginContainer];
        [self presentViewController:initialVC animated:YES completion:nil];
    }
    [SVProgressHUD dismiss];
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
    if (indexPath.section == 1) {
        selectedCoworker = [user.coworkers objectAtIndex:indexPath.row];
        if (selectedCoworker.phone) {
            [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Contact %@",selectedCoworker.fullname] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:emailPlaceholder,callPlaceholder,textPlaceholder, nil] showInView:self.tableView];
        } else {
            [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Contact %@",selectedCoworker.fullname] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:emailPlaceholder,nil] showInView:self.tableView];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:emailPlaceholder]) {
        [self sendMail:selectedCoworker.email];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:callPlaceholder]) {
        [self placeCall];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:textPlaceholder]) {
        [self sendText];
    }
}

- (void)placeCall {
    NSString *phoneNumber = [@"tel://" stringByAppendingString:[[selectedCoworker.phone stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}


#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSString*)destinationEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        //[controller setSubject:@""];
        [controller setToRecipients:@[destinationEmail]];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {}
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendText {
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:@[selectedCoworker.phone]];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
