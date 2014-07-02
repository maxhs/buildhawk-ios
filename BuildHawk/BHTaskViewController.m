//
//  BHTaskViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/10/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHTaskViewController.h"
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
#import "BHTasksViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "WorklistItem+helper.h"
#import "Worklist+helper.h"
#import "Comment+helper.h"
#import "BHAppDelegate.h"
#import "BHActivityCell.h"

static NSString *assigneePlaceholder = @"Assign task";
static NSString *locationPlaceholder = @"Select location";
static NSString *anotherLocationPlaceholder = @"Add Another Location...";
static NSString *itemPlaceholder = @"Describe this task...";
typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHTaskViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MWPhotoBrowserDelegate, CTAssetsPickerControllerDelegate> {
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

@implementation BHTaskViewController

@synthesize worklistItem = _worklistItem;
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
        [_itemTextView setFrame:itemTextRect];
        
        self.photoButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.libraryButton.transform = CGAffineTransformMakeTranslation(0, -34);
        self.locationButton.transform = CGAffineTransformMakeTranslation(0, -50);
        self.assigneeButton.transform = CGAffineTransformMakeTranslation(0, -70);
        self.scrollView.transform = CGAffineTransformMakeTranslation(0, -32);
    }
    
    if (_worklistItem.identifier){
        [self redrawScrollView];
    } else {
        _worklistItem = [WorklistItem MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    shouldSave = NO;
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    
    library = [[ALAssetsLibrary alloc]init];
	[self.completionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    commentFormatter = [[NSDateFormatter alloc] init];
    [commentFormatter setDateStyle:NSDateFormatterShortStyle];
    [commentFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    if ([_worklistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        createButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(createItem)];
        [self.navigationItem setRightBarButtonItem:createButton];
    } else {
        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(updateItem)];
        [self.navigationItem setRightBarButtonItem:saveButton];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assignTask:) name:@"AssignTask" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    self.itemTextView.delegate = self;
    [self.itemTextView setText:itemPlaceholder];
    [Flurry logEvent:@"Viewing task"];
    
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [self drawItem];
}

- (void)drawItem {
    if (_worklistItem.body.length) {
        [self.itemTextView setText:_worklistItem.body];
    } else {
        [self.itemTextView setTextColor:[UIColor lightGrayColor]];
    }
    if ([_worklistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        [self.completionButton setBackgroundColor:kDarkGrayColor];
        [self.completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Completed" forState:UIControlStateNormal];
    } else {
        [self.completionButton setBackgroundColor:[UIColor whiteColor]];
        [self.completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
    }
    
    if (_worklistItem.location && _worklistItem.location.length) {
        [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",_worklistItem.location] forState:UIControlStateNormal];
    } else {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
    }
    if (_worklistItem.assignees.count) {
        id assignee = _worklistItem.assignees.firstObject;
        if ([assignee isKindOfClass:[User class]]){
            User *assigneeUser = assignee;
            if (assigneeUser.fullname.length){
                [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assigneeUser.fullname] forState:UIControlStateNormal];
            } else if (assigneeUser.firstName.length){
                [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",assigneeUser.firstName] forState:UIControlStateNormal];
            }
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
    [manager GET:[NSString stringWithFormat:@"%@/worklist_items/%@",kApiBaseUrl,_worklistItem.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"success getting task: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load task: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_worklistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
        return 0;
    }
    else return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else if (section == 1) return _worklistItem.comments.count;
    else return _worklistItem.activities.count;
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
    } else if (indexPath.section == 1) {
        BHCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        if (commentCell == nil) {
            commentCell = [[[NSBundle mainBundle] loadNibNamed:@"BHCommentCell" owner:self options:nil] lastObject];
        }
        Comment *comment = [_worklistItem.comments objectAtIndex:indexPath.row];
        [commentCell.messageTextView setText:comment.body];
        if (comment.createdOnString.length){
            [commentCell.timeLabel setText:comment.createdOnString];
        } else {
            [commentCell.timeLabel setText:[commentFormatter stringFromDate:comment.createdAt]];
        }
        [commentCell.nameLabel setText:comment.user.fullname];
        return commentCell;
    } else {
        BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
        }
        Activity *activity = [_worklistItem.activities objectAtIndex:indexPath.row];
        [cell.timestampLabel setText:[commentFormatter stringFromDate:activity.createdDate]];
        return cell;
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
            _worklistItem.body = textView.text;
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
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to submit comments for a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        if (addCommentTextView.text.length) {
            Comment *comment = [Comment MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            comment.body = addCommentTextView.text;
            comment.createdOnString = @"Just now";
            User *currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
            comment.user = currentUser;
            //[_worklistItem addComment:comment];
            [self.tableView reloadData];
            
            NSDictionary *commentDict = @{@"worklist_item_id":_worklistItem.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId],@"body":comment.body};
            [manager POST:[NSString stringWithFormat:@"%@/comments",kApiBaseUrl] parameters:@{@"comment":commentDict} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"success creating a comment for task: %@",responseObject);
                [_worklistItem populateFromDictionary:responseObject];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                [addCommentTextView setTextColor:[UIColor lightGrayColor]];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure creating a comment for task: %@",error.description);
            }];
        }
    }
    [self doneEditing];
}

- (void)assignTask:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    User *user = [info objectForKey:@"user"];
    NSOrderedSet *assigneeSet = [NSOrderedSet orderedSetWithObject:user];
    _worklistItem.assignees = assigneeSet;
    if (user.fullname.length){
        [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",user.fullname] forState:UIControlStateNormal];
    } else if (user.firstName.length){
        [self.assigneeButton setTitle:[NSString stringWithFormat:@"Assigned: %@",user.firstName] forState:UIControlStateNormal];
    }
}

- (IBAction)completionTapped{
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if ([_worklistItem.completed isEqualToNumber:[NSNumber numberWithBool:NO]]){
            [_completionButton setBackgroundColor:kDarkGrayColor];
            [_completionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Completed" forState:UIControlStateNormal];
            _worklistItem.completed = [NSNumber numberWithBool:YES];
        } else {
            [_completionButton setBackgroundColor:[UIColor whiteColor]];
            [_completionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_completionButton setTitle:@"Mark Complete" forState:UIControlStateNormal];
            _worklistItem.completed = [NSNumber numberWithBool:NO];
        }
    } completion:^(BOOL finished) {
        if ([_worklistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [[[UIAlertView alloc] initWithTitle:@"Completion Photo" message:@"Can you take a photo of the completed task?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
        }
        shouldSave = YES;
    }];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if ([_worklistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
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
        //[vc setModalPresentationStyle:UIModalPresentationCurrentContext];
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We're unable to find a camera on this device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.scrollView setAlpha:0.0];
    [self dismissViewControllerAnimated:YES completion:nil];
    Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [newPhoto setImage:image];
    [_worklistItem addPhoto:newPhoto];
    [self redrawScrollView];
    [self saveImage:image];
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
                
                UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                     scale:[UIScreen mainScreen].scale orientation:orientation];
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:[self fixOrientation:image]];
                
                [_worklistItem addPhoto:newPhoto];
                [self saveImage:newPhoto.image];
            }
        }
        [self redrawScrollView];
    }];
}

- (UIImage *)fixOrientation:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *correctedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return correctedImage;
}

- (void)saveToLibrary:(UIImage*)originalImage {
    if (saveToLibrary){
        NSString *albumName = @"BuildHawk";
        UIImage *imageToSave = [UIImage imageWithCGImage:originalImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
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
        if (![_worklistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
            NSData *imageData = UIImageJPEGRepresentation(image,1);
            [manager POST:[NSString stringWithFormat:@"%@/worklist_items/photo",kApiBaseUrl] parameters:@{@"photo":@{@"worklist_item_id":_worklistItem.identifier,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId], @"project_id":_project.identifier, @"source":kWorklist,@"mobile":[NSNumber numberWithBool:YES],@"company_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId]}} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"save task photo response object: %@",responseObject);
                if ([responseObject objectForKey:@"punchlist_item"]){
                    [_worklistItem populateFromDictionary:[responseObject objectForKey:@"punchlist_item"]];
                    //[_project.worklist replaceWorklistItem:_worklistItem];
                } else if ([responseObject objectForKey:@"worklist_item"]){
                    [_worklistItem populateFromDictionary:[responseObject objectForKey:@"worklist_item"]];
                    //[_project.worklist replaceWorklistItem:_worklistItem];
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure posting image to API: %@",error.description);
            }];
        }
    }
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove.identifier){
        for (Photo *photo in _worklistItem.photos){
            if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
                [_worklistItem removePhoto:photo];
                [self redrawScrollView];
                break;
            }
        }
    } else {
        [_worklistItem removePhoto:photoToRemove];
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
    for (Photo *photo in _worklistItem.photos) {
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
        [imageButton setTag:[_worklistItem.photos indexOfObject:photo]];
        [imageButton addTarget:self action:@selector(existingPhotoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        index++;
    }
    
    if (_worklistItem.photos.count > 0){
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
    for (Photo *photo in _worklistItem.photos) {
        MWPhoto *mwPhoto;
        if (photo.image){
            mwPhoto = [MWPhoto photoWithImage:photo.image];
        } else {
            mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        }
        [mwPhoto setPhoto:photo];
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
        }
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
    if (_worklistItem.assignees.count){
        assigneeActionSheet = [[UIActionSheet alloc] initWithTitle:@"Assign this task:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [assigneeActionSheet addButtonWithTitle:@"Reassign"];
        if (_worklistItem.assignees.count) assigneeActionSheet.destructiveButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Remove assignee"];
        assigneeActionSheet.cancelButtonIndex = [assigneeActionSheet addButtonWithTitle:@"Cancel"];
        [assigneeActionSheet showInView:self.view];
    } else {
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    }
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
    [vc setProject:_project];
    if ([segue.identifier isEqualToString:@"PersonnelPicker"]){
        [vc setCompanyMode:NO];
        [vc setTask:_worklistItem];
    }
}

-(void)updateItem {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to save changes to a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [ProgressHUD show:@"Updating task..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) {
                [parameters setObject:strippedLocationString forKey:@"location"];
            }
        }
        if (_worklistItem.assignees.count){
            User *assigneeUser = _worklistItem.assignees.firstObject;
            if (![assigneeUser.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [parameters setObject:assigneeUser.identifier forKey:@"assignee_id"];
        }

        [parameters setObject:_worklistItem.identifier forKey:@"id"];
        
        if (self.itemTextView.text.length) {
            [parameters setObject:self.itemTextView.text forKey:@"body"];
        }
        if ([_worklistItem.completed isEqualToNumber:[NSNumber numberWithBool:YES]]){
            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"completed"];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"completed_by_user_id"];
        } else {
            [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"completed"];
        }
        
        [manager PATCH:[NSString stringWithFormat:@"%@/worklist_items/%@", kApiBaseUrl, _worklistItem.identifier] parameters:@{@"worklist_item":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success updating task: %@",responseObject);
            [_worklistItem populateFromDictionary:[responseObject objectForKey:@"worklist_item"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTask" object:nil userInfo:@{@"task":_worklistItem}];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [ProgressHUD dismiss];
            NSLog(@"Failed to update task: %@",error.description);
        }];
    }
}

-(void)createItem {
    if ([_project.demo isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to create new taskss for a demo project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else if ([_itemTextView.text isEqualToString:itemPlaceholder] || _itemTextView.text.length == 0){
        [[[UIAlertView alloc] initWithTitle:nil message:@"Please describe the new task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        shouldSave = NO;
        [ProgressHUD show:@"Adding task..."];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        NSString *strippedLocationString;
        if (![self.locationButton.titleLabel.text isEqualToString:locationPlaceholder]){
            strippedLocationString = [[self.locationButton.titleLabel.text stringByReplacingOccurrencesOfString:@"Location: " withString:@""] stringByTrimmingCharactersInSet:
                                      [NSCharacterSet whitespaceCharacterSet]];
            if (strippedLocationString.length) {
                [parameters setObject:strippedLocationString forKey:@"location"];
                _worklistItem.location = strippedLocationString;
            }
        } else {
            _worklistItem.location = nil;
        }
        
        if (_worklistItem.assignees.count){
            User *assigneeUser = _worklistItem.assignees.firstObject;
            if (![assigneeUser.identifier isEqualToNumber:[NSNumber numberWithInt:0]]) [parameters setObject:assigneeUser.identifier forKey:@"assignee_id"];
        }
        
        if (_itemTextView.text && ![_itemTextView.text isEqualToString:itemPlaceholder]) {
            [parameters setObject:self.itemTextView.text forKey:@"body"];
            [_worklistItem setBody:self.itemTextView.text];
        }
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];

        NSOrderedSet *photoSet = [NSOrderedSet orderedSetWithOrderedSet:_worklistItem.photos];
        [manager POST:[NSString stringWithFormat:@"%@/worklist_items", kApiBaseUrl] parameters:@{@"worklist_item":parameters,@"project_id":_project.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [_worklistItem populateFromDictionary:[responseObject objectForKey:@"worklist_item"]];
            _worklistItem.photos = photoSet;
            
            //this will cause the worklist view to insert the new item in its tableview through an NSNotification
            [_project.worklist addWorklistItem:_worklistItem];
            
            if (![_worklistItem.identifier isEqualToNumber:[NSNumber numberWithInt:0]]){
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                [parameters setObject:_worklistItem.identifier forKey:@"worklist_item_id"];
                [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"mobile"];
                [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
                if (_project.identifier) [parameters setObject:_project.identifier forKey:@"project_id"];
                [parameters setObject:kWorklist forKey:@"source"];
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId])[parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCompanyId] forKey:@"company_id"];
                
                for (Photo *photo in _worklistItem.photos){
                    NSData *imageData = UIImageJPEGRepresentation(photo.image, 1);
                    [manager POST:[NSString stringWithFormat:@"%@/worklist_items/photo",kApiBaseUrl] parameters:@{@"photo":parameters} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                        [formData appendPartWithFileData:imageData name:@"photo[image]" fileName:@"photo.jpg" mimeType:@"image/jpg"];
                    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSLog(@"Succes posting photo for new task");
                        [_worklistItem populateFromDictionary:[responseObject objectForKey:@"worklist_item"]];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"failure posting image to API: %@",error.description);
                    }];
                }
            }
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a task: %@",error.description);
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
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove location"]) {
        [self.locationButton setTitle:locationPlaceholder forState:UIControlStateNormal];
        _worklistItem.location = nil;
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Reassign"]) {
        [self performSegueWithIdentifier:@"PersonnelPicker" sender:nil];
    } else if (actionSheet == assigneeActionSheet && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        if (buttonIndex == assigneeActionSheet.destructiveButtonIndex){
            _worklistItem.assignees = nil;
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
                [_worklistItem setLocation:buttonTitle];
                [self.locationButton setTitle:[NSString stringWithFormat:@"Location: %@",buttonTitle] forState:UIControlStateNormal];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1){
        Comment *comment = _worklistItem.comments[indexPath.row];
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
        [[[UIAlertView alloc] initWithTitle:@"Demo Project" message:@"We're unable to delete comments on a demo project task." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    } else {
        Comment *comment = [_worklistItem.comments objectAtIndex:indexPathForDeletion.row];
        if (comment.identifier != [NSNumber numberWithInt:0]){
            [manager DELETE:[NSString stringWithFormat:@"%@/comments/%@",kApiBaseUrl,comment.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"successfully deleted comment: %@",responseObject);
                [_worklistItem removeComment:comment];
                [comment MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                shouldSave = NO;
                
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete comment: %@",error.description);
            }];
        } else {
            [_worklistItem removeComment:comment];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPathForDeletion] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == addOtherAlertView) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Submit"]) {
            [self.locationButton setTitle:[[alertView textFieldAtIndex:0] text] forState:UIControlStateNormal];
        }
    } else if ([[alertView buttonTitleAtIndex: buttonIndex] isEqualToString:@"Save"]) {
        if (_worklistItem.identifier && _worklistItem.identifier){
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
