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
#import "Flurry.h"
//#import "GAI.h"
#import "Project.h"

@interface BHChecklistViewController () <UISearchBarDelegate, UISearchDisplayDelegate, RATreeViewDelegate, RATreeViewDataSource, UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *categories;
    NSMutableArray *filteredItems;
    NSMutableArray *listItems;
    NSMutableArray *completedListItems;
    NSMutableArray *inProgressListItems;
    BOOL iPad;
    BOOL iPhone5;
    BOOL iOS7;
    BHProject *project;
    CGFloat itemRowHeight;
    CGRect screen;
    id checklistResponse;
    Project *savedProject;
    AFHTTPRequestOperationManager *manager;
    NSIndexPath *indexPathToExpand;
}
@property (strong, nonatomic) id expanded;
@property (strong, nonatomic) BHChecklist *checklist;
-(IBAction)backToDashboard;
@end

@implementation BHChecklistViewController

- (void)viewDidLoad {
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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        iOS7 = YES;
        [self.treeView setContentInset:UIEdgeInsetsMake(0, 0, 87, 0)];
    } else {
        [self.treeView setFrame:CGRectMake(0, 6, screen.size.width, screen.size.height-113)];
        self.segmentedControl.transform = CGAffineTransformMakeTranslation(0, -8);
        [self.treeView setContentInset:UIEdgeInsetsMake(0, 0, 49, 0)];
        iOS7 = NO;
    }
    project = [(BHTabBarViewController*)self.tabBarController project];
    
    if ([(BHTabBarViewController*)self.tabBarController checklistIndexPath]){
        indexPathToExpand = [(BHTabBarViewController*)self.tabBarController checklistIndexPath];
    }
    
    if (!manager) manager = [AFHTTPRequestOperationManager manager];
    itemRowHeight = 110;
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Checklists",project.name];
	if (iOS7)[self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    
    [self.treeView setDelegate:self];
    [self.treeView setDataSource:self];
    
    if (!self.checklist) self.checklist = [[BHChecklist alloc] init];
    if (!categories) categories = [NSMutableArray array];
    if (!filteredItems) filteredItems = [NSMutableArray array];
    if (!listItems) listItems = [NSMutableArray array];
    if (!completedListItems) completedListItems = [NSMutableArray array];
    if (!inProgressListItems) inProgressListItems = [NSMutableArray array];
    
    [self loadChecklist];
    [ProgressHUD show:@"Loading Checklist..."];
    
    [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:NO];
    [self.segmentedControl setSelectedSegmentIndex:0];
    [Flurry logEvent:@"Viewing checklist"];
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", project.identifier];
    savedProject = [Project MR_findFirstWithPredicate:predicate inContext:localContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChecklist:) name:@"ReloadChecklist" object:nil];
}

- (void)reloadChecklist:(NSNotification*)notification {
    NSMutableArray *array = [NSMutableArray array];
    for (id cat in self.checklist.children){
        if ([cat isKindOfClass:[BHCategory class]] && [[(BHCategory*)cat name] isEqualToString:[notification.userInfo objectForKey:@"category"]]) {
            [array addObject:cat];
            break;
        }
    }
    [self.treeView reloadRowsForItems:array withRowAnimation:RATreeViewRowAnimationAutomatic];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //self.screenName = @"Checklist view controller";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self drawChecklistLimitActive:NO orCompleted:NO];
            break;
        case 1:
            [self drawChecklistLimitActive:YES orCompleted:NO];
            break;
        case 2:
            [self filterInProgress];
            break;
        case 3:
            [self drawChecklistLimitActive:NO orCompleted:YES];
            break;
        default:
            break;
    }
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

/*- (void)filterCompleted {
    [completedListItems removeAllObjects];
    NSPredicate *testForTrue = [NSPredicate predicateWithFormat:@"status like %@",kCompleted];
    for (BHChecklistItem *item in listItems){
        if([testForTrue evaluateWithObject:item]) {
            [completedListItems addObject:item];
        }
    }
    self.checklist.children = completedListItems;
    [self.treeView reloadData];
}*/

