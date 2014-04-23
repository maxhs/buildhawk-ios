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
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHUser.h"
#import <MessageUI/MessageUI.h>
#import "UIButton+WebCache.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import "BHTabBarViewController.h"
#import "BHPeoplePickerViewController.h"
#import "BHAddCommentCell.h"
#import "BHCommentCell.h"
#import "BHPunchlistViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CTAssetsPickerController/CTAssetsPickerController.h>

static NSString *assigneePlaceholder = @"Assign";
static NSString *locationPlaceholder = @"Location";
static NSString *anotherLocationPlaceholder = @"Add Another Location...";
static NSString *itemPlaceholder = @"Describe this item...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHPunchlistItemViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
    BOOL iPhone5;
    BOOL iPad;
    BOOL completed;
    BOOL shouldUpdateCompletion;
    BOOL saveToLibrary;
    Project *savedProject;
    UIActionSheet *assigneeActionSheet;
    UIActionSheet *locationActionSheet;
    AFHTTPRequestOperationManager *manager;
    UIActionSheet *emailActionSheet;
    UIActionSheet *callActionSheet;
    UIActionSheet *textActionSheet;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *createButton;
    UIAlertView *addOtherAlertView;
    UIAlertView *addOtherSubAlertView;
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        iPhone5 = YES;
    } else {
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
        _punchlistItem = [[BHPunchlistItem alloc] init];
        _punchlistItem.photos = [NSMutableArray array];
        _punchlistItem.assignees = [NSMutableArray array];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", _project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];
    
    shouldSave = NO;
    manager = [AFHTTPRequestOperationManager manager];
    
    library = [[ALAssetsLibrary alloc]init];
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    [self addBorderTreatement:self.locationButton];
    [self addBorderTreatement:self.assigneeButton];
    
    if (_punchlistItem.identifier){
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateItem)];
        [[self navigationItem] setRightBarButtonItem:saveButton];
    } else {
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(createItem)];
        [[self navigationItem] setRightBarButtonItem:createButton];
    }
    if (_punchlistItem.completed) {
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePersonnel:) name:@"PunchlistPersonnel" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    self.itemTextView.delegate = self;
    [self.itemTextView setText:itemPlaceholder];
    [Flurry logEvent:@"Viewing punchlist item"];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
}


- (void)shrinkButton:(UIButton*)button width:(int)width height:(int)height {
    CGRect buttonRect = button.frame;
    buttonRect.size.height -= height;
    buttonRect.size.width -= width;
    [button setFrame:buttonRect];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_punchlistItem.location && _punchlistItem.location.length) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",_punchlistItem.location] forState:UIControlStateNormal];
    } else {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
    
    if (_punchlistItem.body) {
        [self.itemTextView setText:_punchlistItem.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    
    if (_punchlistItem.assignees.count) {
        id assignee = _punchlistItem.assignees.firstObject;
        if ([assignee isKindOfClass:[BHUser class]]){
            BHUser *assigneeUser = assignee;
            if (assigneeUser.fullname.length) [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assigneeUser.fullname] forState:UIControlStateNormal];
        } else if ([assignee isKindOfClass:[BHSub class]]){
            BHSub *assigneeSub = assignee;
            if (assigneeSub.name.length) [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assigneeSub.name] forState:UIControlStateNormal];
        }
    }
}

