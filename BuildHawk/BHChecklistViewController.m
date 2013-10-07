//
//  BHChecklistViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistViewController.h"
#import "BHCategoryChecklistViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHTabBarViewController.h"
#import "BHCategory.h"
#import "BHSubcategory.h"
#import "BHChecklistItem.h"
#import "Constants.h"
#import "RADataObject.h"
#import <RestKit/RestKit.h>
#import "BHCategory.h"
#import "BHSubcategory.h"
#import "BHChecklist.h"
#import <SVProgressHUD/SVProgressHUD.h>

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHChecklistViewController () <UISearchBarDelegate, UISearchDisplayDelegate, RATreeViewDelegate, RATreeViewDataSource, UITableViewDataSource, UITableViewDelegate> {

    NSMutableArray *categories;
    NSMutableArray *filteredItems;
    NSMutableArray *listItems;
    NSMutableArray *completedListItems;
    BOOL completed;
}
@property (strong, nonatomic) id expanded;
@property (strong, nonatomic) BHChecklist *checklist;
-(IBAction)backToDashboard;
@end

@implementation BHChecklistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Checklists",[[(BHTabBarViewController*)self.tabBarController project] name]];
	[self.segmentedControl setTintColor:kBlueColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    if (!self.checklist) self.checklist = [[BHChecklist alloc] init];
    
    [self.treeView setDelegate:self];
    [self.treeView setDataSource:self];
    
    if (!categories) categories = [NSMutableArray array];
    if (!filteredItems) filteredItems = [NSMutableArray array];
    if (!listItems) listItems = [NSMutableArray array];
    if (!completedListItems) completedListItems = [NSMutableArray array];
    [self loadChecklist];
    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadChecklistRestkit {
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *checklistItemMapping = [RKObjectMapping mappingForClass:[BHChecklistItem class]];
    [checklistItemMapping addAttributeMappingsFromArray:@[@"category", @"subcategory", @"name"]];
    [checklistItemMapping addAttributeMappingsFromDictionary:@{
                                                           @"_id" : @"identifier",
                                                           }];
    //for core data
    //checklistItemMapping.identificationAttributes@[@"identifier"];
    
   /*RKRelationshipMapping *subcategoryMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"subcategory"
                                                                                         toKeyPath:@"subcategory"
                                                                                       withMapping:checklistItemMapping];
    [checklistMapping addPropertyMapping:categoryMapping];*/

    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *itemsDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:checklistItemMapping method:RKRequestMethodAny pathPattern:@"checklists" keyPath:@"rows" statusCodes:statusCodes];
    
    // For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
    // under the 'article' key path
    //RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:projectMapping objectClass:[BHProject class] rootKeyPath:nil method:RKRequestMethodAny];
    
    //[manager addRequestDescriptor:requestDescriptor];
    [SVProgressHUD showWithStatus:@"Fetching checklist..."];
    [manager addResponseDescriptor:itemsDescriptor];
    [manager getObjectsAtPath:@"checklists" parameters:@{@"project_id":@"5220ffee313d263435000001"} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"mapping result for checklist: %@",mappingResult.array);
        //checklist.listItems = [mappingResult.array mutableCopy];
                [self.treeView reloadData];
        [SVProgressHUD dismiss];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching checklist: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    NSLog(@"sender: %i",sender.selectedSegmentIndex);
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.checklist.children = categories;
            [self.treeView reloadData];
            break;
        case 1:
            
            break;
        case 2:
            [self filterCompleted];
            break;
        default:
            break;
    }
    
}

- (void)filterCompleted {
    
    NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"completed == YES"];
    for (BHChecklistItem *item in listItems){
        if([testForTrue evaluateWithObject:item]) {
            [completedListItems addObject:item];
        }
    }
    self.checklist.children = completedListItems;
    [self.treeView reloadData];
}

- (AFJSONRequestOperation*)loadChecklist {
    AFHTTPClient *checklistClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.buildhawk.com/api/v1"]];
    [checklistClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [checklistClient setDefaultHeader:@"Accept" value:@"application/json"];
    
    OperationFailure opFailure = ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to get the checklist: %@",error.description);
    };
    
    OperationSuccess opSuccess = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        for (id cat in [responseObject objectForKey:@"rows"]) {
            BHCategory *category = [[BHCategory alloc] init];
            [category setName:cat];
            [category setChildren:[self parseSubcategoryIntoArray:[[responseObject objectForKey:@"rows"] valueForKey:cat]]];
            [categories addObject:category];
        }
        self.checklist.children = categories;
        [self.treeView reloadData];
    };
   
    NSMutableURLRequest *request = [checklistClient requestWithMethod:@"GET" path:@"checklists" parameters:@{@"project_id":@"5220ffee313d263435000001", @"tree":@"1"}];
    
    AFJSONRequestOperation *op = (AFJSONRequestOperation *)[checklistClient HTTPRequestOperationWithRequest:request
                                                                                                  success:opSuccess
                                                                                                  failure:opFailure];
    [op start];
    return op;
}

- (void)parseListItems:(NSDictionary*)dict {
    
}

