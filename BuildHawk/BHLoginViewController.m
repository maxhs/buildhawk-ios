//
//  BHLoginViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHLoginViewController.h"
#import "BHUser.h"
#import <RestKit/RestKit.h>
#import "BHAppDelegate.h"
#import "BHMenuViewController.h"
#import "BHDashboardViewController.h"
#import "Constants.h"
#import "SVProgressHUD.h"

@interface BHLoginViewController () <UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *logoContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
-(IBAction)login;

@end

@implementation BHLoginViewController

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
}

- (IBAction)login{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[BHUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"email", @"password", @"deviceTokens",@"lname",@"fullname",@"fname",@"timestamps", @"photo"]];
    [userMapping addAttributeMappingsFromDictionary:@{@"_id":@"identifier"}];

    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *userDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"login" keyPath:nil statusCodes:statusCodes];
    
    RKObjectMapping *requestMapping = [RKObjectMapping requestMapping]; // objectClass == NSMutableDictionary
    [requestMapping addAttributeMappingsFromArray:@[@"email", @"password"]];
    
    // For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
    // under the 'article' key path
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[BHUser class] rootKeyPath:@"user" method:RKRequestMethodAny];
    
    [manager addRequestDescriptor:requestDescriptor];
    [manager addResponseDescriptor:userDescriptor];
    
    BHUser *user = [BHUser new];
    user.email = self.emailTextField.text;
    user.password = self.passwordTextField.text;
    [SVProgressHUD showWithStatus:@"Logging in..."];
    // POST to create
    [manager postObject:user path:@"login" parameters:@{@"email":self.emailTextField.text, @"password":self.passwordTextField.text} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"mapping result: %@",mappingResult);
        BHUser *loggedInUser = [mappingResult firstObject];
        NSLog(@"lname: %@",loggedInUser.lname);
        NSLog(@"fname: %@",loggedInUser.fname);
        NSLog(@"timestamps: %@",loggedInUser.timestamps);
        NSLog(@"id: %@",loggedInUser.identifier);
        NSLog(@"photo array: %@",loggedInUser.photo);
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.identifier forKey:kUserDefaultsId];
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.email forKey:kUserDefaultsEmail];
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.fname forKey:kUserDefaultsFirstName];
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.lname forKey:kUserDefaultsLastName];
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.fullname forKey:kUserDefaultsFullName];
        [[NSUserDefaults standardUserDefaults] setObject:loggedInUser.password forKey:kUserDefaultsPassword];
        [[NSUserDefaults standardUserDefaults] setObject:[[loggedInUser.photo valueForKeyPath:@"urls.100x100"] objectAtIndex:0] forKey:kUserDefaultsPhotoUrl100];
        NSLog(@"user photo default?: %@", [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPhotoUrl100]);
        
        [UIView animateWithDuration:.3 animations:^{
            self.loginContainerView.transform = CGAffineTransformIdentity;
            self.logoContainerView.transform = CGAffineTransformIdentity;
            [self.view endEditing:YES];
            [self performSegueWithIdentifier:@"LoginSuccessful" sender:self];
        } completion:^(BOOL finished) {
            [SVProgressHUD dismiss];
        }];
        
    
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"Failure logging in: %@",error.localizedRecoverySuggestion);
        if ([error.localizedRecoverySuggestion isEqualToString:@"[{\"email\":\"Please enter a valid email.\"}]"]) {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Your email was not formatted correctly. Please try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else if ([error.localizedRecoverySuggestion isEqualToString:@"[{\"password\":\"Please use a valid password.\"}]"]) {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Your password was incorrect. Please try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong with your login. Please try again soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.loginContainerView.transform = CGAffineTransformMakeTranslation(0, -220);
        self.logoContainerView.transform = CGAffineTransformMakeTranslation(0, -180);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (self.passwordTextField.text.length && self.emailTextField.text.length) {
            [self login];
        }
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
