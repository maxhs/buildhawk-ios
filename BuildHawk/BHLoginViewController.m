//
//  BHLoginViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHLoginViewController.h"
#import "User.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHAppDelegate.h"
#import "BHMenuViewController.h"
#import "BHDashboardViewController.h"
#import "Constants.h"
#import "User+helper.h"

@interface BHLoginViewController () <UIAlertViewDelegate, UITextFieldDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    NSString *forgotPasswordEmail;
}
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIView *logoContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
-(IBAction)loginTapped;
-(IBAction)forgotPassword;

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
    [self textFieldTreatment:self.emailTextField];
    [self textFieldTreatment:self.passwordTextField];
    
    [self.loginButton setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.8]];
    [self.loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.loginButton setEnabled:NO];
    self.loginButton.layer.borderColor = [UIColor colorWithWhite:.8 alpha:1].CGColor;
    self.loginButton.layer.borderWidth = .5f;
    self.loginButton.layer.cornerRadius = 5.f;
    [self adjustLoginContainer];
}

- (void)textFieldTreatment:(UITextField*)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
    textField.layer.borderWidth = .5f;
    textField.layer.cornerRadius = 5.f;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)adjustLoginContainer {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
        [self.loginContainerView setAlpha:0.0];
        [self login:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]];
    }
}

- (IBAction)loginTapped {
    [self.loginButton setUserInteractionEnabled:NO];
    [self login:self.emailTextField.text andPassword:self.passwordTextField.text];
}

- (IBAction)forgotPassword{
    if (self.emailTextField.text.length || forgotPasswordEmail.length){
        NSString *email;
        if (forgotPasswordEmail.length){
            email = forgotPasswordEmail;
        } else {
            email = self.emailTextField.text;
        }
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:[NSString stringWithFormat:@"%@/sessions/forgot_password",kApiBaseUrl] parameters:@{@"email":email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"success with forgot password: %@",responseObject);
            if ([responseObject objectForKey:@"failure"]){
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldn't find an account for that email address." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"BuildHawk Password" message:@"You'll receive password reset instructions within the next few minutes." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Error reaching forgot password endpoint: %@",error.description);
        }];
    } else {
        UIAlertView *forgotPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Forgot Password?" message:@"Please enter your email address:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        forgotPasswordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [forgotPasswordAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]){
        forgotPasswordEmail = [[alertView textFieldAtIndex:0] text];
        [self forgotPassword];
    }
}

- (void)login:(NSString*)email andPassword:(NSString*)password{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [ProgressHUD show:@"Logging in..."];
    if (!email.length)
        email = self.emailTextField.text;
    if (!password.length)
        password = self.passwordTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (email) [parameters setObject:email forKey:@"email"];
    if (password) [parameters setObject:password forKey:@"password"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
    [manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"log in response object: %@",responseObject);
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_defaultContext];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", [[responseObject objectForKey:@"user"] objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:localContext];
        if (!user) {
            user = [User MR_createInContext:localContext];
            NSLog(@"Created a new MR user");
        }
        [user populateFromDictionary:[responseObject objectForKey:@"user"]];

        [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:email forKey:kUserDefaultsEmail];
        [[NSUserDefaults standardUserDefaults] setObject:user.authToken forKey:kUserDefaultsAuthToken];
        [[NSUserDefaults standardUserDefaults] setObject:user.firstName forKey:kUserDefaultsFirstName];
        [[NSUserDefaults standardUserDefaults] setObject:user.lastName forKey:kUserDefaultsLastName];
        [[NSUserDefaults standardUserDefaults] setObject:user.fullname forKey:kUserDefaultsFullName];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:kUserDefaultsPassword];
        [[NSUserDefaults standardUserDefaults] setObject:user.company.identifier forKey:kUserDefaultsCompanyId];
        [[NSUserDefaults standardUserDefaults] setBool:user.admin.boolValue forKey:kUserDefaultsAdmin];
        [[NSUserDefaults standardUserDefaults] setBool:user.companyAdmin.boolValue forKey:kUserDefaultsCompanyAdmin];
        [[NSUserDefaults standardUserDefaults] setBool:user.uberAdmin.boolValue forKey:kUserDefaultsUberAdmin];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessful" object:nil];
            [UIView animateWithDuration:.3 animations:^{
                self.loginContainerView.transform = CGAffineTransformIdentity;
                self.logoContainerView.transform = CGAffineTransformIdentity;
                [self.view endEditing:YES];
            } completion:^(BOOL finished) {
                
            }];
            [self.loginButton setUserInteractionEnabled:YES];
            [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
        }];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error logging in: %@",error.description);
        if (operation.response.statusCode == 401) {
            [[[UIAlertView alloc] initWithTitle:@"Incorrect password" message:@"Your email and password don't match. Please try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        [ProgressHUD dismiss];
        [self.loginContainerView setAlpha:1.0];
        [self.loginButton setUserInteractionEnabled:YES];
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (iPhone5){
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -220);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -190);
        } else if (iPad) {
            
        } else {
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -286);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -220);
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if (self.emailTextField.text.length && self.passwordTextField.text.length){
        [self.loginButton setEnabled:YES];
        [self.loginButton setBackgroundColor:kBlueColor];
        [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self.loginButton setBackgroundColor:[UIColor colorWithWhite:.9 alpha:.8]];
        [self.loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.loginButton setEnabled:NO];
    }
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
