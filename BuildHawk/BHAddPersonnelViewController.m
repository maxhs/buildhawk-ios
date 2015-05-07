//
//  BHAddPersonnelViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/5/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHAddPersonnelViewController.h"
#import "BHAddPersonnelCell.h"
#import "BHAppDelegate.h"
#import <AddressBook/AddressBook.h>
#import "BHAddressBookPickerViewController.h"
#import "BHReportViewController.h"
#import "BHTaskViewController.h"

@interface BHAddPersonnelViewController () <UITextFieldDelegate, UIAlertViewDelegate, BHAddressBookPickerDelegate> {
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *createButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *dismissButton;
    AFHTTPRequestOperationManager *manager;
    NSArray *peopleArray;
    UIAlertView *userAlertView;
    NSString *email;
    NSString *phone;
    ReportUser *selectedReportUser;
    UIAlertView *assigneeAlert;
}

@end

@implementation BHAddPersonnelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    self.tableView.rowHeight = 60.f;
    
    createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(create)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = createButton;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [self registerForKeyboardNotifications];

    [self.view setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if (self.task){
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 66)];
        _skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_skipButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
        [_skipButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_skipButton setTitle:@"DON'T NOTIFY ASSIGNEE" forState:UIControlStateNormal];
        [_skipButton setFrame:CGRectMake(40, 10, width-80, 44)];
        [_skipButton addTarget:self action:@selector(skip) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:_skipButton];
        self.tableView.tableFooterView = footerView;
    }
}

- (void)skip {
    assigneeAlert = [[UIAlertView alloc] initWithTitle:@"Assign a Task" message:@"Add custom text into the \"assignee\" field. No recipients will be notified." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    [assigneeAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [assigneeAlert show];
}

#pragma mark - Navigation

- (void)next {
    if (_emailTextField.text.length){
        email = _emailTextField.text;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (email.length) {
        [parameters setObject:email forKey:@"email"];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Please add either an email address or phone number before continuing." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }

    if (parameters){
        [ProgressHUD show:@"Searching..."];
        [manager POST:[NSString stringWithFormat:@"%@/projects/%@/find_user",kApiBaseUrl,_project.identifier] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success finding user: %@",responseObject);
            [ProgressHUD dismiss];
            if ([[responseObject objectForKey:@"success"] isEqualToNumber:@0]){
                //success => false means the API searched for, but could not find, a match
                [self moveForward];
            } else {
                NSDictionary *userDict = [responseObject objectForKey:@"user"];
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [user populateFromDictionary:userDict];
                } else {
                    [user updateFromDictionary:userDict];
                }
                
                if (self.task){
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:user];
                    self.task.assignees = assignees;
                    [self saveAndExit];
                } else if (self.report) {
                    selectedReportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    selectedReportUser.userId = user.identifier;
                    selectedReportUser.fullname = user.fullname;
                    [self getHours];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to find user: %@",error.description);
        }];
    }
}

- (void)getHours {
    userAlertView = [[UIAlertView alloc] initWithTitle:@"# of Hours Worked" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
    userAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[userAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
    [userAlertView show];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == userAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *hours = [f numberFromString:[[userAlertView textFieldAtIndex:0] text]];
            if (hours.floatValue > 0.f){
                [self selectReportUserWithCount:hours];
            }
        }
    } else if (alertView == assigneeAlert) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Add"]){
            NSString *assigneeText = [[assigneeAlert textFieldAtIndex:0] text];
            if (self.task){
                [self.task setAssigneeName:assigneeText];
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            }
            __block BHTaskViewController *taskVC;
            [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if ([vc isKindOfClass:[BHTaskViewController class]]){
                    taskVC = (BHTaskViewController*)vc;
                    *stop = YES;
                }
            }];
            if (taskVC){
                [self.navigationController popToViewController:taskVC animated:YES];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } else {
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        }
    }
}

- (void)selectReportUserWithCount:(NSNumber*)count {
    if (selectedReportUser){
        selectedReportUser.hours = count;
        [self.report addReportUser:selectedReportUser];
        //[self saveAndExit];
    }
}

- (void)moveForward {
    [self performSegueWithIdentifier:@"Details" sender:nil];
}

- (void)previous {
    [_tableView setHidden:NO];
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.rightBarButtonItem = createButton;
    CGRect firstFrame = _tableView.frame;
    firstFrame.origin.x = 0;
    //[self.tableView reloadData];
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_tableView setFrame:firstFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)saveAndExit {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [ProgressHUD dismiss];
        if (self.report){
            [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if ([vc isKindOfClass:[BHReportViewController class]]){
                    BHReportViewController *reportvc = (BHReportViewController*)vc;
                    [reportvc.collectionView reloadData];
                    [self.navigationController popToViewController:vc animated:YES];
                    *stop = YES;
                }
            }];
        } else if (self.task){
            [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
                if ([vc isKindOfClass:[BHTaskViewController class]]){
                    [(BHTaskViewController*)vc setTaskId:self.task.objectID];
                    [(BHTaskViewController*)vc drawItem];
                    [self.navigationController popToViewController:vc animated:YES];
                    *stop = YES;
                }
            }];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AddPersonnel";
    BHAddPersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddPersonnelCell" owner:self options:nil] lastObject];
    }
    cell.personnelTextField.delegate = self;
    [cell.personnelTextField setUserInteractionEnabled:YES];
    
    if (tableView == self.tableView){
        switch (indexPath.row) {
            case 0:
                [cell.textLabel setText:@"Pull from address book"];
                [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kOpenSans] size:0]];
                [cell.imageView setImage:[UIImage imageNamed:@"contacts"]];
                [cell.personnelTextField setUserInteractionEnabled:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            case 1:
                cell.personnelTextField.placeholder = @"Or enter an email address";
                _emailTextField = cell.personnelTextField;
                [_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [_emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [_emailTextField setReturnKeyType:UIReturnKeyNext];
                [_emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.imageView setImage:[UIImage imageNamed:@"email"]];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                break;
            default:
                break;
        }
    }
    return cell;
}