- (void)loadChecklist {
    [manager GET:[NSString stringWithFormat:@"%@/checklists/%@",kApiBaseUrl,project.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        checklistResponse = [[responseObject objectForKey:@"checklist"] objectForKey:@"categories"];
        //NSLog(@"checklist response: %@",responseObject);
        [self drawChecklistLimitActive:NO orCompleted:NO];
        if (self.isViewLoaded && self.view.window) {
            [ProgressHUD dismiss];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading checklist: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:nil message:@"We couldn't find a checklist associated with this project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [ProgressHUD dismiss];
    }];
}

- (void)drawChecklistLimitActive:(BOOL)onlyActive orCompleted:(BOOL)completed {
    [self.checklist.children removeAllObjects];
    for (id cat in checklistResponse) {
        BHCategory *category = [[BHCategory alloc] initWithDictionary:cat];
        NSMutableArray *children = [self parseSubcategoryIntoArray:[cat objectForKey:@"subcategories"] completed:completed active:onlyActive];
        if (children.count) {
            [category setChildren:children];
            [categories addObject:category];
        }
    }
    self.checklist.children = categories;
    [self.treeView reloadData];
}

- (NSMutableArray *)parseSubcategoryIntoArray:(NSArray*)array completed:(BOOL)completed active:(BOOL)onlyActive {
    NSMutableArray *subcats = [NSMutableArray array];
    for (id subcat in array) {
        BHSubcategory *tempSubcat = [[BHSubcategory alloc] initWithDictionary:subcat];
        NSMutableArray *children = [self itemsFromJSONArray:[subcat objectForKey:@"checklist_items"] completed:completed active:onlyActive];
        if (children.count){
            [tempSubcat setChildren:children];
            [listItems addObjectsFromArray:tempSubcat.children];
            [subcats addObject:tempSubcat];
        }
    }
    return subcats;
}

- (NSMutableArray *)itemsFromJSONArray:(NSMutableArray *)array completed:(BOOL)onlyCompleted active:(BOOL)onlyActive {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *itemDict in array) {
        BHChecklistItem *item = [[BHChecklistItem alloc] initWithDictionary:itemDict];
        if (onlyCompleted ) {
            if ([item.status isEqualToString:kCompleted]){
                [items addObject:item];
            }
        } else if (onlyActive) {
            if (![item.status isEqualToString:kNotApplicable] && ![item.status isEqualToString:kCompleted]) {
                [items addObject:item];
            }
        } else {
            [items addObject:item];
        }
    }
    return items;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.treeView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    [self.treeView setSeparatorStyle:RATreeViewCellSeparatorStyleSingleLine];
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
    if (treeNodeInfo.treeDepthLevel == 1) {
        cell.backgroundColor = kLightBlueColor;
        if ([[(BHSubcategory*)item status] isEqualToString:kCompleted]) {
            
        } else if ([[(BHSubcategory*)item status] isEqualToString:kInProgress]) {
            
        } else {
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
        }
    } else if (treeNodeInfo.treeDepthLevel == 2) {
        if ([[(BHChecklistItem*)item photosCount] intValue] > 0) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"miniCamera"]];
        } else if ([(BHChecklistItem*)item commentsCount] > 0) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"miniChat"]];
        } else {
            cell.accessoryView = UITableViewCellAccessoryNone;
        }
        cell.backgroundColor = kBlueColor;
        if ([[(BHChecklistItem*)item status] isEqualToString:kCompleted]) {
            [cell.textLabel setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
            [cell.detailTextLabel setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
            [cell.accessoryView setAlpha:.5];
        } else if ([[(BHChecklistItem*)item status] isEqualToString:kInProgress]) {
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
        } else if ([[(BHChecklistItem*)item status] isEqualToString:kNotApplicable]) {
            [cell.textLabel setTextColor:[UIColor colorWithWhite:1 alpha:.25]];
            [cell.detailTextLabel setTextColor:[UIColor colorWithWhite:1 alpha:.25]];
        } else {
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
        }
    }
    if (indexPathToExpand/* && item == [self.checklist.children objectAtIndex:indexPathToExpand.row]*/) {
        [self.treeView scrollToRowForItem:[self.checklist.children objectAtIndex:indexPathToExpand.row] atScrollPosition:RATreeViewScrollPositionTop animated:YES];
        //[self.treeView expandRowForItem:item withRowAnimation:RATreeViewRowAnimationAutomatic];
        indexPathToExpand = nil;
    }
}

