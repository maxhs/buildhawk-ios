//
//  BHDocumentsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDocumentsViewController.h"
#import "BHPhotoPickerCell.h"
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHPhoto.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHPhotosViewController.h"
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import "Flurry.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    BOOL iPhone5;
    NSMutableArray *photosArray;
    NSArray *sortedByDate;
    NSMutableArray *sortedByUser;
    BOOL sortByDate;
    BOOL sortByUser;
    BOOL noSort;
    NSString *sortUser;
    NSString *sortCategory;
    UIActionSheet *categoryActionSheet;
    UIActionSheet *userActionSheet;
    NSMutableArray *userArray;
    NSMutableArray *sourceArray;
}

-(IBAction)backToDashboard;

@end

@implementation BHDocumentsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[[(BHTabBarViewController*)self.tabBarController project] name]];
	// Do any additional setup after loading the view, typically from a nib.
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    if (!photosArray) photosArray = [NSMutableArray array];
    if (!userArray) userArray = [NSMutableArray array];
    if (!sourceArray) sourceArray = [NSMutableArray array];
    if (!sortedByUser) sortedByUser = [NSMutableArray array];
    [self loadPhotos];
    noSort = YES;
    sortByDate = NO;
    sortByUser = NO;
    [Flurry logEvent:@"Viewing documents"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.tabBar.transform = CGAffineTransformIdentity;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPhotos {
    [SVProgressHUD showWithStatus:@"Fetching documents..."];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@/photos",kApiBaseUrl] parameters:@{@"pid":[[(BHTabBarViewController*)self.tabBarController project] identifier]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting documents: %@",responseObject);
        photosArray = [self photosFromJSONArray:[responseObject objectForKey:@"rows"]];
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting photos: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (NSMutableArray *)photosFromJSONArray:(NSArray *) array {
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *photoDictionary in array) {
        BHPhoto *photo = [[BHPhoto alloc] initWithDictionary:photoDictionary];
        if (![sourceArray containsObject:photo.source]) [sourceArray addObject:photo.source];
        if (photo.userName && ![userArray containsObject:photo.userName]) [userArray addObject:photo.userName];
        [photos addObject:photo];
    }
    return photos;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return sourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"PhotoPickerCell";
        BHPhotoPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPhotoPickerCell" owner:self options:nil] lastObject];
        }
        [cell.categoryButton addTarget:self action:@selector(sortByCategory) forControlEvents:UIControlEventTouchUpInside];
        [cell.dateButton addTarget:self action:@selector(sortByDate) forControlEvents:UIControlEventTouchUpInside];
        [cell.userButton addTarget:self action:@selector(sortByUser) forControlEvents:UIControlEventTouchUpInside];
        if (photosArray.count > 0){
            [cell.mainImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[(BHPhoto*)[photosArray objectAtIndex:0] orig]]] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                [cell.mainImageView setImage:image];
                [cell.mainImageView setContentMode:UIViewContentModeScaleAspectFill];
                cell.mainImageView.clipsToBounds = YES;
                UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [imageButton setFrame:cell.mainImageView.frame];
                [imageButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
                [cell addSubview:imageButton];
                [UIView animateWithDuration:.25 animations:^{
                    [cell.mainImageView setAlpha:1.0];
                }];
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                
            }];
        }
        [self buttonTreatment:cell.categoryButton];
        [self buttonTreatment:cell.dateButton];
        [self buttonTreatment:cell.userButton];
        if (photosArray.count) {
            [cell.countLabel setText:[NSString stringWithFormat:@"%i documents",photosArray.count]];
            [cell.countLabel setAlpha:1.0];
        }
        else {
            [cell.countLabel setAlpha:0.0];
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DocumentFolder"];
        [cell.textLabel setText:[sourceArray objectAtIndex:indexPath.row]];
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
        return cell;
    }
}

- (void)showPhotoDetail:(id)sender {
    NSMutableArray *photos = [NSMutableArray new];
    for (BHPhoto *photo in photosArray) {
        IDMPhoto *idmPhoto = [IDMPhoto photoWithURL:[NSURL URLWithString:photo.orig]];
        [photos addObject:idmPhoto];
    }
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    [self presentViewController:browser animated:YES completion:^{
        
    }];
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = 3.f;
    [button setBackgroundColor:[UIColor clearColor]];
    [button.layer setBackgroundColor:[UIColor colorWithWhite:.96 alpha:1.0].CGColor];
    button.layer.shouldRasterize = YES;
    button.layer.rasterizationScale = [UIScreen mainScreen].scale;
    button.layer.shadowColor = kDarkGrayColor.CGColor;
    button.layer.shadowOpacity =  .5;
    button.layer.shadowRadius = 2.f;
    button.layer.shadowOffset = CGSizeMake(0, 0);
    [button.titleLabel setTextColor:[UIColor darkGrayColor]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)return 200;
    else return 88;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) return [UIView new];
    else return nil;
}

- (void)sortByCategory {
    sortByDate = NO;
    sortByUser = NO;
    [self showPhoto];
}

- (void)sortByDate {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdOn" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    sortedByDate = [photosArray sortedArrayUsingDescriptors:sortDescriptors];
    sortByDate = YES;
    sortByUser = NO;
    [self showPhoto];
}

- (void)sortByUser {
    userActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by user" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *name in userArray) {
        [userActionSheet addButtonWithTitle:name];
    }
    userActionSheet.cancelButtonIndex = [userActionSheet addButtonWithTitle:@"Cancel"];
    [userActionSheet showFromTabBar:self.tabBarController.tabBar];
    sortByDate = NO;
    sortByUser = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == userActionSheet) {
        if (![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
            sortUser = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSPredicate *testForuser = [NSPredicate predicateWithFormat:@"userName contains[cd] %@",sortUser];
            [sortedByUser removeAllObjects];
            for (BHPhoto *photo in photosArray){
                if([testForuser evaluateWithObject:photo]) {
                    [sortedByUser addObject:photo];
                }
            }
            [self showPhoto];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)showPhoto {
    [self performSegueWithIdentifier:@"ByCategory" sender:self];
    [UIView animateWithDuration:.25 animations:^{
        self.tabBarController.tabBar.transform = CGAffineTransformMakeTranslation(0, 49);
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BHPhotosViewController *vc = [segue destinationViewController];
    if (sortByUser) {
        [vc setPhotosArray:sortedByUser];
        [vc setTitle:sortUser];
    } else if (sortByDate) {
        [vc setPhotosArray:sortedByDate];
        [vc setTitle:@"Sorting by date"];
    } else {
        [vc setPhotosArray:photosArray];
        [vc setTitle:sortCategory];
    }
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
