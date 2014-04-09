//
//  BHProjectDocsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/6/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHProjectDocsViewController.h"
#import "BHPhotoPickerCell.h"
#import "UIButton+WebCache.h"
#import "BHWebViewController.h"

@interface BHProjectDocsViewController () {
    BOOL iPad;
    NSMutableArray *browserPhotos;
}

@end

@implementation BHProjectDocsViewController

@synthesize photosArray = _photosArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([BHUtilities isIpad]){
        iPad = YES;
        self.tableView.rowHeight = 180.f;
    } else {
        self.tableView.rowHeight = 88.f;
        iPad = NO;
    }
    [self.view setBackgroundColor:[UIColor colorWithWhite:.875 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.1]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
}

-(void)removePhoto:(NSNotification*)notification {
    BHPhoto *photoToRemove = [notification.userInfo objectForKey:@"photo"];
    if (photoToRemove) {
        [_photosArray removeObject:photoToRemove];
        [self.tableView reloadData];
    }
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
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _photosArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotoPickerCell";
    BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
    }
    BHPhoto *photo = [_photosArray objectAtIndex:indexPath.row];
    [cell.label setText:photo.name];
    
    cell.backgroundColor = kDarkerGrayColor;
    cell.textLabel.numberOfLines = 0;
    cell.userInteractionEnabled = YES;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (iPad) [cell.label setFont:[UIFont systemFontOfSize:18]];
    NSURL *imageUrl;
    if (iPad){
        imageUrl = [NSURL URLWithString:photo.urlLarge];
    } else if (_photosArray.count > 0) {
        imageUrl = [NSURL URLWithString:photo.url200];
    } else {
        imageUrl = nil;
    }

    if (imageUrl) {
        cell.label.transform = CGAffineTransformIdentity;
        [cell.photoButton setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [cell.photoButton setTag:0];
            cell.photoButton.userInteractionEnabled = NO;
            [UIView animateWithDuration:.25 animations:^{
                [cell.photoButton setAlpha:1.0];
                [cell.label setAlpha:1.0];
            }];
        }];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_256"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:.25 animations:^{
            [cell.label setAlpha:1.0];
            [cell.photoButton setAlpha:1.0];
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[self showBrowser:indexPath.row];
    [self performSegueWithIdentifier:@"WebView" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)indexPath {
    if ([segue.identifier isEqualToString:@"WebView"]){
        BHWebViewController *vc = [segue destinationViewController];
        BHPhoto *photo = [_photosArray objectAtIndex:indexPath.row];
        [vc setPhoto:photo];
        if (photo.name) [vc setTitle:photo.name];
    }
}

- (void)showBrowser:(int)idx {
    browserPhotos = [NSMutableArray new];
    for (BHPhoto *photo in _photosArray) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setBhphoto:photo];
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.zoomPhotosToFill = YES;
    browser.alwaysShowControls = YES;
    browser.enableGrid = YES;
    browser.startOnGrid = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0){
        browser.wantsFullScreenLayout = YES;
    }
    
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

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    // Do your thing!
    NSLog(@"action button pressed");
}

@end
