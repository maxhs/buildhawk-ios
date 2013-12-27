//
//  BHPhotosViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPhotosViewController.h"
#import "BHCollectionPhotoCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>

@interface BHPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MWPhotoBrowserDelegate> {
    CGRect screen;
    NSMutableArray *sectionArray;
    NSMutableArray *compositePhotos;
}

@end

@implementation BHPhotosViewController

@synthesize photosArray, phasePhotosArray;
@synthesize numberOfSections = _numberOfSections;
@synthesize sectionTitles = _sectionTitles;

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
    //[self.collectionView registerClass:[BHCollectionPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    [self.collectionView reloadData];
    screen = [UIScreen mainScreen].bounds;
    if (!sectionArray) sectionArray = [NSMutableArray array];
    if (!compositePhotos) compositePhotos = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (self.sectionTitles.count){
        NSString *sectionTitle = [self.sectionTitles objectAtIndex:section];
        NSPredicate *testForPhase = [NSPredicate predicateWithFormat:@"phase like %@",sectionTitle];
        NSMutableArray *tempArray = [NSMutableArray array];
        for (BHPhoto *photo in self.photosArray){
            if([testForPhase evaluateWithObject:photo]) {
                [tempArray addObject:photo];
            }
        }
        [sectionArray addObject:tempArray];
        return tempArray.count;
    } else {
        return self.photosArray.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return _numberOfSections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHCollectionPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    BHPhoto *photo;
    if (self.sectionTitles.count) {
        NSMutableArray *tempArray = [sectionArray objectAtIndex:indexPath.section];
        photo = [tempArray objectAtIndex:indexPath.row];
    } else {
        photo = [self.photosArray objectAtIndex:indexPath.row];
    }
    [cell configureForPhoto:photo];
    [cell.photoButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
    [cell.photoButton setTag:indexPath.row];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}

- (void)showPhotoDetail:(id)sender {
    //reorder photos based on tap
    UIButton *button = (UIButton*)sender;
    NSMutableArray *secondSlice = [NSMutableArray array];
    for (int i=button.tag ; i<self.photosArray.count ; i++){
        [secondSlice addObject:[self.photosArray objectAtIndex:i]];
    }
    NSMutableArray *firstSlice = [NSMutableArray array];
    for (int i=0 ; i<button.tag ; i++){
        [firstSlice addObject:[self.photosArray objectAtIndex:i]];
    }
    compositePhotos = [NSMutableArray new];
    [compositePhotos addObjectsFromArray:secondSlice];
    [compositePhotos addObjectsFromArray:firstSlice];
    [self showBrowser];
}

- (void)showBrowser {
    NSMutableArray *photos = [NSMutableArray new];
    for (BHPhoto *photo in compositePhotos) {
        MWPhoto *mwPhoto;
        //if (photo.mimetype && [photo.mimetype isEqualToString:kPdf]){
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        //} else {
        //    idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        //}
        [photos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES; // iOS 5 & 6 only: Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    }
    
    // Optionally set the current visible photo before displaying
    [browser setCurrentPhotoIndex:1];
    
    // Present
    [self.navigationController pushViewController:browser animated:YES];
    
    // Manipulate
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:10];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return compositePhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < compositePhotos.count)
        return [compositePhotos objectAtIndex:index];
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        [headerView setBackgroundColor:[UIColor colorWithWhite:.1 alpha:.9]];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
        [headerLabel setText:[self.sectionTitles objectAtIndex:indexPath.section]];
        [headerLabel setBackgroundColor:[UIColor clearColor]];
        [headerView addSubview:headerLabel];
        [headerLabel setTextColor:[UIColor whiteColor]];
        [headerLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:14]];
        NSLog(@"setting header view: %@ %@",headerLabel.text, headerLabel);
        return headerView;
    } else {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        return footerView;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.sectionTitles.count) return CGSizeMake(screen.size.width, 34);
    else return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100,100);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

@end
