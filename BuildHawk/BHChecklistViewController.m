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
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "BHCategory.h"
#import "BHSubcategory.h"
#import "BHChecklist.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "Flurry.h"
#import "GAI.h"

typedef void(^OperationSuccess)(AFHTTPRequestOperation *operation, id result);
typedef void(^OperationFailure)(AFHTTPRequestOperation *operation, NSError *error);
typedef void(^RequestFailure)(NSError *error);
typedef void(^RequestSuccess)(id result);

@interface BHChecklistViewController () <UISearchBarDelegate, UISearchDisplayDelegate, RATreeViewDelegate, RATreeViewDataSource, UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *categories;
    NSMutableArray *filteredItems;
    NSMutableArray *listItems;
    NSMutableArray *completedListItems;
    NSMutableArray *inProgressListItems;
    BOOL completed;
    BOOL iPad;
    BOOL iPhone5;
    CGFloat itemRowHeight;
    CGRect screen;
    id checklistResponse;
}
@property (strong, nonatomic) id expanded;
@property (strong, nonatomic) BHChecklist *checklist;
-(IBAction)backToDashboard;
@end

@implementation BHChecklistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    screen = [[UIScreen mainScreen] bounds];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
        CGRect tableRect = self.treeView.frame;
        tableRect.size.height -= 88;
        [self.treeView setFrame:tableRect];
    }
    [self.treeView setContentInset:UIEdgeInsetsMake(0, 0, 87, 0)];
    itemRowHeight = 100;
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Checklists",[[(BHTabBarViewController*)self.tabBarController project] name]];
	[self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    if (!self.checklist) self.checklist = [[BHChecklist alloc] init];
    
    [self.treeView setDelegate:self];
    [self.treeView setDataSource:self];
    
    if (!categories) categories = [NSMutableArray array];
    if (!filteredItems) filteredItems = [NSMutableArray array];
    if (!listItems) listItems = [NSMutableArray array];
    if (!completedListItems) completedListItems = [NSMutableArray array];
    if (!inProgressListItems) inProgressListItems = [NSMutableArray array];
    [self loadChecklist];
    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
    [self.segmentedControl setSelectedSegmentIndex:0];
    //[self.view setBackgroundColor:kDarkShade1];
    //[self.treeView setBackgroundColor:kDarkShade1];
    [Flurry logEvent:@"Viewing checklist"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.screenName = @"Checklist view controller";
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self drawChecklistLimitActive:NO];
            break;
        case 1:
            [self filterActive];
            break;
        case 2:
            [self filterInProgress];
            break;
        case 3:
            [self filterCompleted];
            break;
        default:
            break;
    }
}

- (void)filterActive {
    [self drawChecklistLimitActive:YES];
}

- (void)filterInProgress {
    [inProgressListItems removeAllObjects];
    NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"status like %@",kInProgress];
    for (BHChecklistItem *item in listItems){
        if([testForTrue evaluateWithObject:item]) {
            [inProgressListItems addObject:item];
        }
    }
    self.checklist.children = inProgressListItems;
    [self.treeView reloadData];
}

- (void)filterCompleted {
    [completedListItems removeAllObjects];
    NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"completed == YES"];
    for (BHChecklistItem *item in listItems){
        if([testForTrue evaluateWithObject:item]) {
            [completedListItems addObject:item];
        }
    }
    self.checklist.children = completedListItems;
    [self.treeView reloadData];
}

- (void)loadChecklist {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@/checklists",kApiBaseUrl] parameters:@{@"pid":[[(BHTabBarViewController*)self.tabBarController project] identifier], @"tree":@"1"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"checklist response: %@",responseObject);
        checklistResponse = responseObject;
        [self drawChecklistLimitActive:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading checklist: %@",error.description);
    }];
}

- (void)drawChecklistLimitActive:(BOOL)onlyActive {
    [self.checklist.children removeAllObjects];
    for (id cat in [checklistResponse objectForKey:@"rows"]) {
        BHCategory *category = [[BHCategory alloc] init];
        NSLog(@"category order: %@",cat);
        [category setName:cat];
        NSMutableArray *children = [self parseSubcategoryIntoArray:[[checklistResponse objectForKey:@"rows"] valueForKey:cat] active:onlyActive];
        if (children.count) {
            [category setChildren:children];
            [categories addObject:category];
        }
    }
    self.checklist.children = categories;
    [self.treeView reloadData];
}

