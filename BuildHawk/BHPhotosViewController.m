//
//  BHPhotosViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 10/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPhotosViewController.h"
#import "BHCollectionPhotoCell.h"
#import "UIButton+WebCache.h"
#import "UIImageView+WebCache.h"
#import "MWPhotoBrowser.h"
#import "BHPhotosHeaderView.h"
#import "BHTabBarViewController.h"

@interface BHPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MWPhotoBrowserDelegate, UIActionSheetDelegate> {
    CGFloat width;
    CGFloat height;
    CGRect screen;
    NSMutableArray *sectionArray;
    NSMutableArray *compositePhotos;
    NSMutableArray *browserArray; // for Photo objects
    NSMutableArray *browserPhotos; //for MWPhoto objects
    UIActionSheet *sortSheet;
    BOOL sortByUser;
    BOOL sortByDate;
}
-(IBAction)sort;
@end

@implementation BHPhotosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView reloadData];
    screen = [UIScreen mainScreen].bounds;
    sectionArray = [NSMutableArray array];
    compositePhotos = [NSMutableArray array];
    browserArray = [NSMutableArray array];
    browserPhotos = [NSMutableArray array];
    sortByUser = NO;
    sortByDate = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) || [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [self.tabBarController.tabBar setFrame:CGRectMake(0, screen.size.height, screen.size.width, 49)];
    self.tabBarController.tabBar.alpha = 0.0;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sort{
    sortSheet = [[UIActionSheet alloc] initWithTitle:@"Sort" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [sortSheet addButtonWithTitle:@"Taken/Uploaded By"];
    if (!self.reportsBool)[sortSheet addButtonWithTitle:@"By Date"];
    [sortSheet addButtonWithTitle:@"Default"];
    [sortSheet setCancelButtonIndex:[sortSheet addButtonWithTitle:@"Cancel"]];
    [sortSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Taken/Uploaded By"]) {
        if (browserArray.count) [browserArray removeAllObjects];
        if (sectionArray.count)[sectionArray removeAllObjects];
        sortByUser = YES;
        sortByDate = NO;
        [self.collectionView reloadData];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"By Date"]) {
        if (browserArray.count) [browserArray removeAllObjects];
        if (sectionArray.count)[sectionArray removeAllObjects];
        sortByDate = YES;
        sortByUser = NO;
        [self.collectionView reloadData];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Default"]) {
        if (sectionArray.count)[sectionArray removeAllObjects];
        if (browserArray.count) [browserArray removeAllObjects];
        sortByUser = NO;
        sortByDate = NO;
        [self.collectionView reloadData];
    }
}
#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (sortByUser) {
        NSString *sectionTitle = [_userNames objectAtIndex:section];
        NSPredicate *testForuser = [NSPredicate predicateWithFormat:@"userName contains[cd] %@",sectionTitle];
        NSMutableArray *sortedByUser = [NSMutableArray array];
        for (Photo *photo in _photosArray){
            if([testForuser evaluateWithObject:photo]) {
                [sortedByUser addObject:photo];
                [browserArray addObject:photo];
            }
        }
        [sectionArray addObject:sortedByUser];
        return sortedByUser.count;
    } else if (sortByDate) {
        NSString *sectionTitle = [_dates objectAtIndex:section];
        NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"dateString like %@",sectionTitle];
        NSMutableArray *tempArray = [NSMutableArray array];
        for (Photo *photo in _photosArray){
            if([testPredicate evaluateWithObject:photo]) {
                [tempArray addObject:photo];
                [browserArray addObject:photo];
            }
        }
        NSArray *reversed = [[tempArray reverseObjectEnumerator] allObjects];
        [sectionArray addObject:reversed];
        return tempArray.count;
    } else if (_sectionTitles.count){
        NSString *sectionTitle = [_sectionTitles objectAtIndex:section];
        NSPredicate *testPredicate;
        if (self.documentsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"folder.name like %@",sectionTitle];
        } else if (self.tasklistsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"userName like %@",sectionTitle];
        } else if (self.reportsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"dateString like %@",sectionTitle];
        } else {
            testPredicate = [NSPredicate predicateWithFormat:@"photoPhase like %@",sectionTitle];
        }
        NSMutableArray *tempArray = [NSMutableArray array];
        for (Photo *photo in _photosArray){
            if([photo isKindOfClass:[Photo class]] && [testPredicate evaluateWithObject:photo]) {
                [browserArray addObject:photo];
                [tempArray addObject:photo];
            }
        }
        [sectionArray addObject:tempArray];
        return tempArray.count;
    } else  {
        browserArray = [NSMutableArray arrayWithArray:_photosArray];
        return _photosArray.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (sortByUser) return _userNames.count;
    else if (sortByDate) return _dates.count;
    else return _numberOfSections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHCollectionPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo;
    if (_sectionTitles.count || sortByUser || sortByDate) {
        NSMutableArray *tempArray = [sectionArray objectAtIndex:indexPath.section];
        photo = [tempArray objectAtIndex:indexPath.row];
    } else {
        photo = [_photosArray objectAtIndex:indexPath.row];
    }
    [cell.photoButton setTag:[browserArray indexOfObject:photo]];
    [cell configureForPhoto:photo];
    [cell.photoButton addTarget:self action:@selector(showBrowser:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = (Photo*)[notification.userInfo objectForKey:@"photo"];
    for (Photo *photo in _photosArray) {
        if ([photo.identifier isEqualToNumber:photoToRemove.identifier]) {
            [_photosArray removeObject:photo];
            [browserArray removeAllObjects];
            [sectionArray removeAllObjects];
            [self.collectionView reloadData];
            return;
        }
    }
    [browserArray removeAllObjects];
    [sectionArray removeAllObjects];
    [self.collectionView reloadData];
}

- (void)showBrowser:(UIButton*)button {
    [browserPhotos removeAllObjects];
    for (Photo *photo in browserArray) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
        if (photo.caption.length) mwPhoto.caption = photo.caption;
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];

    if ([_project.demo isEqualToNumber:@YES]) {
        browser.displayTrashButton = NO;
    }
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = NO;
    [browser setProject:_project];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:button.tag];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        BHPhotosHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        NSString *title;
        if (sortByUser){
            title = [_userNames objectAtIndex:indexPath.section];
        } else if (sortByDate){
            title = [_dates objectAtIndex:indexPath.section];
        } else {
            title = [_sectionTitles objectAtIndex:indexPath.section];
        }
        if ([title isKindOfClass:[NSString class]] && title.length){
            [headerView configureForTitle:title];
        }
        [headerView setBackgroundColor:[UIColor clearColor]];
        return headerView;
    } else {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        return footerView;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_sectionTitles.count || sortByDate || sortByUser) return CGSizeMake(screen.size.width, 30);
    else return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(screenWidth()/7,screenWidth()/7);
    } else {
        return CGSizeMake(width/3,width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    sortSheet = nil;
}
@end
