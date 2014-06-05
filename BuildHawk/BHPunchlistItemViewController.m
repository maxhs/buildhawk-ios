//
//  BHPunchlistItemViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistItemViewController.h"
#import "Constants.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "User+helper.h"
#import <MessageUI/MessageUI.h>
#import "UIButton+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import "BHTabBarViewController.h"
#import "BHPersonnelPickerViewController.h"
#import "BHAddCommentCell.h"
#import "BHCommentCell.h"
#import "BHPunchlistViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "PunchlistItem+helper.h"
#import "Comment+helper.h"
#import "BHAppDelegate.h"

static NSString *assigneePlaceholder = @"Assign item";
static NSString *locationPlaceholder = @"Select location";
static NSString *anotherLocationPlaceholder = @"Add Another Location...";
static NSString *itemPlaceholder = @"Describe this item...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHPunchlistItemViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
    BOOL iPhone5;
    BOOL saveToLibrary;
    UIActionSheet *assigneeActionSheet;
    UIActionSheet *locationActionSheet;
    AFHTTPRequestOperationManager *manager;
    UIActionSheet *emailActionSheet;
    UIActionSheet *callActionSheet;
    UIActionSheet *textActionSheet;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    UIAlertView *addOtherAlertView;
    int photoIdx;
    NSMutableArray *browserPhotos;
    UITextView *addCommentTextView;
    NSDateFormatter *commentFormatter;
    UIButton *doneButton;
    ALAssetsLibrary *library;
    BOOL shouldSave;
    NSIndexPath *indexPathForDeletion;
}
- (IBAction)assigneeButtonTapped;
- (IBAction)locationButtonTapped;
- (IBAction)placeText:(id)sender;
- (IBAction)placeCall:(id)sender;
- (IBAction)sendEmail:(id)sender;
@end

@implementation BHPunchlistItemViewController

@synthesize punchlistItem = _punchlistItem;
@synthesize locationSet;
@synthesize project = _project;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else if (IDIOM != IPAD) {
        iPhone5 = NO;
        self.emailButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.callButton.transform = CGAffineTransformMakeTranslation(0, -88);
        self.textButton.transform = CGAffineTransformMakeTranslation(0, -88);
       
        [self shrinkButton:self.photoButton width:16 height:16];
        [self shrinkButton:self.libraryButton width:16 height:16];
        [self shrinkButton:self.locationButton width:0 height:20];
        [self shrinkButton:self.assigneeButton width:0 height:20];
        [self shrinkButton:self.completionButton width:0 height:30];
        CGRect itemTextRect = self.itemTextView.frame;
        itemTextRect.size.height = self.completionButton.frame.size.height;
        [self.itemTextView setFrame:itemTextRect];
        
        self.photoButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.libraryButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
        self.scrollView.transform = CGAffineTransformMakeTranslation(0, -32);
    }
    
    if (_punchlistItem.identifier){
        [self redrawScrollView];
    } else {
        _punchlistItem = [PunchlistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    shouldSave = NO;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    
    library = [[ALAssetsLibrary alloc]init];
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    if ([_punchlistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(createItem)];
        [self.navigationItem setRightBarButtonItem:createButton];
    } else {
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateItem)];
        [self.navigationItem setRightBarButtonItem:saveButton];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"PunchlistPersonnel" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    self.itemTextView.delegate = self;
    [self.itemTextView setText:itemPlaceholder];
    [Flurry logEvent:@"Viewing punchlist item"];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [self drawItem];
}

