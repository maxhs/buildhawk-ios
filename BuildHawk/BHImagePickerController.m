//
//  BHImagePickerController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/16/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHImagePickerController.h"
#import "BHImagePickerCell.h"
#import "Constants.h"
#import "BHUtilities.h"
#import "ProgressHUD.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "Photo+helper.h"
#import "ALAsset+date.h"

@interface BHImagePickerController () {
    CGFloat width;
    CGFloat height;
    NSMutableArray *_assets;
    NSMutableOrderedSet *_selectedAssets;
    UIImageView *focusImageView;
    UIBarButtonItem *selectButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *backButton;
    BOOL selectMode;
}

@end

@implementation BHImagePickerController
static NSString * const reuseIdentifier = @"PhotoCell";

@synthesize assetsGroup = _assetsGroup;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [self.collectionView setBackgroundView:backgroundToolbar];
    
    if (SYSTEM_VERSION >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }
    
    _assets = [NSMutableArray array];
    _selectedAssets = [NSMutableOrderedSet orderedSet];
    selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(toggleSelectMode)];
    selectMode = YES;
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPhotos];
}

- (void)toggleSelectMode {
    selectMode ? (selectMode = NO) : (selectMode = YES);
    self.navigationItem.rightBarButtonItem = selectMode ? doneButton : selectButton;
}

- (void)loadPhotos {
    if([ALAssetsLibrary authorizationStatus]) {
        //NSMutableArray *tempArray = [NSMutableArray array];
        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [_assets addObject:result];
            }
        };
        
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [_assetsGroup setAssetsFilter:onlyPhotosFilter];
        [_assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
        //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        //_assets = [tempArray sortedArrayUsingDescriptors:@[sort]];
        [self.collectionView reloadData];
        NSInteger item = _assets.count-1;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission Denied" message:@"Please allow the application to access your photo and videos in settings panel of your device" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    ALAsset *asset = _assets[indexPath.item];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    [cell.imageView setImage:thumbnail];
    
    if ([_selectedAssets containsObject:asset]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/6,width/6);
    } else {
        return CGSizeMake(width/4, width/4);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *asset = _assets[indexPath.item];
    BHImagePickerCell *selectedCell = (BHImagePickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (_selectedAssets.count >= 10){
        [[[UIAlertView alloc] initWithTitle:@"Photo limit" message:@"You can only select 10 images at a time." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    if (selectMode){
        if ([_selectedAssets containsObject:asset]){
            [_selectedAssets removeObject:asset];
        } else {
            [_selectedAssets addObject:asset];
        }
        NSString *viewTitle = _selectedAssets.count == 1 ? @"1 image selected" : [NSString stringWithFormat:@"%lu images selected",(unsigned long)_selectedAssets.count];
        self.title = viewTitle;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        [_selectedAssets addObject:asset];
        [selectedCell.contentView setAlpha:0.23f];
        [self.view addSubview:focusImageView];
        [self.view bringSubviewToFront:focusImageView];
        focusImageView.frame = selectedCell.frame;
        CGRect newFrame = CGRectMake(width/2-400, height/2-300, 800, 600);
        
        [UIView animateWithDuration:.23f animations:^{
            [focusImageView setFrame:newFrame];
        }];
    }
}

#pragma mark - Segue support

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)done {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_selectedAssets.count == 1){
            [ProgressHUD show:@"Loading image..."];
        } else {
            [ProgressHUD show:@"Loading images..."];
        }
    });

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (double).07f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishPickingPhotos:)]){
            NSMutableArray *photoArray = [NSMutableArray arrayWithCapacity:_selectedAssets.count];
            [_selectedAssets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
                ALAssetRepresentation *imageRep = [asset defaultRepresentation];
                UIImage* image = [UIImage imageWithCGImage:[imageRep fullResolutionImage] scale:imageRep.scale orientation:(UIImageOrientation)imageRep.orientation];
                Photo *newPhoto = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                [newPhoto setImage:image];
                [newPhoto setTakenAt:[asset valueForProperty:ALAssetPropertyDate]];
                [newPhoto setFileName:imageRep.filename];
                [photoArray addObject:newPhoto];
            }];
            [self.delegate didFinishPickingPhotos:photoArray];
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
