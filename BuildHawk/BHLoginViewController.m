//
//  BHLoginViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHLoginViewController.h"
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
    CGRect mainScreen;
    NSString *forgotPasswordEmail;
    BHAppDelegate* delegate;
    NSMutableOrderedSet *projectSet;
    Project *demoProject;
    UIButton *demoButton;
    NSArray *views;
    NSUInteger completedAnimations;
    void (^completionBlock)();
    UITapGestureRecognizer *backgroundTapGesture;
    CGFloat logoY;
}

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

-(IBAction)loginTapped;
-(IBAction)forgotPassword;

@end

@implementation BHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    mainScreen = [UIScreen mainScreen].bounds;
    [self textFieldTreatment:self.emailTextField];
    [self.emailTextField setPlaceholder:@"user@example.com"];
    [self textFieldTreatment:self.passwordTextField];
    
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_loginButton setEnabled:NO];
    [_loginButton setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [_loginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kLato] size:0]];
    CGRect loginButtonFrame = _loginButton.frame;
    loginButtonFrame.origin.y = mainScreen.size.height;
    [_loginButton setFrame:loginButtonFrame];
    
    CGRect emailFrame = _emailTextField.frame;
    emailFrame.origin.y = mainScreen.size.height/2 - emailFrame.size.height;
    [_emailTextField setFrame:emailFrame];
    
    CGRect passwordFrame = _passwordTextField.frame;
    passwordFrame.origin.y = mainScreen.size.height/2-1;
    [_passwordTextField setFrame:passwordFrame];
    
    if (IDIOM != IPAD){
        CGPoint imageViewCenterPoint = self.view.center;
        imageViewCenterPoint.y -= 32.f;
        _logoImageView.center = imageViewCenterPoint;
    }
    
    [_forgotPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_forgotPasswordButton setTitle:@"Forget your password?" forState:UIControlStateNormal];
    [_forgotPasswordButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kLato] size:0]];
    
    [_forgotPasswordButton setAlpha:0.0];
    [_emailTextField setAlpha:0.0];
    [_passwordTextField setAlpha:0.0];
    [_loginButton setAlpha:0.0];

    demoProject = [Project MR_findFirstByAttribute:@"demo" withValue:@YES inContext:[NSManagedObjectContext MR_defaultContext]];
    backgroundTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditing)];
    backgroundTapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:backgroundTapGesture];
    [backgroundTapGesture setEnabled:NO];
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self loadDemo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken] forKey:@"mobile_token"];
        [self login:parameters];
    } else {
        [self showLoginStuff];
    }
}

- (void)showLoginStuff{
    CGRect newLogoFrame = _logoImageView.frame;
    newLogoFrame.origin.y = screenHeight()/4-_logoImageView.frame.size.height;
    [UIView animateWithDuration:.8 delay:.15 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [_logoImageView setFrame:newLogoFrame];
        [_emailTextField setAlpha:1.0];
        [_passwordTextField setAlpha:1.0];
        [_forgotPasswordButton setAlpha:1.0];
        [_loginButton setAlpha:1.0];
    } completion:^(BOOL finished) {
        logoY = _logoImageView.frame.origin.y;
    }];
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
            Project *project = [Project MR_findFirstByAttribute:@"identifier" withValue:[obj objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!project){
                project = [Project MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [project populateFromDictionary:obj];
            [projectSet addObject:project];
        }

        if (projectSet.count){
            [demoButton setUserInteractionEnabled:YES];
            [UIView animateWithDuration:.23 animations:^{
                [demoButton setAlpha:1.0];
            }];
        }
    }
}

- (void)drawDemoButton {
    demoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [demoButton setFrame:CGRectMake(0, screenHeight()-44, screenWidth(), 44)];
    [demoButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadProRegular] size:0]];
    [demoButton setTitle:@"VIEW DEMO PROJECT" forState:UIControlStateNormal];
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
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.1].CGColor;
    textField.layer.borderWidth = .5f;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 21)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
}

- (IBAction)loginTapped {
    [self.loginButton setUserInteractionEnabled:NO];
    
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (email) [parameters setObject:email forKey:@"email"];
    if (password) [parameters setObject:password forKey:@"password"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]) {
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
    }
    
    [self login:parameters];
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
        UITextField *alertTextField = [forgotPasswordAlert textFieldAtIndex:0];
        [alertTextField setKeyboardType:UIKeyboardTypeEmailAddress];
        [alertTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
        [alertTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [alertTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [forgotPasswordAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]){
        forgotPasswordEmail = [[alertView textFieldAtIndex:0] text];
        [self forgotPassword];
    }
}

- (void)login:(NSMutableDictionary*)parameters{
    [ProgressHUD show:@"Logging in..."];
    
    [delegate.manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success logging in: %@",responseObject);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == [c] %@", [[responseObject objectForKey:@"user"] objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user) {
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:[responseObject objectForKey:@"user"]];
        [[NSUserDefaults standardUserDefaults] setObject:user.identifier forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:user.mobileToken forKey:kUserDefaultsMobileToken];
        [[NSUserDefaults standardUserDefaults] setObject:user.company.identifier forKey:kUserDefaultsCompanyId];
        [[NSUserDefaults standardUserDefaults] setBool:user.uberAdmin.boolValue forKey:kUserDefaultsUberAdmin];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //update the delegate's logged in / logged out flag
        [delegate updateLoggedInStatus];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            delegate.currentUser = user;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadUser" object:nil];
            [UIView animateWithDuration:.3 animations:^{
                _logoImageView.transform = CGAffineTransformIdentity;
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
            } else if ([operation.responseString isEqualToString:@"Invalid token"]) {
                NSLog(@"Invalid token");
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"Something went wrong while trying to log you in." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in. Please try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        [ProgressHUD dismiss];
        [self showLoginStuff];
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

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         if (IDIOM != IPAD){
                             _loginButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight-54);
                             _emailTextField.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight/2);
                             _passwordTextField.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight/2);
                             _forgotPasswordButton.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight/2);
                             _logoImageView.transform = CGAffineTransformMakeTranslation(0, -logoY/2);
                         }
                     }
                     completion:^(BOOL finished) {
                         [backgroundTapGesture setEnabled:YES];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _loginButton.transform = CGAffineTransformIdentity;
                         _emailTextField.transform = CGAffineTransformIdentity;
                         _passwordTextField.transform = CGAffineTransformIdentity;
                         _forgotPasswordButton.transform = CGAffineTransformIdentity;
                         _logoImageView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         [backgroundTapGesture setEnabled:NO];
                     }];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if (self.emailTextField.text.length && self.passwordTextField.text.length){
        [self.loginButton setEnabled:YES];
        [self.loginButton setBackgroundColor:kBlueColor];
    } else {
        [self.loginButton setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
        self.loginButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
        [self.loginButton setEnabled:NO];
    }
    if ([text isEqualToString:@"\n"]) {
        if (textField == self.emailTextField){
            [self.passwordTextField becomeFirstResponder];
            return YES;
        } else if (self.passwordTextField.text.length && self.emailTextField.text.length) {
            [textField resignFirstResponder];
            [self loginTapped];
        }
    }
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [demoButton removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