- (void)drawItem {
    if (_punchlistItem.body) {
        [self.itemTextView setText:_punchlistItem.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    if ([_punchlistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
    } else {
        [self.completionButton setBackgroundColor:[UIColor whiteColor]];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
    }
    
    if (_punchlistItem.location && _punchlistItem.location.length) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",_punchlistItem.location] forState:UIControlStateNormal];
    } else {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
    if (_punchlistItem.assignees.count) {
        id assignee = _punchlistItem.assignees.firstObject;
        if ([assignee isKindOfClass:[User class]]){
            User *assigneeUser = assignee;
            if (assigneeUser.fullname.length) [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assigneeUser.fullname] forState:UIControlStateNormal];
        }
    }
}

- (void)shrinkButton:(UIButton*)button width:(int)width height:(int)height {
    CGRect buttonRect = button.frame;
    buttonRect.size.height -= height;
    buttonRect.size.width -= width;
    [button setFrame:buttonRect];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)loadItem {
    [manager GET:[NSString stringWithFormat:@"%@/punchlist_items/%@",kApiBaseUrl,_punchlistItem.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting punchlist item: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load punchlist item: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_punchlistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return 0;
    }
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return _punchlistItem.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        BHAddCommentCell *addCommentCell = [tableView dequeueReusableCellWithIdentifier:@"AddCommentCell"];
        if (addCommentCell == nil) {
            addCommentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHAddCommentCell" owner:self options:nil] lastObject];
        }
        [addCommentCell configure];
        
        addCommentTextView = addCommentCell.messageTextView;
        addCommentTextView.delegate = self;
        [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
        doneButton = addCommentCell.doneButton;
        return addCommentCell;
    } else {
        BHCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (commentCell == nil) {
            commentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHCommentCell" owner:self options:nil] lastObject];
        }
        Comment *comment = [_punchlistItem.comments objectAtIndex:indexPath.row];
        [commentCell.messageTextView setText:comment.body];
        if (comment.createdOnString.length){
            [commentCell.timeLabel setText:comment.createdOnString];
        } else {
            [commentCell.timeLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
        }
        [commentCell.nameLabel setText:comment.user.fullname];
        return commentCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    shouldSave = YES;
    if ([textView.text isEqualToString:kAddCommentPlaceholder] || [textView.text isEqualToString:itemPlaceholder]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 1.0;
    }];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    [cancelButton setTitle:@"Cancel"];
    [[self navigationItem] setRightBarButtonItem:cancelButton];
    if (textView == addCommentTextView){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}


-(void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == addCommentTextView){
        if (textView.text.length) {
            addCommentTextView = textView;
        } else {
            shouldSave = NO;
            [textView setText:kAddCommentPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    } else {
        if (textView.text.length) {
            _punchlistItem.body = textView.text;
        } else {
            shouldSave = NO;
            [textView setText:itemPlaceholder];
            [textView setTextColor:[UIColor lightGrayColor]];
        }
    }
    [self doneEditing];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)thisText {
    if ([thisText isEqualToString:@"\n"]) {
        if (textView == addCommentTextView && textView.text.length) {
            [self submitComment];
            [self doneEditing];
        }
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)submitComment {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            comment.body = addCommentTextView.text;
            comment.createdOnString = @"Just now";
            User *currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
            comment.user = currentUser;
            //[_punchlistItem addComment:comment];
            [self.tableView reloadData];
            
            NSDictionary *commentDict = @{@"punchlist_item_id":_punchlistItem.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":comment.body};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success creating a comment for punchlist item: %@",responseObject);
                [_punchlistItem populateFromDictionary:responseObject];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                [addCommentTextView setTextColor:[UIColor lightGrayColor]];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure creating a comment for punchlist item: %@",error.description);
            }];
        }
    }
    [self doneEditing];
}

- (void)updatePersonnel:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    User *user = [info objectForKey:kpersonnel];
    NSOrderedSet *assigneeSet = [NSOrderedSet orderedSetWithObject:user];
    _punchlistItem.assignees = assigneeSet;
    [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",user.fullname] forState:UIControlStateNormal];
}

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([_punchlistItem.completed isEqualToNumber:[NSNumber numberWithBool:NO]]){
            [_completionButton setBackgroundColor:kDarkGrayColor];
            [_completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Completed" forState:UIControlStateNormal];
            _punchlistItem.completed = [NSNumber numberWithBool:YES];
        } else {
            [_completionButton setBackgroundColor:[UIColor whiteColor]];
            [_completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
            _punchlistItem.completed = [NSNumber numberWithBool:NO];
        }
    } completion:^(BOOL finished) {
        if ([_punchlistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [[[UIAlertView alloc] initWithTitle:@"Completion Photo" message:@"Can you take a photo of the completed worklist item?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        }
        shouldSave = YES;
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if ([_punchlistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        self.navigationItem.rightBarButtonItem = createButton;
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 0.0;
    }];
}

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    photoIdx = button.tag;
    [self showPhotoDetail];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if (picker.selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:nil message:@"We're unable to select more than 10 photos per batch." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
    // Allow 10 assets to be picked
    return (picker.selectedAssets.count < 10);
}


- (IBAction)choosePhoto {
    saveToLibrary = NO;
    CTAssetsPickerController *controller = [[CTAssetsPickerController alloc] init];
    controller.delegate = self;
    //controller.maximumNumberOfSelections = 4;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (IBAction)takePhoto {
    saveToLibrary = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setModalPresentationStyle:UIModalPresentationCurrentContext];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to find a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.scrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [_punchlistItem addPhoto:newPhoto];
    [self redrawScrollView];
    [self saveImage:[self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]]];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    
    [self dismissViewControllerAnimated:YES completion:^{
        for (id asset in assets) {
            if (asset != nil) {
                ALAssetRepresentation* representation = [asset defaultRepresentation];
                
                // Retrieve the image orientation from the ALAsset
                UIImageOrientation orientation = UIImageOrientationUp;
                NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                if (orientationValue != nil) {
                    orientation = [orientationValue intValue];
                }
                
                CGFloat scale  = 1;
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:scale orientation:orientation];
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:[self fixOrientation:image]];
                [_punchlistItem addPhoto:newPhoto];
                [self saveImage:newPhoto.image];
            }
        }
        [self redrawScrollView];
    }];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)saveToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:0.5 orientation:UIImageOrientationUp];
        library = [[ALAssetsLibrary alloc]init];
        [library addAssetsGroupAlbumWithName:albumName
                                 resultBlock:^(ALAssetsGroup *group) {
                                     
                                 }
                                failureBlock:^(NSError *error) {
                                    NSLog(@"error adding album");
                                }];
        
        __block ALAssetsGroup* groupToAddTo;
        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                   if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                       
                                       groupToAddTo = group;
                                   }
                               }
                             failureBlock:^(NSError* error) {
                                 NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                             }];
        
        [library writeImageToSavedPhotosAlbum:imageToSave.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error.code == 0) {
                // try to get the asset
                [library assetForURL:assetURL
                         resultBlock:^(ALAsset *asset) {
                             // assign the photo to the album
                             [groupToAddTo addAsset:asset];
                         }
                        failureBlock:^(NSError* error) {
                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                        }];
            }
            else {
                NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
            }
        }];
    }
}

