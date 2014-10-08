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
#import "BHTabBarViewController.h"
#import "Photo+helper.h"

@interface BHProjectDocsViewController () {
    NSMutableArray *browserPhotos;
}

@end

@implementation BHProjectDocsViewController

@synthesize photosArray = _photosArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (IDIOM == IPAD){
        self.tableView.rowHeight = 180.f;
    } else {
        self.tableView.rowHeight = 88.f;
    }
    [self.view setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.1]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePhoto:) name:@"RemovePhoto" object:nil];
}

-(void)removePhoto:(NSNotification*)notification {
    Photo *photoToRemove = [notification.userInfo objectForKey:@"photo"];
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
    Photo *photo = [_photosArray objectAtIndex:indexPath.row];
    [cell.docLabel setText:photo.name];
    
    [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.photoButton.imageView.clipsToBounds = YES;
    cell.backgroundColor = kDarkerGrayColor;
    [cell.docLabel setFont:[UIFont fontWithName:kMyriadProLight size:20]];
    cell.userInteractionEnabled = YES;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSURL *imageUrl;
    if (IDIOM == IPAD){
        
        imageUrl = [NSURL URLWithString:photo.urlLarge];
    } else if (_photosArray.count > 0) {
        imageUrl = [NSURL URLWithString:photo.urlSmall];
    } else {
        imageUrl = nil;
    }

    if (imageUrl) {
        cell.docLabel.transform = CGAffineTransformIdentity;
        [cell.photoButton sd_setImageWithURL:imageUrl forState:UIControlStateNormal completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [cell.photoButton setTag:0];
            cell.photoButton.userInteractionEnabled = NO;
            [UIView animateWithDuration:.25 animations:^{
                [cell.photoButton setAlpha:1.0];
                [cell.docLabel setAlpha:1.0];
            }];
        }];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"icon-256"] forState:UIControlStateNormal];
        [UIView animateWithDuration:.25 animations:^{
            [cell.docLabel setAlpha:1.0];
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
    [super prepareForSegue:segue sender:indexPath];
    
    if ([segue.identifier isEqualToString:@"WebView"]){
        BHWebViewController *vc = [segue destinationViewController];
        Photo *photo = [_photosArray objectAtIndex:indexPath.row];
        [vc setPhoto:photo];
        if (photo.name) [vc setTitle:photo.name];
    }
}

- (void)showBrowser:(int)idx {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _photosArray) {
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setPhoto:photo];
        [browserPhotos addObject:mwPhoto];
        if (photo.caption.length) mwPhoto.caption = photo.caption;
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    Project *project = (Project*)[(BHTabBarViewController*)self.tabBarController project];
    if (project.demo) browser.displayTrashButton = NO;
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
