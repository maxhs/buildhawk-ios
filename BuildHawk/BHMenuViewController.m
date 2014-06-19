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
#import "User+helper.h"
#import <CoreData+MagicalRecord.h>
#import <MessageUI/MessageUI.h>
#import "BHNotificationCell.h"
#import "Notification+helper.h"
#import "BHSettingsViewController.h"

static NSString *callPlaceholder = @"Call";
static NSString *emailPlaceholder = @"Email";
static NSString *textPlaceholder = @"Text Message";

@interface BHMenuViewController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    User *selectedCoworker;
    User *currentUser;
    CGRect screen;
    BOOL iPhone5;
    BOOL iPad;
    NSDateFormatter *dateFormatter;
    NSIndexPath *indexPathForDeletion;
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
    currentUser = [User MR_findFirstWithPredicate:predicate inContext:localContext];
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
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadNotifications];
}

- (void)loadNotifications {
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] GET:[NSString stringWithFormat:@"%@/notifications/messages",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting messages: %@",responseObject);
        [self updateNotifications:[responseObject objectForKey:@"notifications"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting notifications: %@",error.description);
    }];
}

- (void)updateNotifications:(NSArray*)array {
    NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *dict in array){
        Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"]];
        if (!notification){
            notification = [Notification MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [notification populateFromDictionary:dict];
        [notifications addObject:notification];
    }
    
    for (Notification *notification in currentUser.notifications) {
        if (![notifications containsObject:notification]) {
            NSLog(@"Deleting a notification that no longer exists: %@",notification.body);
            [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }
    currentUser.notifications = notifications;
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Success saving notifications: %u",success);
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }];
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
    else return currentUser.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"UserCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 32, cell.frame.size.width-80, 27)];
        [nameLabel setText:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFullName]];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setFont:[UIFont systemFontOfSize:19]];
        [nameLabel setTextColor:[UIColor whiteColor]];
        [nameLabel setNumberOfLines:0];
        
        UILabel *settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 52, cell.frame.size.width-80, 27)];
        [settingsLabel setText:@"Tap to edit settings"];
        [settingsLabel setFont:[UIFont italicSystemFontOfSize:15]];
        [settingsLabel setBackgroundColor:[UIColor clearColor]];
        [settingsLabel setTextColor:[UIColor whiteColor]];
        [settingsLabel setNumberOfLines:0];
        
        CGRect textRect = cell.textLabel.frame;
        textRect.origin.x += 80;
        [cell.textLabel setFrame:textRect];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 30, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageView.layer.cornerRadius = 2.f;
        imageView.clipsToBounds = YES;
        [cell addSubview:imageView];
        [cell addSubview:nameLabel];
        [cell addSubview:settingsLabel];
        
        [imageView setImageWithURL:[NSURL URLWithString:currentUser.photoUrlSmall]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setBackgroundColor:[UIColor clearColor]];
        
        return cell;
    } else {
        static NSString *CellIdentifier = @"PermissionsCell";
        BHNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHDashboardProjectCell" owner:self options:nil] lastObject];
        }
        Notification *notification = [currentUser.notifications objectAtIndex:indexPath.row];
        [cell.textLabel setText:notification.body];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.detailTextLabel setText:[dateFormatter stringFromDate:notification.createdDate]];
        return cell;
    }
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

- (void)goToSettings {
    BHSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
    [vc setTitle:@"Settings"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this notification?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self deleteNotification];
    } else {
        indexPathForDeletion = nil;
    }
}

- (void)deleteNotification{
    [ProgressHUD show:@"Deleting..."];
    Notification *notification = [currentUser.notifications objectAtIndex:indexPathForDeletion.row];
    [currentUser removeNotification:notification];
    [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] DELETE:[NSString stringWithFormat:@"%@/notifications/%@",kApiBaseUrl, notification.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        NSLog(@"Success deleting notification: %@",responseObject);
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this notification. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Error deleting notification: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (IBAction)logout {
    [self cleanAndResetupDB];
    
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
    [ProgressHUD dismiss];
}

- (void)cleanAndResetupDB {
    NSError *error = nil;
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:@"BuildHawk"];
    [MagicalRecord cleanUp];
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"BuildHawk"];
    } else{
        NSLog(@"Error deleting persistent store description: %@ %@", error.description,storeURL);
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        [self goToSettings];
    } else if (indexPath.section == 1) {
        
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