- (void)saveImage:(UIImage*)image {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        
    } else {
        [self saveToLibrary:image];
        if (![_punchlistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:@{@"photo":@{@"punchlist_item_id":_punchlistItem.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"project_id":_project.identifier, @"source":kWorklist, @"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]}} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"save punchlist item photo response object: %@",responseObject);
                [_punchlistItem populateFromDictionary:[responseObject objectForKey:@"punchlist_item"]];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure posting image to API: %@",error.description);
            }];
        }
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in _punchlistItem.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_punchlistItem removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_punchlistItem removePhoto:photoToRemove];
        [self redrawScrollView];
    }
}

- (void)redrawScrollView {
    self.scrollView.delegate = self;
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.showsHorizontalScrollIndicator=NO;

    float imageSize;
    float space;
    if (IDIOM == IPAD) {
        imageSize = 80;
        space = 4;
    } else if (iPhone5){
        imageSize = 56.0;
        space = 4.0;
    } else {
        imageSize = 40;
        space = 3;
    }

    int index = 0;
    for (Photo *photo in _punchlistItem.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.scrollView addSubview:imageButton];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        
        if (photo.urlSmall.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                [UIView animateWithDuration:.25 animations:^{
                    [imageButton setAlpha:1.0];
                }];
            }];
        } else if (photo.image) {
            [imageButton setImage:photo.image forState:UIControlStateNormal];
            [UIView animateWithDuration:.25 animations:^{
                [imageButton setAlpha:1.0];
            }];
        }
        imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageButton.imageView.clipsToBounds = YES;
        imageButton.imageView.layer.cornerRadius = 2.0;
        [imageButton.imageView setBackgroundColor:[UIColor clearColor]];
        [imageButton.imageView.layer setBackgroundColor:[UIColor whiteColor].CGColor];
        imageButton.imageView.layer.shouldRasterize = YES;
        imageButton.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [imageButton setTag:[_punchlistItem.photos indexOfObject:photo]];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        index++;
    }
    
    if (_punchlistItem.photos.count > 0){
        [self.view bringSubviewToFront:self.scrollView];
        [self.scrollView setContentSize:CGSizeMake(((space*(index+1))+(imageSize*(index+1))),40)];
        if (self.scrollView.isHidden) [self.scrollView setHidden:NO];
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (IDIOM == IPAD) {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-302, 0);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-302, 0);
            } else if (iPhone5) {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-96, 0);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-96, 0);
            } else {
                self.photoButton.transform = CGAffineTransformMakeTranslation(-96, -32);
                self.libraryButton.transform = CGAffineTransformMakeTranslation(-86, -32);
            }
        } completion:^(BOOL finished) {
            
        }];
    }
    
    [UIView animateWithDuration:.3 delay:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.scrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        self.scrollView.layer.shouldRasterize = YES;
        self.scrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }];

}

