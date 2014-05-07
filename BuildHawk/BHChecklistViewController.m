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
#import "Cat.h"
#import "Cat+helper.h"
#import "Subcat+helper.h"
#import "Subcat.h"
#import "ChecklistItem.h"
#import "ChecklistItem+helper.h"
#import "Constants.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "Cat.h"
#import "Subcat.h"
#import "Checklist.h"
#import "Flurry.h"
//#import "GAI.h"
#import "Project.h"
#import "BHOverlayView.h"
#import "UIImage+ImageEffects.h"
#import "BHAppDelegate.h"
#import "BHChecklistCell.h"
#import "Checklist+helper.h"

@interface BHChecklistViewController () <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> {
    UIRefreshControl *refreshControl;
    NSMutableArray *filteredItems;
    NSMutableArray *listItems;
    NSMutableOrderedSet *allCategories;
    NSMutableOrderedSet *activeCategories;
    NSMutableOrderedSet *completedCategories;
    NSMutableOrderedSet *inProgressCategories;
    BOOL iPad;
    BOOL iPhone5;
    BOOL iOS7;
    BOOL shouldSave;
    Project *project;
    CGFloat itemRowHeight;
    CGRect screen;
    Project *savedProject;
    AFHTTPRequestOperationManager *manager;
    NSIndexPath *indexPathToExpand;
    UIView *initialOverlayBackground;
    UIView *overlayBackground;
    UIImageView *checklistScreenshot;
    NSMutableDictionary *rowDictionary;
    NSManagedObjectContext *localContext;
    NSManagedObjectContext *itemContext;
}

@property (strong, nonatomic) id expanded;
@property (strong, nonatomic) Checklist *checklist;

-(IBAction)backToDashboard;
@end

@implementation BHChecklistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    screen = [[UIScreen mainScreen] bounds];
    if (IDIOM == IPAD) {
        iPad = YES;
    } else if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
        iPad = NO;
    } else {
        iPad = NO;
        iPhone5 = NO;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        iOS7 = YES;
    } else {
        self.segmentedControl.transform = CGAffineTransformMakeTranslation(0, -8);
        iOS7 = NO;
    }
    
    project = [(BHTabBarViewController*)self.tabBarController project];
    
    if ([(BHTabBarViewController*)self.tabBarController checklistIndexPath]){
        indexPathToExpand = [(BHTabBarViewController*)self.tabBarController checklistIndexPath];
    }
    
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    rowDictionary = [NSMutableDictionary dictionary];
    itemRowHeight = 110;
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Checklists",project.name];
	if (iOS7)[self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];

    localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    
    filteredItems = [NSMutableArray array];
    listItems = [NSMutableArray array];
    completedCategories = [NSMutableOrderedSet orderedSet];
    inProgressCategories = [NSMutableOrderedSet orderedSet];
    activeCategories = [NSMutableOrderedSet orderedSet];
    
    _checklist = [Checklist MR_findFirstByAttribute:@"project.identifier" withValue:project.identifier];
    if (!_checklist){
        _checklist = [Checklist MR_createEntity];
        _checklist.project = project;
        [self loadChecklist];
    } else {
        for (Cat *category in _checklist.categories){
            category.expanded = [NSNumber numberWithBool:NO];
        }
        allCategories = [NSMutableOrderedSet orderedSetWithOrderedSet:_checklist.categories];
        [self.tableView reloadData];
    }
    
    [self.segmentedControl setSelectedSegmentIndex:0];
    [Flurry logEvent:@"Viewing checklist"];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChecklist:) name:@"ReloadChecklist" object:nil];
}

- (void)reloadChecklist:(NSNotification*)notification {
    NSLog(@"notification: %@",notification);
//    NSMutableArray *array = [NSMutableArray array];
//    for (id cat in self.checklist.categories){
//        if ([cat isKindOfClass:[Cat class]] && [[(Cat*)cat name] isEqualToString:[notification.userInfo objectForKey:@"category"]]) {
//            [array addObject:cat];
//            break;
//        }
//    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //self.screenName = @"Checklist view controller";
    /*if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenChecklist]){
        initialOverlayBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), screenHeight()-49)];
        [initialOverlayBackground setAlpha:0.0];
        [initialOverlayBackground setBackgroundColor:[UIColor colorWithPatternImage:[self focusTabBar]]];
        [[[UIApplication sharedApplication].delegate window] addSubview:initialOverlayBackground];
        [UIView animateWithDuration:.25 animations:^{
            [initialOverlayBackground setAlpha:1.0];
        }];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenDashboard];
    } else {
        [ProgressHUD show:@"Loading Checklist..."];
    }*/
}
-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self resetChecklist];
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

