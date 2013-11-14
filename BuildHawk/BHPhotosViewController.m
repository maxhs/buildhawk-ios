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
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

@interface BHPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@end

@implementation BHPhotosViewController

@synthesize photosArray;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.photosArray.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHCollectionPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    BHPhoto *photo = [self.photosArray objectAtIndex:indexPath.row];
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
    NSMutableArray *compositePhotos = [NSMutableArray new];
    [compositePhotos addObjectsFromArray:secondSlice];
    [compositePhotos addObjectsFromArray:firstSlice];
    
    NSMutableArray *photos = [NSMutableArray new];
    for (BHPhoto *photo in compositePhotos) {
        IDMPhoto *idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        [photos addObject:idmPhoto];
    }
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    [self presentViewController:browser animated:YES completion:^{
        
    }];
}

/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/

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
    //CGSize retval = photo.thumbnail.size.width > 0 ? photo.thumbnail.size : CGSizeMake(100, 100);
    //retval.height += 35; retval.width += 35; return retval;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

@end