- (void)showPhotoDetail {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _punchlistItem.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
    }

    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;

    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:photoIdx];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

-(IBAction)assigneeButtonTapped{
    shouldSave = YES;
    assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assign this worklist item:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [assigneeActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@ Personnel",_project.company.name]];
    [assigneeActionSheet addButtonWithTitle:kSubcontractors];
    if (_punchlistItem.assignees.count) assigneeActionSheet.destructiveButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Remove assignee"];
    assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
    [assigneeActionSheet showInView:self.view];
}

-(IBAction)locationButtonTapped{
    shouldSave = YES;
    locationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Location" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *location in locationSet.allObjects) {
        [locationActionSheet addButtonWithTitle:location];
    }
    [locationActionSheet addButtonWithTitle:kAddOther];
    if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder])locationActionSheet.destructiveButtonIndex = [locationActionSheet addButtonWithTitle:@"Remove location"];
    locationActionSheet.cancelButtonIndex = [locationActionSheet addButtonWithTitle:@"Cancel"];
    [locationActionSheet showInView:self.view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    BHPersonnelPickerViewController *vc = [segue destinationViewController];
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        [vc setUsers:_project.users.mutableCopy];
        [vc setCountNotNeeded:YES];
    } else if ([segue.identifier isEqualToString:@"SubcontractorPicker"]){
        [vc setCompany:_project.company];
        [vc setWorklistMode:YES];
        [vc setCountNotNeeded:YES];
    }
}

-(void)updateItem {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [ProgressHUD show:@"Updating item..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) {
                [parameters setObject:strippedLocationString forKey:@"location"];
            }
        }
        
        if (_punchlistItem.assignees.count){
            User *assigneeUser = _punchlistItem.assignees.firstObject;
            if (assigneeUser.fullname.length) [parameters setObject:assigneeUser.fullname forKey:@"user_assignee"];
        }
        
        [parameters setObject:_punchlistItem.identifier forKey:@"id"];
        
        if (self.itemTextView.text.length) {
            [parameters setObject:self.itemTextView.text forKey:@"body"];
        }
        if ([_punchlistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"completed"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"completed"];
        }
        
        [manager PATCH:[NSString stringWithFormat:@"%@/punchlist_items/%@", kApiBaseUrl, _punchlistItem.identifier] parameters:@{@"punchlist_item":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.navigationController popViewControllerAnimated:YES];
            [ProgressHUD dismiss];
            NSLog(@"Success updating punchlist item: %@",responseObject);
            [_punchlistItem populateFromDictionary:[responseObject objectForKey:@"punchlist_item"]];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to update punchlist item: %@",error.description);
        }];
    }
}

-(void)createItem {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new worklist items for a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [ProgressHUD show:@"Adding item..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) {
                [parameters setObject:strippedLocationString forKey:@"location"];
                _punchlistItem.location = strippedLocationString;
            }
        } else {
            _punchlistItem.location = nil;
        }
        
        if (_punchlistItem.assignees.count){
            User *assigneeUser = _punchlistItem.assignees.firstObject;
            if (assigneeUser.fullname.length) [parameters setObject:assigneeUser.fullname forKey:@"user_assignee"];
        }
        
        if (self.itemTextView.text) {
            [parameters setObject:self.itemTextView.text forKey:@"body"];
            [_punchlistItem setBody:self.itemTextView.text];
        }
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];

        [manager POST:[NSString stringWithFormat:@"%@/punchlist_items", kApiBaseUrl] parameters:@{@"punchlist_item":parameters,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [ProgressHUD dismiss];
            PunchlistItem *newItem = [PunchlistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [newItem populateFromDictionary:[responseObject objectForKey:@"punchlist_item"]];
            if (newItem.identifier){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:newItem.identifier forKey:@"punchlist_item_id"];
                [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
                if (_project.identifier) [parameters setObject:_project.identifier forKey:@"project_id"];
                [parameters setObject:kWorklist forKey:@"source"];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId])[parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
                
                for (Photo *photo in _punchlistItem.photos){
                    NSData *imageData = UIImageJPEGRepresentation(photo.image, 0.5);
                    //NSLog(@"New photo for new punchlist item parameters: %@",parameters);
                    [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:@{@"photo":parameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //NSLog(@"save punchlist item photo response object: %@",responseObject);
                        //_punchlistItem = [responseObject objectForKey:@"punchlist_item"];
                        //[self.tableView reloadData];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"failure posting image to API: %@",error.description);
                    }];
                }
            }
            [self.navigationController popViewControllerAnimated:YES];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a punchlist item: %@",error.description);
        }];
    }
}

