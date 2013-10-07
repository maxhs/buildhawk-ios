//
//  BHPunchlistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistItemViewController.h"
#import "Constants.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <RestKit/RestKit.h>
#import "BHUser.h"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHPunchlistItemViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate> {
    BOOL iPhone5;
    BOOL completed;
    BOOL shouldUpdateCompletion;
    AFHTTPClient *punchlistClient;
}
-(IBAction)assigneeButtonTapped;
-(IBAction)locationButtonTapped;
@end

@implementation BHPunchlistItemViewController

@synthesize punchlistItem, photos, assignees;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
        [self shrinkButton:self.photoButton withAmount:20];
        [self shrinkButton:self.photoLabelButton withAmount:20];
        [self shrinkButton:self.locationButton withAmount:20];
        [self shrinkButton:self.assigneeButton withAmount:20];
        [self shrinkButton:self.completionButton withAmount:30];
        CGRect textRect = self.itemTextView.frame;
        textRect.size.height -= 44;
        [self.itemTextView setFrame:textRect];
        self.photoButton.transform = CGAffineTransformMakeTranslation(0, -30);
        self.photoLabelButton.transform = CGAffineTransformMakeTranslation(0, -30);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
    }
    if (!self.photos) self.photos = [NSMutableArray array];
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self addBorderTreatement:self.photoButton];
    [self.photoButton addTarget:self action:@selector(photoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addBorderTreatement:self.locationButton];
    [self addBorderTreatement:self.assigneeButton];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    if (self.punchlistItem.completedOn) {
        completed = YES;
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
    } else {
        completed = NO;
        [self.completionButton setBackgroundColor:kLightestGrayColor];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
    }
    shouldUpdateCompletion = NO;
    punchlistClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.buildhawk.com/api/v1"]];
    [punchlistClient setDefaultHeader:@"Accept" value:@"application/json"];
    NSLog(@"completed? %@",self.punchlistItem.completedOn);
    [punchlistClient setDefaultHeader:@"authtoken" value:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAuthToken]];
    [punchlistClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.punchlistItem.location) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",self.punchlistItem.location] forState:UIControlStateNormal];
        [self.locationButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
    
    if (self.punchlistItem.name) {
        [self.itemTextView setText:self.punchlistItem.name];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    
    if (self.punchlistItem.assignees.count) {
        NSLog(@"There are assignees");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.itemTextView becomeFirstResponder];
}

- (void)save {
    [self updateItem];
    [SVProgressHUD showWithStatus:@"Saving..."];
}

- (void)addBorderTreatement:(UIButton*)button {
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 0.5f;
    [button setBackgroundColor:kLightestGrayColor];
}

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (!completed){
            [self.completionButton setBackgroundColor:[UIColor colorWithWhite:.15 alpha:1]];
            [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
        } else {
            [self.completionButton setBackgroundColor:kLightestGrayColor];
            [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
        }
    } completion:^(BOOL finished) {
        completed = !completed;
        shouldUpdateCompletion = YES;
    }];
}