- (NSMutableArray *)parseSubcategoryIntoArray:(NSDictionary*)dict {
    NSMutableArray *subcats = [NSMutableArray array];
    for (id obj in dict) {
        BHSubcategory *tempSubcat = [[BHSubcategory alloc] init];
        [tempSubcat setName:obj];
        [tempSubcat setChildren:[self itemsFromJSONArray:[dict valueForKey:obj]]];
        [listItems addObjectsFromArray:tempSubcat.children];
        [subcats addObject:tempSubcat];
    }
    return subcats;
}
- (NSMutableArray *)itemsFromJSONArray:(NSMutableArray *) array {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDict in array) {
        BHChecklistItem *item = [[BHChecklistItem alloc] initWithDictionary:itemDict];
        [items addObject:item];
    }
    return items;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.treeView reloadData];
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (NSInteger)treeView:(RATreeView *)treeView indentationLevelForRowForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    return 1 * treeNodeInfo.treeDepthLevel;
}

- (BOOL)treeView:(RATreeView *)treeView shouldExpandItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    return YES;
}

- (BOOL)treeView:(RATreeView *)treeView shouldItemBeExpandedAfterDataReload:(id)item treeDepthLevel:(NSInteger)treeDepthLevel
{
    if ([item isEqual:self.expanded]) {
        return YES;
    }
    return NO;
}

- (void)treeView:(RATreeView *)treeView willDisplayCell:(UITableViewCell *)cell forItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    if (treeNodeInfo.treeDepthLevel == 0) {
        cell.backgroundColor = [UIColor clearColor];
    } else if (treeNodeInfo.treeDepthLevel == 1) {
        cell.backgroundColor = kLightestGrayColor;
    } else if (treeNodeInfo.treeDepthLevel == 2) {
        cell.backgroundColor = kLighterGrayColor;
    }
}

#pragma mark TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    NSInteger numberOfChildren = [treeNodeInfo.children count];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    
    switch (treeNodeInfo.treeDepthLevel) {
        case 0:
            if ([item isKindOfClass:[BHCategory class]]) {
                cell.textLabel.text = ((BHCategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Subcategories %d", numberOfChildren];
            }
            break;
        case 1:
            if ([item isKindOfClass:[BHSubcategory class]]) {
                cell.textLabel.text = ((BHSubcategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Items: %d", numberOfChildren];
            }
            break;
        case 2:
            [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
        default:
            cell.detailTextLabel.text = @"";
            break;
    }
    
    if ([item isKindOfClass:[BHChecklistItem class]]){
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:cell.frame];
        [button setTag:[listItems indexOfObject:item]];
        [button addTarget:self action:@selector(dummySegue:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:button];
        cell.textLabel.text = [(BHChecklistItem*)item name];
        if ([(BHChecklistItem*)item completed]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [cell setTintColor:[UIColor blackColor]];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            [cell.imageView setAlpha:.25];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (treeNodeInfo.treeDepthLevel == 0) {
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)dummySegue:(UIButton*)button{
    BHChecklistItem *item = [listItems objectAtIndex:button.tag];
    [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        BHChecklistItemViewController *vc = segue.destinationViewController;
        [vc setItem:(BHChecklistItem*)sender];
    }
}

- (NSInteger)treeView:(RATreeView *)treeView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.checklist.children count];
    }
    if ([item isKindOfClass:[BHCategory class]]) {
        return [[(BHCategory*)item children] count];
    } else {
        return [[(BHSubcategory*)item children] count];
    }
}

- (id)treeView:(RATreeView *)treeView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [self.checklist.children objectAtIndex:index];
    }
    if ([item isKindOfClass:[BHCategory class]]) {
        return [[(BHCategory*)item children] objectAtIndex:index];
    } else if ([item isKindOfClass:[BHSubcategory class]]){
        return [[(BHSubcategory*)item children] objectAtIndex:index];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return filteredItems.count;
    else return categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ItemCell"];
    if (completed) [cell.textLabel setText:[[completedListItems objectAtIndex:indexPath.row] name]];
    else [cell.textLabel setText:[[filteredItems objectAtIndex:indexPath.row] name]];
    [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (CGFloat)treeView:(RATreeView *)treeView heightForRowForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo {
    return 66;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        CGRect tableRect = self.treeView.frame;
        tableRect.size.height += 44;
        tableRect.origin.y -= 44;
        [self.treeView setFrame:tableRect];
    }];
}

- (void)dismissTableView {
    [self.searchDisplayController setActive:NO animated:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.searchDisplayController.searchBar.transform = CGAffineTransformIdentity;
        self.segmentedControl.transform = CGAffineTransformIdentity;
        CGRect tableRect = self.treeView.frame;
        tableRect.size.height -= 44;
        tableRect.origin.y += 44;
        [self.treeView setFrame:tableRect];
    }];
}

#pragma mark - Table view delegate

- (void)treeView:(UITableView *)treeView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"do something");
    //[self performSegueWithIdentifier:@"ShowSubcategories" sender:self];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredItems removeAllObjects]; // First clear the filtered array.
    NSLog(@"checklist search text: %@",searchText);
    for (BHChecklistItem *item in listItems){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:item.name]) {
            NSLog(@"able to add %@",item.name);
            [filteredItems addObject:item];
        }
    }
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:nil];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
    //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}

@end