- (void)create {
    if (_emailTextField.text.length > 0){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (_company && ![_company.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:_company.identifier forKey:@"company_id"];
        }
        if (self.task && ![self.task.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            [parameters setObject:self.task.identifier forKey:@"task_id"];
        }
        
        NSMutableDictionary *userParameters = [NSMutableDictionary dictionary];
        if (_emailTextField.text.length){
            [userParameters setObject:_emailTextField.text forKey:@"email"];
        }
        [ProgressHUD show:@"Adding contact..."];
        [parameters setObject:userParameters forKey:@"user"]; // wrap it in a "user" hash
        
        [manager POST:[NSString stringWithFormat:@"%@/projects/%@/add_user",kApiBaseUrl,_project.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success creating a new project sub user: %@",responseObject);
            
            if ([responseObject objectForKey:@"user"]){
                NSDictionary *userDict = [responseObject objectForKey:@"user"];
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [user populateFromDictionary:userDict];
                
                if (self.task){
                    NSMutableOrderedSet *assignees = [NSMutableOrderedSet orderedSet];
                    [assignees addObject:user];
                    self.task.assignees = assignees;
                    
                    //Check if the user is active or not. If not, then they're a "connect user"
                    if ([user.active isEqualToNumber:@NO]){
                        NSString *alertMessage;
                        if (user.email.length){
                            alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've emailed them this task.";
                        } else {
                            alertMessage = @"The person you've selected doesn't currently use BuildHawk, but we've notified them about this task.";
                        }
                        [[[UIAlertView alloc] initWithTitle:@"BuildHawk Connect" message:alertMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    }
    
                } else if (self.report) {
                    ReportUser *reportUser = [ReportUser MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    reportUser.userId = user.identifier;
                    reportUser.fullname = user.fullname;
                    [self.report addReportUser:reportUser];
                }
            }
            
            [self saveAndExit];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating a company sub: %@",error.description);
            [ProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Unable to connect" message:@"Something went wrong while trying to add personnel." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Email Needed" message:@"Please make sure you've added an email address for this recipient." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
        return emptyView;
    } else {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), 4)];
        [headerView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
        
        UILabel *contactInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, screenWidth()-40, 24)];
        [contactInfoLabel setTextColor:[UIColor darkGrayColor]];
        [contactInfoLabel setText:@"CONTACT INFO"];
        [contactInfoLabel setTextAlignment:NSTextAlignmentCenter];
        [contactInfoLabel setFont:[UIFont fontWithName:kOpenSans size:16]];
        contactInfoLabel.numberOfLines = 0;
        [headerView addSubview:contactInfoLabel];
        
        return headerView;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        CFErrorRef error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (!addressBook)
        {
            //some sort of error preventing us from grabbing the address book
            return;
        }
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted){
                CFArrayRef arrayOfPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
                peopleArray = (__bridge NSArray *)(arrayOfPeople);
                
                CFRelease(arrayOfPeople);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"AddressBook" sender:nil];
                });
            }
        });
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddressBook"]){
        BHAddressBookPickerViewController *vc = [segue destinationViewController];
        vc.addressBookPickerDelegate = self;
        [vc setPeopleArray:peopleArray];
        [vc setCompany:_company];
        [vc setProject:_project];
        if (_company.name.length){
            [vc setTitle:[NSString stringWithFormat:@"%@",_company.name]];
        } else {
            [vc setTitle:@"Address Book"];
        }
        if (self.task){
            [vc setTask:self.task];
        }
    }
}

- (void)userSelected:(User *)user {
    if (user.email.length){
        [_emailTextField setText:user.email];
        [self.tableView reloadData];
    }
}

#pragma mark - UITextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textField == _emailTextField){
            [textField resignFirstResponder];
            [self next];
        }
    }
    return YES;
}

- (void)doneEditing {
    self.navigationItem.rightBarButtonItem = createButton;
    [self.view endEditing:YES];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                     }
                     completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
