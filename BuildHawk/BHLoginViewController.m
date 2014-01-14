//
//  BHLoginViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHLoginViewController.h"
#import "BHUser.h"
#import "User.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHAppDelegate.h"
#import "BHMenuViewController.h"
#import "BHDashboardViewController.h"
#import "Constants.h"
#import "SVProgressHUD.h"


@interface BHLoginViewController () <UIAlertViewDelegate, UITextFieldDelegate> {
    BOOL iPhone5;
    BHUser *user;
    BOOL iPad;
}
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *logoContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
-(IBAction)loginTapped;

@end

@implementation BHLoginViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        iPhone5 = NO;
        self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -88);
        self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -88);
    } else {
        iPad = YES;
    }
    [self adjustLoginContainer];
}

- (void)adjustLoginContainer {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthToken]) {
        [self.loginContainerView setAlpha:0.0];
        [self login:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]];
    }
}

- (IBAction)loginTapped {
    [self login:self.emailTextField.text andPassword:self.passwordTextField.text];
}

- (void)login:(NSString*)email andPassword:(NSString*)password{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [SVProgressHUD showWithStatus:@"Logging in..."];
    if (!email.length)
        email = self.emailTextField.text;
    if (!password.length)
        password = self.passwordTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:email forKey:@"user[email]"];
    [parameters setObject:password forKey:@"user[password]"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"user[device_token]"];
    [manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"log in response object: %@",responseObject);
        user = [[BHUser alloc] initWithDictionary:[responseObject objectForKey:@"user"]];
        [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:email forKey:kUserDefaultsEmail];
        [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:kUserDefaultsAuthToken];
        [[NSUserDefaults standardUserDefaults] setObject:user.fname forKey:kUserDefaultsFirstName];
        [[NSUserDefaults standardUserDefaults] setObject:user.lname forKey:kUserDefaultsLastName];
        [[NSUserDefaults standardUserDefaults] setObject:user.fullname forKey:kUserDefaultsFullName];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:kUserDefaultsPassword];
        [[NSUserDefaults standardUserDefaults] setObject:user.photo.url100 forKey:kUserDefaultsPhotoUrl100];
        [[NSUserDefaults standardUserDefaults] setObject:user.company.identifier forKey:kUserDefaultsCompanyId];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", user.identifier];
        User *saveUser = [User MR_findFirstWithPredicate:predicate inContext:localContext];
        if (saveUser) {
            NSLog(@"found existing MR user");
            saveUser.identifier = user.identifier;
            saveUser.lname = user.lname;
            saveUser.email = user.email;
            saveUser.fullname = user.fullname;
            saveUser.fname = user.fname;
            saveUser.coworkers = user.coworkers;
            saveUser.subcontractors = user.subcontractors;
            NSLog(@"save user has subcontractors: %i, %@",user.subcontractors.count, saveUser.subcontractors);
            saveUser.photoUrl100 = user.photo.url100;
            saveUser.phone1 = user.phone1;
            
            [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (success) NSLog(@"done saving user through Magical Record");
                else NSLog(@"error saving through MR: %@",error.description);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessful" object:nil];
                [UIView animateWithDuration:.3 animations:^{
                    self.loginContainerView.transform = CGAffineTransformIdentity;
                    self.logoContainerView.transform = CGAffineTransformIdentity;
                    [self.view endEditing:YES];
                } completion:^(BOOL finished) {
                    
                }];
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
            }];
        } else {
            User *newUser = [User MR_createInContext:localContext];
            NSLog(@"had to create new MR user");
            newUser.identifier = user.identifier;
            newUser.lname = user.lname;
            newUser.email = user.email;
            newUser.fullname = user.fullname;
            newUser.fname = user.fname;
            newUser.coworkers = user.coworkers;
            newUser.subcontractors = user.subcontractors;
            NSLog(@"new user has subcontractors: %i, %@",user.subcontractors.count, saveUser.subcontractors);
            newUser.photoUrl100 = user.photo.url100;
            newUser.phone1 = user.phone1;
            [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (success) NSLog(@"done saving user through Magical Record");
                else NSLog(@"error saving through MR: %@",error.description);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessful" object:nil];
                [UIView animateWithDuration:.3 animations:^{
                    self.loginContainerView.transform = CGAffineTransformIdentity;
                    self.logoContainerView.transform = CGAffineTransformIdentity;
                    [self.view endEditing:YES];
                } completion:^(BOOL finished) {
                    
                }];
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
            }];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error logging in: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [SVProgressHUD dismiss];
        [self.loginContainerView setAlpha:1.0];
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (iPhone5){
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -220);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -180);
        } else if (iPad) {
            
        } else {
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -286);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -210);
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (self.passwordTextField.text.length && self.emailTextField.text.length) {
            [self login:self.emailTextField.text andPassword:self.passwordTextField.text];
        }
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.loginContainerView setAlpha:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
