//
//  BHAssetGroupPickerViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 3/16/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHAssetGroupPickerViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BHImagePickerController.h"
#import "BHAssetGroupPickerCell.h"
#import "Constants.h"
#import "BHUtilities.h"

@interface BHAssetGroupPickerViewController () {
    ALAssetsLibrary *_assetsLibrary;
    NSMutableArray *_assetGroups;
}

@end

@implementation BHAssetGroupPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.03]];
    self.tableView.rowHeight = 100.f;
    [self.tableView setBackgroundColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]]; //make sure the buttons are tinted white
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    _assetGroups = [NSMutableArray array];
    [self loadGroups];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)loadGroups {
    // setup our failure view controller in case enumerateGroupsWithTypes fails
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"The user has declined access to it.";
                break;
            default:
                errorMessage = @"Reason unknown.";
                break;
        }
        
        NSLog(@"Something went wrong while fetching the groups");
    };
    
    // emumerate through our groups and only add groups that contain photos
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [group setAssetsFilter:onlyPhotosFilter];
        if ([group numberOfAssets] > 0) {
            [_assetGroups addObject:group];
        } else {
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    };
    
    // enumerate only photos
    NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
    [_assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock failureBlock:failureBlock];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _assetGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BHAssetGroupPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];
    if (SYSTEM_VERSION < 8.f){
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    
    ALAssetsGroup *group = _assetGroups[indexPath.row];
    CGImageRef posterImageRef = [group posterImage];
    UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
    cell.imageView.image = posterImage;
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    cell.detailTextLabel.text = [@(group.numberOfAssets) stringValue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"AssetGroupSelected" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"AssetGroupSelected"]) {
        BHImagePickerController *imagePicker = [segue destinationViewController];
        UIViewController *previousVC = self.navigationController.viewControllers[self.navigationController.viewControllers.count-2];
        imagePicker.delegate = (id<BHImagePickerControllerDelegate>)previousVC;
        NSIndexPath *selectedIndexPath = (NSIndexPath*)sender;
        [imagePicker setAssetsGroup:_assetGroups[selectedIndexPath.row]];
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
