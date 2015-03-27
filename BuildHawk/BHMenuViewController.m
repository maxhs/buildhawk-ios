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
#import "BHMessageCell.h"
#import "Notification+helper.h"
#import "Message+helper.h"
#import "BHSettingsViewController.h"
#import <RESideMenu/RESideMenu.h>
#import "BHLoginViewController.h"

static NSString *callPlaceholder = @"Call";
static NSString *emailPlaceholder = @"Email";
static NSString *textPlaceholder = @"Text Message";

@interface BHMenuViewController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    BHAppDelegate *delegate;
    User *selectedCoworker;
    BOOL iPad;
    NSDateFormatter *dateFormatter;
    NSIndexPath *indexPathForDeletion;
}
@property (strong, nonatomic) User *currentUser;
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
    CGRect screen = [UIScreen mainScreen].bounds;
    
    [_logoutButton setFrame:CGRectMake(0, screen.size.height-88, self.tableView.frame.size.width, 88)];
    [_logoutButton setBackgroundColor:kDarkGrayColor];
    [_logoutButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMyriadPro] size:0]];
  
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    _currentUser = [delegate currentUser];
    
    if (!_currentUser && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadUser) name:@"ReloadUser" object:nil];
}

- (void)reloadUser {
    _currentUser = [(BHAppDelegate*)[UIApplication sharedApplication].delegate currentUser];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadNotifications];
}

- (void)loadNotifications {
    if (delegate.connected && delegate.loggedIn){
        [delegate.manager GET:[NSString stringWithFormat:@"%@/notifications/messages",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting messages: %@",responseObject);
            [self updateNotifications:[responseObject objectForKey:@"notifications"]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error getting notifications: %@",error.description);
        }];
    }
}

- (void)updateNotifications:(NSArray*)array {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        //refetch the user in case there's a CoreData fault
        self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
        NSMutableOrderedSet *notifications = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *dict in array){
            Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!notification){
                notification = [Notification MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [notification populateFromDictionary:dict];
            [notifications addObject:notification];
        }
        
        for (Notification *notification in self.currentUser.notifications) {
            if (![notifications containsObject:notification]) {
                //NSLog(@"Deleting a notification that no longer exists: %@",notification.body);
                [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
    
        [self.currentUser setNotifications:notifications];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //NSLog(@"Success saving notifications: %u",success);
            [self.tableView reloadData];
//            [self.tableView beginUpdates];
//            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
//            [self.tableView endUpdates];
        }];
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
    if (_currentUser){
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        return 2;
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return _currentUser.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"UserCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 32, cell.frame.size.width-80, 27)];
        [nameLabel setText:_currentUser.fullname];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setFont:[UIFont fontWithName:kMyriadPro size:19]];
        [nameLabel setTextColor:[UIColor whiteColor]];
        [nameLabel setNumberOfLines:0];
        
        UILabel *settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 52, cell.frame.size.width-80, 27)];
        [settingsLabel setText:@"Tap to edit settings"];
        [settingsLabel setFont:[UIFont fontWithName:kMyriadProItalic size:16]];
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
        if (_currentUser.photoUrlSmall.length){
            [imageView sd_setImageWithURL:[NSURL URLWithString:_currentUser.photoUrlSmall]];
        } else {
            [imageView setImage:[UIImage imageNamed:@"whiteIcon"]];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setBackgroundColor:[UIColor clearColor]];
        
        return cell;
    } else {
        static NSString *CellIdentifier = @"MessageCell";
        BHMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        Notification *notification = [_currentUser.notifications objectAtIndex:indexPath.row];
        if (notification.message.body.length){
            [cell.notificationLabel setText:[NSString stringWithFormat:@"\"%@\"\n -%@",notification.message.body,[dateFormatter stringFromDate:notification.createdDate]]];
        } else {
            [cell.notificationLabel setText:@""];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setBackgroundColor:[UIColor clearColor]];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
       return 100;
    } else {
        return 88;
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
    if (indexPath.section == 1 && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Confirmation Needed" message:@"Are you sure you want to delete this message?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
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
    Notification *notification = [_currentUser.notifications objectAtIndex:indexPathForDeletion.row];
    [_currentUser removeNotification:notification];
    [notification MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[(BHAppDelegate*)[UIApplication sharedApplication].delegate manager] DELETE:[NSString stringWithFormat:@"%@/notifications/%@",kApiBaseUrl, notification.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        NSLog(@"Success deleting notification: %@",responseObject);
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to delete this notification. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Error deleting notification: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (IBAction)logout {
    [self cleanAndResetDB];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [delegate updateLoggedInStatus];
    [delegate.syncController cancelSynch];
    BHLoginViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES];
    [self.sideMenuViewController hideMenuViewController];
    [self.tableView reloadData];
    [ProgressHUD dismiss];
}

- (void)cleanAndResetDB {
    NSError *error = nil;
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]];
    [MagicalRecord cleanUp];
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
        [MagicalRecord setupAutoMigratingCoreDataStack];
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
