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
#import <RestKit/RestKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHPhotosViewController.h"

@interface BHDocumentsViewController () <UITableViewDataSource, UITableViewDelegate> {
    BOOL iPhone5;
    NSMutableArray *photosArray;
}

-(IBAction)backToDashboard;
@end

@implementation BHDocumentsViewController

@synthesize documentFolders;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Documents",[[(BHTabBarViewController*)self.tabBarController project] name]];
	// Do any additional setup after loading the view, typically from a nib.
    if (!self.documentFolders) self.documentFolders = [NSMutableArray array];
    [self.documentFolders addObject:@"Blueprints"];
    [self.documentFolders addObject:@"Financials"];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    if (!photosArray) photosArray = [NSMutableArray array];
    [self loadPhotos];
    
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
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *photosMapping = [RKObjectMapping mappingForClass:[BHPhoto class]];
    [photosMapping addAttributeMappingsFromDictionary:@{
                                                        @"urls.200x200":@"url200",
                                                        @"urls.100x100":@"url100"
                                                        }];
    
    /*RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"created.photos"
                                                                                             toKeyPath:@"photos"
                                                                                           withMapping:photosMapping];*/

    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *punchlistDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:photosMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"rows" statusCodes:statusCodes];
    
    [SVProgressHUD showWithStatus:@"Fetching documents..."];
    [manager addResponseDescriptor:punchlistDescriptor];
    [manager getObjectsAtPath:[NSString stringWithFormat:@"photos/%@",[[(BHTabBarViewController*)self.tabBarController project] identifier]] parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [photosArray removeAllObjects];
        for (id obj in mappingResult.array) {
            if ([obj isKindOfClass:[BHPhoto class]]) [photosArray addObject:(BHPhoto*)obj];
        }
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching projects for dashboard: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    else return self.documentFolders.count;
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
        [cell.categoryButton addTarget:self action:@selector(showPhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell.dateButton addTarget:self action:@selector(showPhoto) forControlEvents:UIControlEventTouchUpInside];
        [cell.userButton addTarget:self action:@selector(showPhoto) forControlEvents:UIControlEventTouchUpInside];
        if (photosArray.count > 0){
            [cell.mainImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[(BHPhoto*)[photosArray objectAtIndex:0] url200]]] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                [cell.mainImageView setImage:image];
                [cell.mainImageView setContentMode:UIViewContentModeScaleAspectFill];
                cell.mainImageView.clipsToBounds = YES;
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
        [cell.textLabel setText:[self.documentFolders objectAtIndex:indexPath.row]];
        return cell;
    }
}

- (void)buttonTreatment:(UIButton*)button {
    button.layer.cornerRadius = button.frame.size.height/2;
    button.clipsToBounds = YES;
    button.backgroundColor = kBlueColor;
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 0.5;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)return 200;
    else return 88;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) return [UIView new];
    else return nil;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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
    [vc setPhotosArray:photosArray];
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