- (void)resetChecklist {
    _checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:_checklist.identifier];
    NSLog(@"resetting checklist: %@",_checklist);
    shouldSave = YES;
    [self.tableView reloadData];
}

- (void)filterActive {
    shouldSave = NO;
    activeCategories = [NSMutableOrderedSet orderedSetWithOrderedSet:allCategories];
    
    NSPredicate *testForFalse = [NSPredicate predicateWithFormat:@"status != %@",kInProgress];
    for (Cat *category in activeCategories){
        for (Subcat *subcategory in category.subcategories){
            for (ChecklistItem *item in subcategory.items){
                if([testForFalse evaluateWithObject:item]) {
                    NSLog(@"active item status: %@",item.status);
                    [subcategory removeItem:item];
                }
            }
            if (subcategory.items.count == 0) [category removeSubcategory:subcategory];
        }
        //if (category.subcategories.count == 0) [completedCategories removeObject:category];
    }
    [_checklist setCategories:activeCategories];
    [self.tableView reloadData];
}

- (void)filterInProgress {
    shouldSave = NO;
    inProgressCategories = allCategories.mutableCopy;
    
    NSPredicate *testForFalse = [NSPredicate predicateWithFormat:@"status != %@",kInProgress];
    for (Cat *category in inProgressCategories){
        for (Subcat *subcategory in category.subcategories){
            for (ChecklistItem *item in subcategory.items){
                if([testForFalse evaluateWithObject:item]) {
                    NSLog(@"in progress item status: %@",item.status);
                    [subcategory removeItem:item];
                }
            }
            if (subcategory.items.count == 0) [category removeSubcategory:subcategory];
        }
        //if (category.subcategories.count == 0) [completedCategories removeObject:category];
    }
    [_checklist setCategories:inProgressCategories];
    [self.tableView reloadData];
}

- (void)filterCompleted {
    shouldSave = NO;
    completedCategories = [[NSMutableOrderedSet alloc] initWithOrderedSet:allCategories];
    NSLog(@"completed: %@ and the other %@",completedCategories, allCategories);
    NSPredicate *testForFalse = [NSPredicate predicateWithFormat:@"status != %@",kCompleted];
    for (Cat *category in completedCategories){
        for (Subcat *subcategory in category.subcategories){
            
            for (ChecklistItem *item in subcategory.items){
                if([testForFalse evaluateWithObject:item]) {
                    NSLog(@"completed item status: %@",item.status);
                    [subcategory removeItem:item];
                }
            }
            if (subcategory.items.count == 0) [category removeSubcategory:subcategory];
        }
        //if (category.subcategories.count == 0) [completedCategories removeObject:category];
    }
    [_checklist setCategories:completedCategories];
    [self.tableView reloadData];
}


- (void)handleRefresh {
    [self loadChecklist];
}

- (void)loadChecklist {
    [ProgressHUD show:@"Refreshing checklist..."];
    [manager GET:[NSString stringWithFormat:@"%@/checklists/%@",kApiBaseUrl,project.identifier] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"checklist response: %@",[responseObject objectForKey:@"checklist"]);
    
        _checklist.identifier = [[responseObject objectForKey:@"checklist"] objectForKey:@"id"];
        [self drawChecklist:[[responseObject objectForKey:@"checklist"] objectForKey:@"categories"]];
        [ProgressHUD dismiss];
        
        //[localContext MR_saveOnlySelfAndWait];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading checklist: %@",error.description);
        [[[UIAlertView alloc] initWithTitle:nil message:@"We couldn't find a checklist associated with this project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
    }];
}