- (void)loadItem {
    [manager GET:[NSString stringWithFormat:@"%@/punchlist_items/%@",kApiBaseUrl,_punchlistItem.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success getting punchlist item: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load punchlist item: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_punchlistItem && _punchlistItem.identifier) return 2;
    else return 0;
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
        [addCommentCell.messageTextView setText:kAddCommentPlaceholder];
        addCommentTextView = addCommentCell.messageTextView;
        addCommentTextView.delegate = self;
        
        [addCommentCell.doneButton addTarget:self action:@selector(submitComment) forControlEvents:UIControlEventTouchUpInside];
        [addCommentCell.doneButton setBackgroundColor:kSelectBlueColor];
        addCommentCell.doneButton.layer.cornerRadius = 4.f;
        addCommentCell.doneButton.clipsToBounds = YES;
        doneButton = addCommentCell.doneButton;
        return addCommentCell;
    } else {
        BHCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (commentCell == nil) {
            commentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHCommentCell" owner:self options:nil] lastObject];
        }
        BHComment *comment = [_punchlistItem.comments objectAtIndex:indexPath.row];
        [commentCell.messageTextView setText:comment.body];
        if (comment.createdOnString.length){
            [commentCell.timeLabel setText:comment.createdOnString];
        } else {
            [commentCell.timeLabel setText:[commentFormatter stringFromDate:comment.createdOn]];
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
        [textView setTextColor:[UIColor darkGrayColor]];
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
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            BHComment *comment = [[BHComment alloc] init];
            comment.body = addCommentTextView.text;
            comment.createdOnString = @"Just now";
            User *user = [(BHTabBarViewController*) self.tabBarController user];
            comment.user = [[BHUser alloc] init];
            comment.user.fullname = user.fullname;
            [_punchlistItem.comments addObject:comment];
            [self.tableView reloadData];
            
            NSDictionary *commentDict = @{@"punchlist_item_id":_punchlistItem.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":comment.body};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success creating a comment for punchlist item: %@",responseObject);
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
    _punchlistItem.assignees = [info objectForKey:kpersonnel];
}

- (void)addBorderTreatement:(UIButton*)button {
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 0.5f;
    [button setBackgroundColor:kLightestGrayColor];
}

- (IBAction)completionTapped{
    shouldSave = YES;
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (!completed){
            [[[UIAlertView alloc] initWithTitle:@"Completion Photo" message:@"Can you take a photo of the completed worklist item?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
            [self.completionButton setBackgroundColor:kDarkGrayColor];
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

- (void)doneEditing {
    [self.view endEditing:YES];
    if (_punchlistItem.identifier){
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = createButton;
    }
    [UIView animateWithDuration:.25 animations:^{
        doneButton.alpha = 0.0;
    }];
}

- (IBAction)photoButtonTapped;
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

- (void)existingPhotoButtonTapped:(UIButton*)button;
{
    photoIdx = button.tag;
    [self showPhotoDetail];
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
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [vc setDelegate:self];
    [vc setAllowsEditing:YES];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.scrollView setAlpha:0.0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    BHPhoto *newPhoto = [[BHPhoto alloc] init];
    [newPhoto setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [_punchlistItem.photos addObject:newPhoto];
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
                BHPhoto *newPhoto = [[BHPhoto alloc] init];
                [newPhoto setImage:[self fixOrientation:image]];
                [_punchlistItem.photos addObject:newPhoto];
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
    if (_project.demo){
        
    } else {
        [self saveToLibrary:image];
        if (_punchlistItem.identifier){
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:@{@"id":_punchlistItem.identifier, @"photo[user_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"photo[project_id]":_project.identifier, @"photo[source]":kWorklist, @"photo[company_id]":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"save punchlist item photo response object: %@",responseObject);
                _punchlistItem = [[BHPunchlistItem alloc] initWithDictionary:[responseObject objectForKey:@"punchlist_item"]];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure posting image to API: %@",error.description);
            }];
        }
    }
}

-(void)removePhoto:(NSNotification*)notification {
    BHPhoto *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (BHPhoto *photo in _punchlistItem.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_punchlistItem.photos removeObject:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_punchlistItem.photos removeObjectAtIndex:photoIdx];
        [self redrawScrollView];
    }
}

- (void)redrawScrollView {
    self.scrollView.delegate = self;
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.showsHorizontalScrollIndicator=NO;

    float imageSize;
    float space;
    if (iPad) {
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
    for (BHPhoto *photo in _punchlistItem.photos) {
        __weak UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.scrollView addSubview:imageButton];
        [imageButton setFrame:CGRectMake(((space+imageSize)*index),4,imageSize, imageSize)];
        
        if (photo.url200.length){
            [imageButton setAlpha:0.0];
            [imageButton setImageWithURL:[NSURL URLWithString:photo.url200] forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
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
            if (iPad) {
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
    for (BHPhoto *photo in _punchlistItem.photos) {
        MWPhoto *mwPhoto;
        if (mwPhoto.image){
            mwPhoto = [MWPhoto photoWithImage:mwPhoto.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        [mwPhoto setBhphoto:photo];
        [browserPhotos addObject:mwPhoto];
    }

    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    if (_project.demo == YES) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES;
    }
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
    [assigneeActionSheet addButtonWithTitle:kUsers];
    [assigneeActionSheet addButtonWithTitle:kSubcontractors];
    [assigneeActionSheet addButtonWithTitle:kAddOther];
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
    BHPeoplePickerViewController *vc = [segue destinationViewController];
    if ([segue.identifier isEqualToString:@"PeoplePicker"]){
        [vc setUserArray:savedProject.users.array];
    } else if ([segue.identifier isEqualToString:@"SubPicker"]){
        [vc setCountNotNeeded:YES];
        [vc setSubArray:savedProject.subs.array];
    }
}

-(void)updateItem {
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [SVProgressHUD showWithStatus:@"Updating item..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                            [NSCharacterSet whitespaceCharacterSet]];
                if (strippedLocationString.length) [parameters setObject:strippedLocationString forKey:@"location"];
        }
        
        if (_punchlistItem.assignees.count){
            id assignee = _punchlistItem.assignees.firstObject;
            if ([assignee isKindOfClass:[BHUser class]]){
                BHUser *assigneeUser = assignee;
                if (assigneeUser.fullname.length) [parameters setObject:assigneeUser.fullname forKey:@"user_assignee"];
            } else if ([assignee isKindOfClass:[BHSub class]]){
                BHSub *assigneeSub = assignee;
                if (assigneeSub.name.length) [parameters setObject:assigneeSub.name forKey:@"sub_assignee"];
            }
        }
        
        [parameters setObject:_punchlistItem.identifier forKey:@"id"];
        if (self.itemTextView.text.length) [parameters setObject:self.itemTextView.text forKey:@"body"];
        if (completed){
            [parameters setObject:kCompleted forKey:@"status"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:@"Not Completed" forKey:@"status"];
        }
        
        [manager PATCH:[NSString stringWithFormat:@"%@/punchlist_items/%@", kApiBaseUrl, _punchlistItem.identifier] parameters:@{@"punchlist_item":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.navigationController popViewControllerAnimated:YES];
            [SVProgressHUD dismiss];
            //NSLog(@"Success updating punchlist item: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SVProgressHUD dismiss];
            NSLog(@"Failed to update punchlist item: %@",error.description);
        }];
    }
}

-(void)createItem {
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new worklist items for a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [SVProgressHUD showWithStatus:@"Adding item..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) [parameters setObject:strippedLocationString forKey:@"location"];
        }
        if (_punchlistItem.assignees.count){
            id assignee = _punchlistItem.assignees.firstObject;
            if ([assignee isKindOfClass:[BHUser class]]){
                BHUser *assigneeUser = assignee;
                if (assigneeUser.fullname.length) [parameters setObject:assigneeUser.fullname forKey:@"user_assignee"];
            } else if ([assignee isKindOfClass:[BHSub class]]){
                BHSub *assigneeSub = assignee;
                if (assigneeSub.name.length) [parameters setObject:assigneeSub.name forKey:@"sub_assignee"];
            }
        }
        if (self.itemTextView.text) [parameters setObject:self.itemTextView.text forKey:@"body"];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];

        [manager POST:[NSString stringWithFormat:@"%@/punchlist_items", kApiBaseUrl] parameters:@{@"punchlist_item":parameters,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [SVProgressHUD dismiss];
            BHPunchlistItem *newItem = [[BHPunchlistItem alloc] initWithDictionary:[responseObject objectForKey:@"punchlist_item"]];
            if (newItem.identifier){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:newItem.identifier forKey:@"id"];
                [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"photo[user_id]"];
                if (_project.identifier) [parameters setObject:_project.identifier forKey:@"photo[project_id]"];
                [parameters setObject:kWorklist forKey:@"photo[source]"];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId])[parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"photo[company_id]"];
                
                for (BHPhoto *photo in _punchlistItem.photos){
                    NSData *imageData = UIImageJPEGRepresentation(photo.image, 0.5);
                    //NSLog(@"New photo for new punchlist item parameters: %@",parameters);
                    [manager POST:[NSString stringWithFormat:@"%@/punchlist_items/photo",kApiBaseUrl] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
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
    for (BHUser *user in savedProject.users) {
        [callActionSheet addButtonWithTitle:user.fullname];
    }
    callActionSheet.cancelButtonIndex = [callActionSheet addButtonWithTitle:@"Cancel"];
    [callActionSheet showInView:self.view];
}

- (IBAction)placeText:(id)sender{
    textActionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to text?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
    for (BHUser *user in savedProject.users) {
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
    for (BHUser *user in savedProject.users) {
        [emailActionSheet addButtonWithTitle:user.fullname];
    }
    emailActionSheet.cancelButtonIndex = [emailActionSheet addButtonWithTitle:@"Cancel"];
    [emailActionSheet showInView:self.view];
}

- (void)call:(NSString*)phone {
    if (!iPad){
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
            for (BHUser *user in savedProject.users){
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
        for (BHUser *user in savedProject.users){
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
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kUsers]) {
        [self performSegueWithIdentifier:@"PeoplePicker" sender:nil];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kSubcontractors]) {
        [self performSegueWithIdentifier:@"SubPicker" sender:nil];
    } else if (actionSheet == assigneeActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        if (buttonIndex == assigneeActionSheet.destructiveButtonIndex){
            [_punchlistItem.assignees removeAllObjects];
            [self.assigneeButton setTitle:assigneePlaceholder forState:UIControlStateNormal];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kAddOther]){
            addOtherSubAlertView = [[UIAlertView alloc] initWithTitle:@"Add a subcontractor" message:@"Enter name:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            addOtherSubAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [addOtherSubAlertView show];
        }
    } else if (actionSheet == locationActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if (buttonTitle.length) {
            if ([buttonTitle isEqualToString:kAddOther]) {
                addOtherAlertView = [[UIAlertView alloc] initWithTitle:@"Add another location" message:@"Enter location name(s):" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
                addOtherAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [addOtherAlertView show];
            } else {
                [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",[actionSheet buttonTitleAtIndex:buttonIndex]] forState:UIControlStateNormal];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_punchlistItem && _punchlistItem.identifier && indexPath.section == 1) {
        return YES;
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
    if (_project.demo){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments on a demo project worklist item." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        BHComment *comment = [_punchlistItem.comments objectAtIndex:indexPathForDeletion.row];
        if (comment.identifier){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_punchlistItem.comments removeObject:comment];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                //NSLog(@"Failed to delete comment: %@",error.description);
            }];
        } else {
            NSLog(@"should be deleting fresh comment");
            [_punchlistItem.comments removeObject:comment];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self.locationButton setTitle:[[alertView textFieldAtIndex:0] text] forState:UIControlStateNormal];
        }
    } else if (alertView == addOtherSubAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            BHSub *newSub = [[BHSub alloc] init];
            newSub.name = [[alertView textFieldAtIndex:0] text];

            if (!_punchlistItem.assignees) {
                _punchlistItem.assignees = [NSMutableArray array];
                [_punchlistItem.assignees addObject:newSub];
            } else {
                [_punchlistItem.assignees replaceObjectAtIndex:0 withObject:newSub];
            }

            [self.assigneeButton setTitle:newSub.name forState:UIControlStateNormal];
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
    if (shouldSave && !_project.demo) {
        [[[UIAlertView alloc] initWithTitle:@"Unsaved Changes" message:@"Do you want to save your unsaved changes?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Discard", @"Save", nil] show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