- (void)shrinkButton:(UIButton*)button withAmount:(int)amount {
    CGRect buttonRect = button.frame;
    buttonRect.size.height -= amount;
    [button setFrame:buttonRect];
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (IBAction)photoButtonTapped;
{
    UIActionSheet *actionSheet = nil;
    //[self doneEditing];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", @"Take Photo", nil];
        [actionSheet showInView:self.view];
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:photos.count ? @"Remove Last Photo" : nil
                                         otherButtonTitles:@"Choose Existing Photo", nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove Last Photo"]) {
        [self removePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Will Miller"]) {
        [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: Will Miller"] forState:UIControlStateNormal];
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
    [self.scrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (iPhone5){
        if (self.photos.count == 0){
            [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.photoLabelButton.transform = CGAffineTransformMakeTranslation(-98, 0);
                [self.scrollView setHidden:NO];
            } completion:^(BOOL finished) {
                
            }];
        }
    }
    [self.photos addObject:[info objectForKey:UIImagePickerControllerEditedImage]];
    if (iPhone5) [self redrawScrollView];
    
    if (self.photos.count == 1){
         [self.photoLabelButton setTitle:@"1 photo added" forState:UIControlStateNormal];
    } else {
        [self.photoLabelButton setTitle:[NSString stringWithFormat:@"%i photos added", self.photos.count] forState:UIControlStateNormal];
    }
    
}

-(void)removePhoto {
    [self.photos removeLastObject];
    if (self.photos.count == 0){
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.photoLabelButton.transform = CGAffineTransformIdentity;
            [self.scrollView setAlpha:0.0];
            [self.photoLabelButton setTitle:@"Add Photo" forState:UIControlStateNormal];
        } completion:^(BOOL finished) {
            [self.scrollView setHidden:YES];
        }];
    } else {
        [UIView animateWithDuration:.35 delay:.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (self.photos.count == 1){
                [self.photoLabelButton setTitle:@"1 photo added" forState:UIControlStateNormal];
            } else {
                [self.photoLabelButton setTitle:[NSString stringWithFormat:@"%i photos added", self.photos.count] forState:UIControlStateNormal];
            }
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)redrawScrollView {
    self.scrollView.delegate = self;
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.showsHorizontalScrollIndicator=NO;

    float imageSize = 56.0;
    float space = 6.0;
    int index = 0;
    
    for (UIImage *image in self.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [imageButton setImage:image forState:UIControlStateNormal];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        [self.scrollView addSubview:imageButton];
        index++;
    }
    
    [self.view bringSubviewToFront:self.scrollView];
    [self.scrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
    if (self.scrollView.isHidden) [self.scrollView setHidden:NO];
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.scrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        self.scrollView.layer.shouldRasterize = YES;
        self.scrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];
}

-(IBAction)assigneeButtonTapped{
    UIActionSheet *assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assign this worklist item" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove assignee" otherButtonTitles:@"Will Miller", nil];
    [assigneeActionSheet showFromTabBar:self.tabBarController.tabBar];
    
}

-(IBAction)locationButtonTapped{
    
}

-(AFJSONRequestOperation*)updateItem {
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to update punchlist item: %@",error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        if (completed && shouldUpdateCompletion) [self sendComplete];
        else if (shouldUpdateCompletion) [self uncomplete];
        else [SVProgressHUD dismiss];
        [self.navigationController popViewControllerAnimated:YES];
        NSLog(@"Success updating punchlist item: %@",responseObject);
    };
    
    //temporary code for updating punchlist item
    NSDictionary *parameters = @{@"name":self.itemTextView.text,@"location":[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""]};
    NSMutableURLRequest *request = [punchlistClient requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"punchlist/%@",self.punchlistItem.identifier] parameters:parameters];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[punchlistClient HTTPRequestOperationWithRequest:request
                                                                                                    success:opSuccess
                                                                                                    failure:opFailure];
    [op start];
    return op;
}

-(AFJSONRequestOperation*)sendComplete {
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to mark punchlist item as complete: %@",error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [SVProgressHUD dismiss];
        NSLog(@"Success completing punchlist item: %@",responseObject);
    };
    NSDictionary *parameters = @{kcompleted:@{@"user":@{@"_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}}};
    NSMutableURLRequest *request = [punchlistClient requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"punchlist/complete/%@",self.punchlistItem.identifier] parameters:parameters];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[punchlistClient HTTPRequestOperationWithRequest:request
                                                                                                  success:opSuccess
                                                                                                  failure:opFailure];
    [op start];
    return op;
}

-(AFJSONRequestOperation*)uncomplete {
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to mark punchlist item as NOT complete: %@",error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [SVProgressHUD dismiss];
        NSLog(@"Success UNCOMPLETING a punchlist item: %@",responseObject);
    };
    NSDictionary *parameters = @{kcompleted:@{@"user":@{@"_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}}};
    NSMutableURLRequest *request = [punchlistClient requestWithMethod:@"PUT" path:[NSString stringWithFormat:@"punchlist/uncomplete/%@",self.punchlistItem.identifier] parameters:parameters];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[punchlistClient HTTPRequestOperationWithRequest:request
                                                                                                    success:opSuccess
                                                                                                    failure:opFailure];
    [op start];
    return op;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