- (void)drawChecklist:(id)array {
    NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSet];
    for (id cat in array) {
        NSLog(@"cat dictionary: %@",cat);
        Cat *category = [Cat MR_findFirstByAttribute:@"identifier" withValue:[cat objectForKey:@"id"]];
        if (!category){
            category = [Cat MR_createEntity];
        }
        [category populateFromDictionary:cat];
        category.checklist = _checklist;
        [categories addObject:category];
    }
    //NSLog(@"drawing new categories: %@",categories);
    _checklist.categories = categories;
    [self.tableView reloadData];
    shouldSave = YES;
    allCategories = categories;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        ChecklistItem *item = (ChecklistItem*)sender;
        BHChecklistItemViewController *vc = segue.destinationViewController;
        [vc setItem:item];
        [vc setProject:project];
        [vc setProject:savedProject];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else return _checklist.categories.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return filteredItems.count;
    else {
        Cat *category = [_checklist.categories objectAtIndex:section];
        if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            
            int count = category.subcategories.count + 1;
            for (Subcat *subcategory in category.subcategories){
                if ([subcategory.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    count += subcategory.items.count;
                }
            }
            
            return count;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ItemCell"];
        ChecklistItem *item = [filteredItems objectAtIndex:indexPath.row];
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
    } else {
        BHChecklistCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChecklistCell" owner:self options:nil] lastObject];
        }
        [cell.mainLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:24]];
        [cell.mainLabel setNumberOfLines:5];
        [cell.detailLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:15]];
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.backgroundView = backgroundView;
        Cat *category = [_checklist.categories objectAtIndex:indexPath.section];
        
        if (indexPath.row == 0){
            cell.level = [NSNumber numberWithInt:0];
            [cell.mainLabel setText:category.name];
            [cell.detailLabel setText:[NSString stringWithFormat:@"Categories: %i",category.subcategories.count]];
            [cell.photoImageView setHidden:YES];
            UILabel *progressLabel = [[UILabel alloc] init];
            [progressLabel setTextColor:[UIColor lightGrayColor]];
            [progressLabel setText:category.progressPercentage];
            cell.accessoryView = progressLabel;
            [backgroundView setBackgroundColor:[UIColor whiteColor]];
            
        } else if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            NSMutableOrderedSet *openRows = [rowDictionary objectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            id item = [openRows.array objectAtIndex:indexPath.row-1];
            if ([item isKindOfClass:[Subcat class]]){
                Subcat *subcategory = (Subcat*)item;
                [cell.mainLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:22]];
                [cell.mainLabel setTextColor:[UIColor whiteColor]];
                [cell.mainLabel setText:[NSString stringWithFormat:@" %@",subcategory.name]];
                [cell.detailLabel setText:[NSString stringWithFormat:@"  Items: %i",subcategory.items.count]];
                [cell.detailLabel setTextColor:[UIColor whiteColor]];
                [cell.photoImageView setHidden:YES];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [backgroundView setBackgroundColor:kLightBlueColor];
            } else {
                ChecklistItem *item = [openRows.array objectAtIndex:indexPath.row-1];
                [cell.itemBody setText:item.body];
                [cell.itemBody setFont:[UIFont fontWithName:kHelveticaNeueLight size:17]];
                [backgroundView setBackgroundColor:kBlueColor];
                
                if ([item.status isEqualToString:kCompleted]){
                    [cell.itemBody setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [cell.itemBody setTextColor:[UIColor whiteColor]];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                
                if ([item.photosCount compare:[NSNumber numberWithInt:0]] == NSOrderedDescending) {
                    [cell.photoImageView setHidden:NO];
                } else {
                    [cell.photoImageView setHidden:YES];
                }
                
                //set the image properly
                if ([item.type isEqualToString:@"Com"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"communicateOutline"]];
                } else if ([item.type isEqualToString:@"S&C"]) {
                    [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutline"]];
                } else {
                    [cell.imageView setImage:[UIImage imageNamed:@"documentsOutline"]];
                }
            }
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return itemRowHeight;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.segmentedControl setAlpha:0.0];
    }];
}

