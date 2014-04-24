//
//  BHFoldersViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 1/31/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHFoldersViewController.h"
#import "BHPhotoPickerCell.h"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "BHProjectDocsViewController.h"
#import "BHTabBarViewController.h"

@interface BHFoldersViewController () <MWPhotoBrowserDelegate, UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *compositePhotos;
    NSMutableArray *browserArray; // for BHPhoto objects
    NSMutableArray *browserPhotos; //for MWPhoto objects
    NSIndexPath *tapped;
    BOOL iPad;
    CGRect screen;
}

@end

@implementation BHFoldersViewController

@synthesize photoSet = _photoSet;
@synthesize photosArray = _photosArray;
@synthesize sectionTitles = _sectionTitles;

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"DeletePhoto" object:nil];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.875 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.1]];
    if ([BHUtilities isIpad]) {
        iPad = YES;
        self.tableView.rowHeight = 88.f;
    } else {
        iPad = NO;
        self.tableView.rowHeight = 60.f;
    }
    screen = [UIScreen mainScreen].bounds;
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    //return _photoSet.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _sectionTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Folder"];
    NSDictionary *dict = [_photoSet.allObjects objectAtIndex:indexPath.row];
    NSString *key = [[dict allKeys] firstObject];
    NSArray *array = [dict objectForKey:key];
    NSString *titleString;
    if (array.count == 1){
        titleString = [NSString stringWithFormat:@"%@ - 1 item",key];
    } else {
        titleString = [NSString stringWithFormat:@"%@ - %i items",key,array.count];
    }
    [cell.textLabel setText:titleString];
    if(iPad) [cell.textLabel setFont:[UIFont systemFontOfSize:19]];
    else [cell.textLabel setFont:[UIFont systemFontOfSize:18]];
    return cell;
    /*static NSString *CellIdentifier = @"PhotoPickerCell";
    BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
    }
    
    NSDictionary *dict = [_photoSet.allObjects objectAtIndex:indexPath.section];
    NSString *key = [[dict allKeys] firstObject];
    
    BHPhoto *photo = [[dict objectForKey:key] objectAtIndex:indexPath.row];
    NSURL *imageUrl;
    if (iPad) {
        imageUrl = [NSURL URLWithString:photo.urlLarge];
    } else {
        imageUrl = [NSURL URLWithString:photo.url200];
    }
    [cell.photoButton setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        cell.photoButton.userInteractionEnabled = NO;
        [UIView animateWithDuration:.25 animations:^{
            [cell.photoButton setAlpha:1.0];
            [cell.label setAlpha:1.0];
        }];
    }];
    if (photo.name.length) [cell.label setText:photo.name];
    else [cell.label setText:@"photo name"];
    return cell;*/
}

/*- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (iPad) return (screen.size.height-64-52)/5;
    else return (screen.size.height-64-49)/5;
}*/

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

/*- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *dict = [_photoSet.allObjects objectAtIndex:section];
    return [[dict allKeys] firstObject];
}*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*NSDictionary *dict = [_photoSet.allObjects objectAtIndex:indexPath.section];
    NSString *key = [[dict allKeys] firstObject];
    BHPhoto *photo = [[dict objectForKey:key] objectAtIndex:indexPath.row];
    [self showBrowser:[_photosArray indexOfObject:photo]];
    tapped = indexPath;*/
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ProjectDocs" sender:indexPath];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    if ([segue.identifier isEqualToString:@"ProjectDocs"]){
        NSDictionary *dict = [_photoSet.allObjects objectAtIndex:indexPath.row];
        NSString *folder = [[dict allKeys] firstObject];
        NSPredicate *test = [NSPredicate predicateWithFormat:@"folder contains[cd] %@",folder];
        browserArray = [NSMutableArray array];
        for (BHPhoto *photo in _photosArray){
            if([test evaluateWithObject:photo]) {
                [browserArray addObject:photo];
            }
        }
        BHProjectDocsViewController *vc = [segue destinationViewController];
        [vc setTitle:folder];
        [vc setPhotosArray:browserArray];
    }
}

-(void)removePhoto:(NSNotification*)notification {
    BHPhoto *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove){
        [_photosArray removeObject:photoToRemove];
        [[[_photoSet.allObjects objectAtIndex:tapped.section] objectForKey:[_sectionTitles objectAtIndex:tapped.section]] removeObject:photoToRemove];
        [self.tableView reloadData];
    }
}

- (void)showBrowser {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in browserArray) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setBhphoto:photo];
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    BHProject *project = (BHProject*)[(BHTabBarViewController*)self.tabBarController project];
    if (project.demo) browser.displayTrashButton = NO;
    // Set options
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = YES;

    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:0];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

@end
