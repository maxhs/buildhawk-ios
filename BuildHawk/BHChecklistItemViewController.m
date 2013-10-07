//
//  BHChecklistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/23/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistItemViewController.h"
#import "BHChecklistItem.h"
#import "Constants.h"
#import "BHCommentCell.h"
#import "BHAddCommentCell.h"
#import "BHChecklistMessageCell.h"
#import "BHListItemPhotoCell.h"
#import <MessageUI/MessageUI.h>
#import <RestKit/RestKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHChecklistItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate> {
    NSMutableArray *photosArray;
    AFHTTPClient *checklistClient;
    BOOL complete;
    NSString *mainPhoneNumber;
    NSString *recipientEmail;
    BOOL text;
    BOOL phone;
}

@end

@implementation BHChecklistItemViewController

@synthesize item;
@synthesize comments = _comments;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _comments = [NSMutableArray arrayWithCapacity:0];
    if (!photosArray) photosArray = [NSMutableArray array];
    checklistClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.buildhawk.com/api/v1"]];
    [checklistClient setDefaultHeader:@"Accept" value:@"application/json"];
    [checklistClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    if (self.item.completed) complete = YES;
    else complete = NO;
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
    if (section == 0) return 1;
    else if (section == 1) return 3;
    else if (section == 2) return 1;
    else if (section == 3) return _comments.count + 1;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return self.item.type;
    } else return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        BHChecklistMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
        if (messageCell == nil) {
            messageCell = [[[NSBundle mainBundle] loadNibNamed:@"BHChecklistMessageCell" owner:self options:nil] lastObject];
        }
        [messageCell.messageTextView setText:self.item.name];
        [messageCell.messageTextView setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
        [messageCell.emailButton addTarget:self action:@selector(showContactPicker) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.callButton addTarget:self action:@selector(startPhone) forControlEvents:UIControlEventTouchUpInside];
        [messageCell.textButton addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
        return messageCell;
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"ActionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        UIView *selectecBackgroundColor = [[UIView alloc] init];
        [selectecBackgroundColor setBackgroundColor:kDarkGrayColor];
        cell.selectedBackgroundView = selectecBackgroundColor;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        switch (indexPath.row) {
            case 0:
                if (self.item.completed) {
                    NSLog(@"cell selected!");
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                [cell.textLabel setText:@"COMPLETED"];
                break;
            case 1:
                [cell.textLabel setText:@"IN-PROGRESS"];
                break;
            case 2:
                [cell.textLabel setText:@"NOT APPLICABLE"];
                break;
                
            default:
                break;
        }
        return cell;
    } else if (indexPath.section == 2) {
        BHListItemPhotoCell *photoCell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
        if (photoCell == nil) {
            photoCell = [[[NSBundle mainBundle] loadNibNamed:@"BHListItemPhotoCell" owner:self options:nil] lastObject];
        }
        [photoCell.takePhotoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        return photoCell;
    } else {
        if (indexPath.row == _comments.count) {
            BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
            if (addCommentCell == nil) {
                addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
            }
            return addCommentCell;
        } else {
            BHCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
            if (commentCell == nil) {
                commentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHCommentCell" owner:self options:nil] lastObject];
            }
            return commentCell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 180;
            break;
        case 1:
            return 54;
            break;
        case 2:
            return 100;
            break;
        case 3:
            return 80;
            break;
        default:
            return 0;
            break;
    }
}

- (void)placeCall:(NSString*)number {
    NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
    NSString *phoneString = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@")" withString:@""];
    phoneString= [phoneString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneString]];
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)sendMail:(NSString*)destinationEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.navigationBar.barStyle = UIBarStyleBlack;
        controller.mailComposeDelegate = self;
        [controller setSubject:[NSString stringWithFormat:@"%@",self.item.type]];
        [controller setToRecipients:@[destinationEmail]];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send mail on this device." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
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
        [viewController setRecipients:nil];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        
    } else if (result == MessageComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But we weren't able to send your message. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    }
}

- (void)choosePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)takePhoto {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [photosArray addObject:[info objectForKey:UIImagePickerControllerEditedImage]];
    [self.tableView reloadData];
}

-(void)removePhoto {
    //eventPhoto = nil;
    [self.tableView reloadData];
}

- (void)startPhone {
    phone = YES;
    text = NO;
    [self showContactPicker];
}

- (void)showContactPicker {
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES
                             completion:^{}];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    if (kABPersonEmailProperty == property) {
        ABMultiValueRef emailRef = ABRecordCopyValue(person, kABPersonEmailProperty);
        recipientEmail = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emailRef, 0);
        [self sendMail:recipientEmail];
        NSLog(@"recipient email: %@",recipientEmail);
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        return NO;
    } else if (kABPersonPhoneProperty == property) {
        ABMultiValueRef phoneRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
        mainPhoneNumber = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneRef, 0);
        NSLog(@"main phone number: %@",mainPhoneNumber);
        if (phone) [self placeCall:mainPhoneNumber];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        return NO;
    }
    return YES;
}


-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"view is disappering");
    if (complete) [self sendComplete];
    [super viewWillDisappear:animated];
}


-(AFJSONRequestOperation*)sendComplete {
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to mark checklist item as complete: %@",error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        
        NSLog(@"Success completing checklist item: %@",responseObject);
    };
    NSDictionary *parameters = @{@"authToken":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthToken],@"user":@{@"_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}};
    NSMutableURLRequest *request = [checklistClient requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"checklist/complete/%@",self.item.identifier] parameters:parameters];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[checklistClient HTTPRequestOperationWithRequest:request
                                                                                                    success:opSuccess
                                                                                                    failure:opFailure];
    [op start];
    return op;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            complete = !complete;
        }
    }
}

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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