- (void)dismissTableView {
    [self.searchDisplayController setActive:NO animated:YES];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.segmentedControl setAlpha:1.0];
    }];
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        ChecklistItem *item = [filteredItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    } else {
        Cat *category = [_checklist.categories objectAtIndex:indexPath.section];
        
        if (indexPath.row == 0){
            if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                category.expanded = [NSNumber numberWithBool:NO];
                [rowDictionary removeObjectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            } else {
                category.expanded = [NSNumber numberWithBool:YES];
                [rowDictionary setObject:category.subcategories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            }
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            
            NSMutableOrderedSet *openRows = [rowDictionary objectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            id item = [openRows objectAtIndex:indexPath.row-1];
            if ([item isKindOfClass:[Subcat class]]){
                Subcat *subcategory = [openRows objectAtIndex:indexPath.row-1];
                
                if ([subcategory.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    
                    NSMutableArray *deleteIndexPaths = [NSMutableArray array];
                    int subIdx = [openRows indexOfObject:subcategory];
                    
                    for (int idx = subIdx; idx < (subcategory.items.count+subIdx); idx ++){
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx+2 inSection:indexPath.section];
                        [deleteIndexPaths addObject:newIndexPath];
                    }
                    
                    [openRows removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([openRows indexOfObject:subcategory]+1, subcategory.items.count)]];
                    
                    subcategory.expanded = [NSNumber numberWithBool:NO];
                    [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                } else {

                    subcategory.expanded = [NSNumber numberWithBool:YES];
                    NSMutableArray *newIndexPaths = [NSMutableArray array];
                    int subIdx = [openRows indexOfObject:subcategory];
                    int itemIdx = 0;
                    for (int idx = subIdx; idx < (subcategory.items.count+subIdx); idx ++){
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx+2 inSection:indexPath.section];
                        [newIndexPaths addObject:newIndexPath];
                        [openRows insertObject:[subcategory.items objectAtIndex:itemIdx] atIndex:idx+1];
                        itemIdx++;
                    }
                    
                    [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];

                }
                
            } else {
                ChecklistItem *item = [openRows objectAtIndex:indexPath.row-1];
                [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredItems removeAllObjects]; // First clear the filtered array.
    for (ChecklistItem *item in listItems){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:item.body]) {
            [filteredItems addObject:item];
            NSLog(@"adding item to filtereditems; %@",item);
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:nil];
    
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //[self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
    //[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}


#pragma mark Intro Stuff

-(UIImage *)focusTabBar {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, self.view.window.screen.scale);
    [[[UIApplication sharedApplication].delegate window] drawViewHierarchyInRect:CGRectMake(0, 0, screenWidth(), screenHeight()) afterScreenUpdates:YES];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)slide1 {
    BHOverlayView *navigation = [[BHOverlayView alloc] initWithFrame:screen];
    if (iPad){
        [navigation configureText:@"Now that you're in a project, the bottom menu bar will help you navigate through each section." atFrame:CGRectMake(screenWidth()/2-150, screenHeight()-310, 300, 100)];
    } else {
        [navigation configureText:@"Now that you're in a project, the bottom menu bar will help you navigate through each section." atFrame:CGRectMake(20, screenHeight()-300, screenWidth()-40, 100)];
    }
    
    [navigation.label setTextAlignment:NSTextAlignmentCenter];
    [navigation configureArrow:[UIImage imageNamed:@"downWhiteArrow"] atFrame:CGRectMake(screenWidth()/2-25, screenHeight()-200, 50, 110)];
    [navigation.tapGesture addTarget:self action:@selector(slide2:)];
    [initialOverlayBackground addSubview:navigation];
    [UIView animateWithDuration:.25 animations:^{
        [navigation setAlpha:1.0];
    }];
}


- (void)slide2:(UITapGestureRecognizer*)sender {
    BHOverlayView *checklist = [[BHOverlayView alloc] initWithFrame:screen];
    if (iPad){
        checklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checklistiPad"]];
        [checklistScreenshot setFrame:CGRectMake(screenWidth()/2-355, 26, 710, 505)];
    } else {
        checklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checklistScreenshot"]];
        [checklistScreenshot setFrame:CGRectMake(screenWidth()/2-150, 26, 300, 350)];
    }
    [checklistScreenshot setAlpha:0.0];
    
    [checklist configureText:@"The first section is the checklist.\n\n Search for specific items or use the filters to quickly prioritize." atFrame:CGRectMake(10, screenHeight()/2+100, screenWidth()-20, 120)];
    [checklist.tapGesture addTarget:self action:@selector(slide3:)];
    [checklist.label setTextAlignment:NSTextAlignmentCenter];
    
    [UIView animateWithDuration:.35 animations:^{
        
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlay];
        [overlayBackground addSubview:checklistScreenshot];
        [overlayBackground addSubview:checklist];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        
        [UIView animateWithDuration:.25 animations:^{
            [initialOverlayBackground setAlpha:0.0];
            [checklist setAlpha:1.0];
            [checklistScreenshot setAlpha:1.0];
        } completion:^(BOOL finished) {
            [initialOverlayBackground removeFromSuperview];
        }];
    }];
}

- (void)slide3:(UITapGestureRecognizer*)sender {
    BHOverlayView *tapToExpand = [[BHOverlayView alloc] initWithFrame:screen];
    [tapToExpand configureText:@"Tap any section to hide or expand the checklist items within." atFrame:CGRectMake(10, screenHeight()/2+100, screenWidth()-20, 100)];
    [tapToExpand.tapGesture addTarget:self action:@selector(endIntro:)];
    [tapToExpand.label setTextAlignment:NSTextAlignmentCenter];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:tapToExpand];
        [UIView animateWithDuration:.25 animations:^{
            [tapToExpand setAlpha:1.0];
            [checklistScreenshot setAlpha:1.0];
        }];
    }];
}

- (void)endIntro:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.35 animations:^{
        [checklistScreenshot setAlpha:0.0];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.35 animations:^{
            [overlayBackground setAlpha:0.0];
        }completion:^(BOOL finished) {
            [overlayBackground removeFromSuperview];
        }];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    if (shouldSave)[self saveContext];
    [super viewWillDisappear:animated];
}

- (void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"What happened during checklist save? %hhd %@",success, error);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