- (NSMutableArray *)parseSubcategoryIntoArray:(NSDictionary*)dict active:(BOOL)onlyActive {
    NSMutableArray *subcats = [NSMutableArray array];
    for (id obj in dict) {
        BHSubcategory *tempSubcat = [[BHSubcategory alloc] init];
        [tempSubcat setName:obj];
        NSMutableArray *children = [self itemsFromJSONArray:[dict valueForKey:obj] active:onlyActive];
        if (children.count){
            [tempSubcat setChildren:children];
            [listItems addObjectsFromArray:tempSubcat.children];
            [subcats addObject:tempSubcat];
        }
    }
    return subcats;
}
- (NSMutableArray *)itemsFromJSONArray:(NSMutableArray *)array active:(BOOL)onlyActive {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDict in array) {
        BHChecklistItem *item = [[BHChecklistItem alloc] initWithDictionary:itemDict];
        if (onlyActive && [item.status isEqualToString:kNotApplicable]) {
            
        } else {
            [items addObject:item];
        }
    }
    return items;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.treeView setSeparatorStyle:RATreeViewCellSeparatorStyleNone];
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
         
    } else if (treeNodeInfo.treeDepthLevel == 1) {
        cell.backgroundColor = kDarkShade2;
        [cell.textLabel setTextColor:[UIColor whiteColor]];
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    } else if (treeNodeInfo.treeDepthLevel == 2) {
        cell.backgroundColor = kDarkShade3;
        [cell.textLabel setTextColor:[UIColor whiteColor]];
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    }
}

#pragma mark TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    NSInteger numberOfChildren = [treeNodeInfo.children count];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:24]];
    [cell.textLabel setNumberOfLines:0];
    [cell.detailTextLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
    switch (treeNodeInfo.treeDepthLevel) {
        case 0:
            if ([item isKindOfClass:[BHCategory class]]) {
                cell.textLabel.text = ((BHCategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Subcategories %d", numberOfChildren];
            } else if ([item isKindOfClass:[BHChecklistItem class]]) {
                if ([[(BHChecklistItem*)item type] isEqualToString:@"Com"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
                } else if ([[(BHChecklistItem*)item type] isEqualToString:@"S&C"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutline"]];
                } else {
                    [cell.imageView setImage:[UIImage imageNamed:@"documentsOutline"]];
                }
                [cell.detailTextLabel setText:[(BHChecklistItem*)item subcategory]];
            }
            break;
        case 1:
            if ([item isKindOfClass:[BHSubcategory class]]) {
                cell.textLabel.text = ((BHSubcategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Items: %d", numberOfChildren];
            }
            break;
        default:
            cell.detailTextLabel.text = @"";
            break;
    }
    
    if ([item isKindOfClass:[BHChecklistItem class]]){
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = cell.frame;
        frame.size.height = itemRowHeight;
        frame.size.width = screen.size.width;
        [button setFrame:frame];
        [button setTag:[listItems indexOfObject:item]];
        [button addTarget:self action:@selector(dummySegue:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:button];
        cell.textLabel.text = [(BHChecklistItem*)item name];
        cell.textLabel.numberOfLines = 0;
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];

        if ([[(BHChecklistItem*)item type] isEqualToString:@"Com"]) {
            [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
        } else if ([[(BHChecklistItem*)item type] isEqualToString:@"S&C"]) {
            [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutline"]];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"documentsOutline"]];
        }
        
        if ([(BHChecklistItem*)item completed]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [cell setTintColor:[UIColor blackColor]];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
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
    } else return nil;
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
    BHChecklistItem *item;
    if (completed) {
        item = [completedListItems objectAtIndex:indexPath.row];
        [cell.textLabel setText:item.name];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryView.tintColor = [UIColor lightGrayColor];
    } else {
        item = [filteredItems objectAtIndex:indexPath.row];
        [cell.textLabel setText:item.name];
        [cell.textLabel setTextColor:kDarkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel setTextColor:kDarkGrayColor];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
    
    //set the image properly
    if ([item.type isEqualToString:@"Com"]) {
        [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
    } else if ([item.type isEqualToString:@"S&C"]) {
        [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutline"]];
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"documentsOutline"]];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return itemRowHeight;
}

- (CGFloat)treeView:(RATreeView *)treeView heightForRowForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo {
    if ([item isKindOfClass:[BHChecklistItem class]]) return itemRowHeight;
    else return 100;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        CGRect tableRect = self.treeView.frame;
        tableRect.size.height += 44;
        tableRect.origin.y -= 44;
        [self.treeView setFrame:tableRect];
        [self.segmentedControl setAlpha:0.0];
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
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
        [self.segmentedControl setAlpha:1.0];
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        BHChecklistItem *item = [filteredItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    }
}

- (void)treeView:(UITableView *)treeView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[self performSegueWithIdentifier:@"ShowSubcategories" sender:self];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredItems removeAllObjects]; // First clear the filtered array.
    for (BHChecklistItem *item in listItems){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:item.name]) {
            [filteredItems addObject:item];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (UITableViewCellEditingStyle)treeView:(RATreeView *)treeView editingStyleForRowForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo {
    return UITableViewCellEditingStyleNone;
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.searchDisplayController setActive:NO];
}

@end