- (IBAction)placeCall:(id)sender{
    callActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to call?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [callActionSheet addButtonWithTitle:user.fullname];
    }
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showInView:self.view];
}

- (IBAction)placeText:(id)sender{
    textActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to text?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [textActionSheet addButtonWithTitle:user.fullname];
    }
    textActionSheet.cancelButtonIndex = [textActionSheet addButtonWithTitle:@"Cancel"];
    [textActionSheet showInView:self.view];
}

- (void)text:(NSString*)phone {
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    if ([MFMessageComposeViewController canSendText]){
        viewController.messageComposeDelegate = self;
        [viewController setRecipients:@[phone]];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    }
}

- (IBAction)sendEmail:(id)sender {
    emailActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to email?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (User *user in _project.users) {
        [emailActionSheet addButtonWithTitle:user.fullname];
    }
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showInView:self.view];
}

- (void)call:(NSString*)phone {
    if (IDIOM != IPAD){
        NSString *phoneNumber = [@"tel://" stringByAppendingString:phone];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (actionSheet == callActionSheet || actionSheet == textActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (![buttonTitle isEqualToString:@"Cancel"]) {
            for (User *user in _project.users){
                if ([user.fullname isEqualToString:buttonTitle] && user.phone) {
                    if (actionSheet == callActionSheet){
                        [self call:user.phone];
                    } else {
                        [self text:user.phone];
                    }
                    return;
                }
            }
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have a phone number on file with BuildHawk" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        
    } else if (actionSheet == emailActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            [emailActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            return;
        }
        for (User *user in _project.users){
            if ([user.fullname isEqualToString:buttonTitle]) {
                [self sendMail:user.email];
                return;
            }
        }
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"That user may not have an email address on file with BuildHawk" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose Existing Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            [self choosePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take Photo"]) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self takePhoto];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove location"]) {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
        _punchlistItem.location = nil;
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:[NSString stringWithFormat:@"%@ Personnel",_project.company.name]]) {
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSubcontractors]) {
        [self performSegueWithIdentifier:@"SubcontractorPicker" sender:nil];
    } else if (actionSheet == assigneeActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        if (buttonIndex == assigneeActionSheet.destructiveButtonIndex){
            _punchlistItem.assignees = nil;
            [self.assigneeButton setTitle:assigneePlaceholder forState:UIControlStateNormal];
        }
    } else if (actionSheet == locationActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (buttonTitle.length) {
            if ([buttonTitle isEqualToString:kAddOther]) {
                addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add another location" message:@"Enter location name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
                addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [addOtherAlertView show];
            } else {
                [_punchlistItem setLocation:buttonTitle];
                [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",buttonTitle] forState:UIControlStateNormal];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        Comment *comment = _punchlistItem.comments[indexPath.row];
        if ([comment.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        indexPathForDeletion = indexPath;
        [[[UIAlertView alloc] initWithTitle:@"Please confirm" message:@"Are you sure you want to delete this comment?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Delete", nil] show];
    }
}

- (void)deleteComment {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments on a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = [_punchlistItem.comments objectAtIndex:indexPathForDeletion.row];
        if (comment.identifier != [NSNumber numberWithInt:0]){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_punchlistItem removeComment:comment];
                [comment MR_deleteEntity];
                shouldSave = NO;
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete comment: %@",error.description);
            }];
        } else {
            [_punchlistItem removeComment:comment];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self.locationButton setTitle:[[alertView textFieldAtIndex:0] text] forState:UIControlStateNormal];
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        if (_punchlistItem.identifier && _punchlistItem.identifier){
            [self updateItem];
        } else {
            [self createItem];
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Discard"]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]){
        [self takePhoto];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]){
        [self deleteComment];
    }
}

- (void)back {
    if (shouldSave && [_project.demo isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self saveContext];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during punchlist item save? %hhd %@",success, error);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
