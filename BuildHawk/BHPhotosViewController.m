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
#import "BHPhotosHeaderView.h"

@interface BHPhotosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MWPhotoBrowserDelegate, UIActionSheetDelegate> {
    BOOL iPad;
    CGRect screen;
    NSMutableArray *sectionArray;
    NSMutableArray *compositePhotos;
    NSMutableArray *browserArray; // for BHPhoto objects
    NSMutableArray *browserPhotos; //for MWPhoto objects
    UIActionSheet *sortSheet;
    BOOL sortByUser;
    BOOL sortByDate;
}
-(IBAction)sort;
@end

@implementation BHPhotosViewController

@synthesize photosArray, phasePhotosArray, userNames, dates;
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
    [self.collectionView reloadData];
    screen = [UIScreen mainScreen].bounds;
    if (!sectionArray) sectionArray = [NSMutableArray array];
    if (!compositePhotos) compositePhotos = [NSMutableArray array];
    if (!browserArray) browserArray = [NSMutableArray array];
    sortByUser = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"DeletePhoto" object:nil];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else
        iPad = NO;
}
- (void)viewWillAppear:(BOOL)animated {
    [self.tabBarController.tabBar setFrame:CGRectMake(0, screen.size.height, screen.size.width, 49)];
    self.tabBarController.tabBar.alpha = 0.0;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sort{
    sortSheet = [[UIActionSheet alloc] initWithTitle:@"Sort" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [sortSheet addButtonWithTitle:@"By User"];
    if (!self.reportsBool)[sortSheet addButtonWithTitle:@"By Date"];
    [sortSheet addButtonWithTitle:@"Default"];
    [sortSheet setCancelButtonIndex:[sortSheet addButtonWithTitle:@"Cancel"]];
    [sortSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"By User"]) {
        if (sectionArray.count)[sectionArray removeAllObjects];
        sortByUser = YES;
        sortByDate = NO;
        [self.collectionView reloadData];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"By Date"]) {
        if (sectionArray.count)[sectionArray removeAllObjects];
        sortByUser = NO;
        sortByDate = YES;
        [self.collectionView reloadData];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Default"]) {
        if (sectionArray.count)[sectionArray removeAllObjects];
        sortByUser = NO;
        sortByDate = NO;
        [self.collectionView reloadData];
    }
}
#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (sortByUser) {
        NSString *sectionTitle = [self.userNames objectAtIndex:section];
        NSPredicate *testForuser = [NSPredicate predicateWithFormat:@"userName contains[cd] %@",sectionTitle];
        NSMutableArray *sortedByUser = [NSMutableArray array];
        for (BHPhoto *photo in photosArray){
            if([testForuser evaluateWithObject:photo]) {
                [sortedByUser addObject:photo];
            }
        }
        [sectionArray addObject:sortedByUser];
        return sortedByUser.count;
    } else if (sortByDate) {
        NSString *sectionTitle = [self.dates objectAtIndex:section];
        NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"createdDate like %@",sectionTitle];
        NSMutableArray *tempArray = [NSMutableArray array];
        for (BHPhoto *photo in self.photosArray){
            if([testPredicate evaluateWithObject:photo]) {
                [tempArray addObject:photo];
            }
        }
        [sectionArray addObject:tempArray];
        return tempArray.count;
    } else if (self.sectionTitles.count){
        NSString *sectionTitle = [self.sectionTitles objectAtIndex:section];
        NSPredicate *testPredicate;
        if (self.documentsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"folder like %@",sectionTitle];
        } else if (self.worklistsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"assignee like %@",sectionTitle];
        } else if (self.reportsBool) {
            testPredicate = [NSPredicate predicateWithFormat:@"createdDate like %@",sectionTitle];
        } else {
            testPredicate = [NSPredicate predicateWithFormat:@"phase like %@",sectionTitle];
        }
        NSMutableArray *tempArray = [NSMutableArray array];
        for (BHPhoto *photo in self.photosArray){
            if([photo isKindOfClass:[BHPhoto class]] && [testPredicate evaluateWithObject:photo]) {
                [tempArray addObject:photo];
            }
        }
        [sectionArray addObject:tempArray];
        return tempArray.count;
    } else  {
        return self.photosArray.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (sortByUser) return self.userNames.count;
    else if (sortByDate) return self.dates.count;
    else return _numberOfSections;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BHCollectionPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    BHPhoto *photo;
    if (self.sectionTitles.count || sortByUser || sortByDate) {
        NSMutableArray *tempArray = [sectionArray objectAtIndex:indexPath.section];
        photo = [tempArray objectAtIndex:indexPath.row];
        [browserArray addObject:photo];
    } else {
        photo = [self.photosArray objectAtIndex:indexPath.row];
        [browserArray addObject:photo];
    }
    [cell.photoButton setTag:[browserArray indexOfObject:photo]];
    [cell configureForPhoto:photo];
    [cell.photoButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)removePhoto:(NSNotification*)notification {
    NSString *photoIdentifier = [notification.userInfo objectForKey:@"photoId"];
    [SVProgressHUD showWithStatus:@"Deleting photo..."];
    [self.photosArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(BHPhoto*)obj identifier] isEqualToString:photoIdentifier]){
            NSLog(@"should be removing photo at index: %i",idx);
            BHPhoto *photoToRemove = [self.photosArray objectAtIndex:idx];
            
            if (self.documentsBool) [[NSNotificationCenter defaultCenter] postNotificationName:@"RemovePhoto" object:nil userInfo:@{@"photo":photoToRemove,@"type":kDocuments}];
            else if (self.reportsBool) [[NSNotificationCenter defaultCenter] postNotificationName:@"RemovePhoto" object:nil userInfo:@{@"photo":photoToRemove,@"type":kReports}];
            else if (self.checklistsBool) [[NSNotificationCenter defaultCenter] postNotificationName:@"RemovePhoto" object:nil userInfo:@{@"photo":photoToRemove,@"type":kChecklist}];
            else if (self.worklistsBool) [[NSNotificationCenter defaultCenter] postNotificationName:@"RemovePhoto" object:nil userInfo:@{@"photo":photoToRemove,@"type":kWorklist}];
            
            [[AFHTTPRequestOperationManager manager] DELETE:[NSString stringWithFormat:@"%@/photos/%@",kApiBaseUrl,[notification.userInfo objectForKey:@"photoId"]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [SVProgressHUD dismiss];
                [self.photosArray removeObject:photoToRemove];
                [self.collectionView reloadData];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
            }];
            *stop = YES;
        }
    }];
}

- (void)showPhotoDetail:(UIButton*)button {
    //reorder photos based on tap
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
    [self showBrowser:button.tag];
}

- (void)showBrowser:(int)idx {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in browserArray) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setOriginalURL:[NSURL URLWithString:photo.orig]];
        [mwPhoto setPhotoId:photo.identifier];
        [browserPhotos addObject:mwPhoto];
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
    browser.navigationController.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(save)]];
    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:idx];
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
            title = [self.userNames objectAtIndex:indexPath.section];
        } else if (sortByDate){
            title = [self.dates objectAtIndex:indexPath.section];
        } else {
            title = [self.sectionTitles objectAtIndex:indexPath.section];
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
    if (self.sectionTitles.count) return CGSizeMake(screen.size.width, 30);
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    sortSheet = nil;
}
@end
