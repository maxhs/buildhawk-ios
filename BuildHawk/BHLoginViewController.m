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
#import "Company+helper.h"
#import "Project+helper.h"
#import "BHTabBarViewController.h"

static NSString * const kShakeAnimationKey = @"BuildHawkLoginResponse";

@interface BHLoginViewController () <UIAlertViewDelegate, UITextFieldDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    NSString *forgotPasswordEmail;
    BHAppDelegate* delegate;
    NSMutableOrderedSet *projectSet;
    Project *demoProject;
    UIButton *demoButton;
    NSArray *views;
    NSUInteger completedAnimations;
    void (^completionBlock)();
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
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
    
    [self.loginButton setTitleColor:[UIColor colorWithWhite:0 alpha:.2] forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitleColor:[UIColor colorWithWhite:0 alpha:.2] forState:UIControlStateNormal];
    [self.loginButton setEnabled:NO];
    self.loginButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
    self.loginButton.layer.borderWidth = .5f;
    self.loginButton.layer.cornerRadius = 0.f;
    [self adjustLoginContainer];
    demoProject = [Project MR_findFirstByAttribute:@"demo" withValue:[NSNumber numberWithBool:YES]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self loadDemo];
}

- (void)loadDemo {
    [self drawDemoButton];
    [delegate.manager GET:[NSString stringWithFormat:@"%@/projects/demo",kApiBaseUrl] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting demo projects: %@",responseObject);
        [self updateProjects:[responseObject objectForKey:@"projects"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get demo project: %@", error.description);
    }];
}

- (void)updateProjects:(NSArray*)projectsArray {
    if (projectsArray.count == 0){
        [ProgressHUD dismiss];
    } else {
        projectSet = [NSMutableOrderedSet orderedSet];
        for (id obj in projectsArray) {
            Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:(NSNumber*)[obj objectForKey:@"id"]];
            if (!project){
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:obj];
            [projectSet addObject:project];
        }

        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"What happened during login save? %hhd %@",success, error);
            if (projectSet.count){
                [demoButton setUserInteractionEnabled:YES];
                [UIView animateWithDuration:.23 animations:^{
                    [demoButton setAlpha:1.0];
                }];
            }
        }];
    }
}

- (void)drawDemoButton {
    demoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [demoButton setFrame:CGRectMake(0, screenHeight()-44, screenWidth(), 44)];
    [demoButton setTitle:@"View demo project" forState:UIControlStateNormal];
    [demoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [demoButton setBackgroundColor:kBlueColor];
    [demoButton addTarget:self action:@selector(viewDemoProject) forControlEvents:UIControlEventTouchUpInside];
    [demoButton setUserInteractionEnabled:NO];
    [demoButton setAlpha:0];
    [self.view addSubview:demoButton];
}

- (void) viewDemoProject {
    [self performSegueWithIdentifier:@"DemoProject" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DemoProject"]){
        BHTabBarViewController *vc = [segue destinationViewController];
        [vc setProject:projectSet.lastObject];
    }
}

- (void)textFieldTreatment:(UITextField*)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
    textField.layer.borderWidth = .5f;
    textField.layer.cornerRadius = 0.f;
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
        [delegate.manager POST:[NSString stringWithFormat:@"%@/sessions/forgot_password",kApiBaseUrl] parameters:@{@"email":email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [ProgressHUD show:@"Logging in..."];
    if (!email.length)
        email = self.emailTextField.text;
    if (!password.length)
        password = self.passwordTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (email) [parameters setObject:email forKey:@"email"];
    if (password) [parameters setObject:password forKey:@"password"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
    [delegate.manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success logging in: %@",responseObject);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", [[responseObject objectForKey:@"user"] objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user) {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
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
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [delegate.menu setCurrentUser:user];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadUser" object:nil];
            [UIView animateWithDuration:.3 animations:^{
                self.loginContainerView.transform = CGAffineTransformIdentity;
                self.logoContainerView.transform = CGAffineTransformIdentity;
                [self.view endEditing:YES];
            } completion:^(BOOL finished) {
                [self.loginButton setUserInteractionEnabled:YES];
                [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
            }];
            
        }];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        if (operation.response.statusCode == 401) {
            if ([operation.responseString isEqualToString:@"Incorrect password"]){
                [self addShakeAnimationForView:self.passwordTextField withDuration:.77];
                
            } else if ([operation.responseString isEqualToString:@"User already exists"]) {
                //[self addShakeAnimationForView:self.registerEmailTextField withDuration:.77];
                //[self alert:@"An account with that email address already exists."];
                
            } else if ([operation.responseString isEqualToString:@"No email"]) {
                [self addShakeAnimationForView:self.emailTextField withDuration:.77];
                //[self alert:@"Sorry, but we couldn't find an account for that email address."];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"Something went wrong while trying to log you in." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        [ProgressHUD dismiss];
        [self.loginContainerView setAlpha:1.0];
        [self.loginButton setUserInteractionEnabled:YES];
    }];
}

#pragma mark - Shake Animation

- (void)addShakeAnimationForView:(UIView *)view withDuration:(NSTimeInterval)duration {
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.delegate = self;
    animation.duration = duration;
    animation.values = @[ @(0), @(10), @(-8), @(8), @(-5), @(5), @(0) ];
    animation.keyTimes = @[ @(0), @(0.225), @(0.425), @(0.6), @(0.75), @(0.875), @(1) ];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:animation forKey:kShakeAnimationKey];
}


#pragma mark - CAAnimation Delegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    completedAnimations += 1;
    if ( completedAnimations >= views.count ) {
        completedAnimations = 0;
        if ( completionBlock ) {
            completionBlock();
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (iPhone5){
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -180);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -190);
        } else if (iPad) {
            
        } else {
            self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -286);
            self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -220);
        }
    } completion:^(BOOL finished) {
        
    }];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if (self.emailTextField.text.length && self.passwordTextField.text.length){
        [self.loginButton setEnabled:YES];
        [self.loginButton setBackgroundColor:kBlueColor];
        [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self.loginButton setTitleColor:[UIColor colorWithWhite:0 alpha:.2] forState:UIControlStateNormal];
        [self.loginButton setBackgroundColor:[UIColor clearColor]];
        self.loginButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
        [self.loginButton setEnabled:NO];
    }
    if ([text isEqualToString:@"\n"]) {
        if (textField == self.emailTextField){
            [self.passwordTextField becomeFirstResponder];
            return YES;
        } else if (self.passwordTextField.text.length && self.emailTextField.text.length) {
            [textField resignFirstResponder];
            [self login:self.emailTextField.text andPassword:self.passwordTextField.text];
        }
    }
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.loginContainerView setAlpha:1.0];
    [demoButton removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
