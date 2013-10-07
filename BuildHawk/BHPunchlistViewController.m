//
//  BHPunchlistViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHPunchlistViewController.h"
#import "BHPunchlistItemCell.h"
#import "BHPunchlistItemViewController.h"
#import "BHPunchlistItem.h"
#import "BHPunchlist.h"
#import "BHPhoto.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <RestKit/RestKit.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "BHTabBarViewController.h"
#import "Constants.h"
#import "BHAppDelegate.h"

@interface BHPunchlistViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *listItems;
    NSDateFormatter *dateFormatter;
}
- (IBAction)backToDashboard;
@end

@implementation BHPunchlistViewController

@synthesize punchlists;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Worklists",[[(BHTabBarViewController*)self.tabBarController project] name]];
    self.tableView.tableHeaderView = self.segmentContainerView;
    if (!listItems) listItems = [NSMutableArray array];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [self.segmentedControl setTintColor:kBlueColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPunchlist];
    [SVProgressHUD showWithStatus:@"Fetching worklists..."];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPunchlist {
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *photosMapping = [RKObjectMapping mappingForClass:[BHPhoto class]];
    [photosMapping addAttributeMappingsFromDictionary:@{
                                                         @"urls.200x200":@"url200",
                                                         @"urls.100x100":@"url100"
                                                         }];
    RKObjectMapping *completedMapping = [RKObjectMapping mappingForClass:[BHCompleted class]];
    [photosMapping addAttributeMappingsFromDictionary:@{
                                                        @"completedOn":@"completedOn"
                                                        }];
    
    RKObjectMapping *punchlistMapping = [RKObjectMapping mappingForClass:[BHPunchlistItem class]];
    [punchlistMapping addAttributeMappingsFromArray:@[@"name", @"location"]];
    [punchlistMapping addAttributeMappingsFromDictionary:@{
                                                         @"_id" : @"identifier",
                                                         @"created.createdOn" : @"createdOn",
                                                         @"completed.completedOn" : @"completedOn"
                                                         }];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"created.photos"
                                                                                             toKeyPath:@"photos"
                                                                                           withMapping:photosMapping];
    RKRelationshipMapping *moreRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"completed.photos"
                                                                                                 toKeyPath:@"completedPhotos"
                                                                                               withMapping:completedMapping];
    [punchlistMapping addPropertyMapping:relationshipMapping];
    [punchlistMapping addPropertyMapping:moreRelationshipMapping];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *punchlistDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:punchlistMapping method:RKRequestMethodAny pathPattern:@"punchlists" keyPath:@"rows" statusCodes:statusCodes];
    
    // For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
    // under the 'article' key path
    //RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:projectMapping objectClass:[BHProject class] rootKeyPath:nil method:RKRequestMethodAny];
    
    //[manager addRequestDescriptor:requestDescriptor];
    [SVProgressHUD showWithStatus:@"Fetching punchlist..."];
    [manager addResponseDescriptor:punchlistDescriptor];
    [manager getObjectsAtPath:@"punchlists" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [listItems removeAllObjects];
        for (id obj in mappingResult.array) {
            if ([obj isKindOfClass:[BHPunchlistItem class]]) [listItems addObject:(BHPunchlistItem*)obj];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return listItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PunchlistItemCell";
    BHPunchlistItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHPunchlistItemCell" owner:self options:nil] lastObject];
    }
    
    BHPunchlistItem *item = [listItems objectAtIndex:indexPath.row];
    [cell.itemLabel setText:item.name];
    if (item.photos.count) {
        [cell.photoButton setImageWithURL:[NSURL URLWithString:[[item.photos objectAtIndex:0] url200]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"]];
    } else {
        [cell.photoButton setImage:[UIImage imageNamed:@"BuildHawk_app_icon_120"] forState:UIControlStateNormal];
    }
    [cell.photoButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.photoButton.clipsToBounds = YES;
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
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
    [self performSegueWithIdentifier:@"PunchlistItem" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CreateItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setTitle:@"Create Punchlist Item"];
        [vc setNewItem:YES];
        [vc setPunchlistItem:[NSEntityDescription insertNewObjectForEntityForName:@"PunchlistItem" inManagedObjectContext:self.managedObjectContext]];
    } else if ([segue.identifier isEqualToString:@"PunchlistItem"]) {
        BHPunchlistItemViewController *vc = segue.destinationViewController;
        [vc setNewItem:NO];
        BHPunchlistItem *item = [listItems objectAtIndex:self.tableView.indexPathForSelectedRow.row];

        NSDate *parsedDate = [dateFormatter dateFromString:item.createdOn];
        NSDateFormatter *readableFormatter = [[NSDateFormatter alloc] init];
        [readableFormatter setDateStyle:NSDateFormatterShortStyle];
        [readableFormatter setTimeStyle:NSDateFormatterShortStyle];
        [vc setTitle:[NSString stringWithFormat:@"%@",[readableFormatter stringFromDate:parsedDate]]];
        [vc setPunchlistItem:item];
    }
        
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