#pragma mark TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    
    NSInteger numberOfChildren = [treeNodeInfo.children count];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:24]];
    [cell.textLabel setNumberOfLines:5];
    [cell.detailTextLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
    switch (treeNodeInfo.treeDepthLevel) {
        case 0:
            if ([item isKindOfClass:[BHCategory class]]) {
                cell.textLabel.text = ((BHCategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Subcategories %ld", (long)numberOfChildren];
                UILabel *progressPercentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 22)];
                [progressPercentageLabel setTextColor:[UIColor lightGrayColor]];
                [progressPercentageLabel setText:((BHCategory *)item).progressPercentage];
                [progressPercentageLabel setTextAlignment:NSTextAlignmentRight];
                progressPercentageLabel.clipsToBounds = NO;
                [progressPercentageLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
                cell.accessoryView = progressPercentageLabel;
                
            } else if ([item isKindOfClass:[BHChecklistItem class]]) {
                [cell.detailTextLabel setText:[(BHChecklistItem*)item subcategory]];
            }
            break;
        case 1:
            if ([item isKindOfClass:[BHSubcategory class]]) {
                cell.textLabel.text = ((BHSubcategory *)item).name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Items: %ld", (long)numberOfChildren];
                UILabel *progressPercentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 22)];
                [progressPercentageLabel setTextColor:[UIColor whiteColor]];
                [progressPercentageLabel setText:((BHSubcategory *)item).progressPercentage];
                [progressPercentageLabel setTextAlignment:NSTextAlignmentRight];
                progressPercentageLabel.clipsToBounds = NO;
                [progressPercentageLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:16]];
                cell.accessoryView = progressPercentageLabel;
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
        cell.textLabel.text = [(BHChecklistItem*)item body];
        cell.textLabel.numberOfLines = 5;
        [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];

        if (treeNodeInfo.treeDepthLevel == 2){
            if ([[(BHChecklistItem*)item type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
            } else if ([[(BHChecklistItem*)item type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutline"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"documentsOutline"]];
            }
        } else {
            if ([[(BHChecklistItem*)item type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
            } else if ([[(BHChecklistItem*)item type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
            }
        }
        
        if ([[(BHChecklistItem*)item status] isEqualToString:kCompleted]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryView.tintColor = [UIColor whiteColor];
            if (iOS7)[cell setTintColor:[UIColor whiteColor]];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            [cell.imageView setAlpha:.5];
        } else if([[(BHChecklistItem*)item status] isEqualToString:kInProgress]) {
            if (iOS7)[cell setTintColor:[UIColor colorWithWhite:1 alpha:.5]];
        } else if([[(BHChecklistItem*)item status] isEqualToString:kNotApplicable]) {
            [cell.imageView setImage:[UIImage imageNamed:@"naImage"]];
            if (iOS7)[cell setTintColor:[UIColor colorWithWhite:1 alpha:.25]];
            [cell.imageView setAlpha:.25];
        }
        
        if ([[(BHChecklistItem*)item photosCount] intValue] > 0) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"miniCamera"]];
        } else if ([(BHChecklistItem*)item commentsCount] > 0) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"miniChat"]];
        } else {
            cell.accessoryView = UITableViewCellAccessoryNone;
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
        BHChecklistItem *item = (BHChecklistItem*)sender;
        BHChecklistItemViewController *vc = segue.destinationViewController;
        [vc setItem:item];
        [vc setProject:project];
        [vc setSavedProject:savedProject];
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
    BHChecklistItem *item = [filteredItems objectAtIndex:indexPath.row];
    [cell.textLabel setText:item.body];
    if ([item.status isEqualToString:kCompleted]) {
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryView.tintColor = [UIColor lightGrayColor];
    } else {
        [cell.textLabel setTextColor:kDarkGrayColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.numberOfLines = 5;
    [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
    
    //set the image properly
    if ([item.type isEqualToString:@"Com"]) {
        [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
    } else if ([item.type isEqualToString:@"S&C"]) {
        [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
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
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.segmentedControl setAlpha:0.0];
        //self.treeView.transform = CGAffineTransformMakeTranslation(0, -44);
    }];
}

- (void)dismissTableView {
    [self.searchDisplayController setActive:NO animated:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.segmentedControl setAlpha:1.0];
        self.treeView.transform = CGAffineTransformIdentity;
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
        if([predicate evaluateWithObject:item.body]) {
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
- (void)viewWillDisappear:(BOOL)animated {
    //[manager.operationQueue cancelAllOperations];
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

@end
