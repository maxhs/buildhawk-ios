//
//  BHChecklistViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHChecklistViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHTabBarViewController.h"
#import "Phase+helper.h"
#import "Cat+helper.h"
#import "ChecklistItem+helper.h"
#import "Constants.h"
#import "Checklist.h"
#import "Flurry.h"
#import "Project.h"
#import "BHOverlayView.h"
#import "UIImage+ImageEffects.h"
#import "BHAppDelegate.h"
#import "BHChecklistCell.h"
#import "Checklist+helper.h"
//#import "GAI.h"

@interface BHChecklistViewController () <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> {
    Project *project;
    UIRefreshControl *refreshControl;
    NSMutableArray *filteredItems;
    BOOL iPhone5;
    BOOL loading;
    BOOL active;
    BOOL completed;
    BOOL inProgress;
    CGFloat itemRowHeight;
    CGRect screen;
    AFHTTPRequestOperationManager *manager;
    NSIndexPath *indexPathToExpand;
    UIView *initialOverlayBackground;
    UIView *overlayBackground;
    UIImageView *checklistScreenshot;
    NSMutableDictionary *rowDictionary;
    NSManagedObjectContext *itemContext;
    Checklist *activeChecklist;
    UIBarButtonItem *searchButton;
}

@property (strong, nonatomic) id expanded;
@property (strong, nonatomic) Checklist *checklist;

@end

@implementation BHChecklistViewController

- (void)viewDidLoad {
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    [super viewDidLoad];
    screen = [[UIScreen mainScreen] bounds];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    [self.navigationController setNavigationBarHidden:NO];
    project = [(BHTabBarViewController*)self.tabBarController project];
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    rowDictionary = [NSMutableDictionary dictionary];
    itemRowHeight = 110;
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Checklists",project.name];
	[self.segmentedControl setTintColor:kDarkGrayColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];

    filteredItems = [NSMutableArray array];
    _checklist = [Checklist MR_findFirstByAttribute:@"project.identifier" withValue:project.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
    
    //collapse all the phases/rows
    if (_checklist){
        for (Cat *category in _checklist.phases){
            category.expanded = [NSNumber numberWithBool:NO];
        }
    }
    
    [Flurry logEvent:@"Viewing checklist"];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[UIColor darkGrayColor]];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [self.tableView addSubview:refreshControl];
    
    searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(activateSearch)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChecklistItem:) name:@"ReloadChecklistItem" object:nil];
    if ([(BHTabBarViewController*)self.tabBarController checklistIndexPath]){
        indexPathToExpand = [(BHTabBarViewController*)self.tabBarController checklistIndexPath];
    }
    [self.searchDisplayController.searchBar setBackgroundColor:kDarkerGrayColor];

}

- (void)activateSearch {
    [self.searchDisplayController.searchBar becomeFirstResponder];
    [UIView animateWithDuration:.65 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        /*if (IDIOM == IPAD){
            CGRect searchFrame = self.searchDisplayController.searchBar.frame;
            searchFrame.origin.y = -0;
            [self.searchDisplayController.searchBar setFrame:searchFrame];
            [self.searchDisplayController.searchBar setAlpha:1.0];
            [self.segmentedControl setAlpha:0.0];
        } else {*/
            CGRect searchFrame = self.searchDisplayController.searchBar.frame;
            searchFrame.origin.x = 0;
            [self.searchDisplayController.searchBar setFrame:searchFrame];
            CGRect segmentedControlFrame = self.segmentedControl.frame;
            segmentedControlFrame.origin.x = -screenWidth();
            [self.segmentedControl setFrame:segmentedControlFrame];
        //}
    
        self.tabBarController.navigationItem.rightBarButtonItem = nil;
    } completion:^(BOOL finished) {
    }];
}

- (void)endSearch {
 
    [UIView animateWithDuration:.65 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
            CGRect searchFrame = self.searchDisplayController.searchBar.frame;
            searchFrame.origin.x = screenWidth();
            [self.searchDisplayController.searchBar setFrame:searchFrame];
            CGRect segmentedControlFrame = self.segmentedControl.frame;
            segmentedControlFrame.origin.x = (screenWidth()-segmentedControlFrame.size.width)/2;
            [self.segmentedControl setFrame:segmentedControlFrame];
        
        self.tabBarController.navigationItem.rightBarButtonItem = searchButton;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)reloadChecklistItem:(NSNotification*)notification {
    ChecklistItem *item = [notification.userInfo objectForKey:@"item"];
    //update the count inputs, with category before phase so that the changes propagate correctly
    [item.category calculateProgress];
    [item.category.phase calculateProgress];
    //ensure the row stays expanded
    [item.category setExpanded:@YES];
    [item.category.phase setExpanded:@YES];
    if (item.category.phase.orderIndex.intValue < self.tableView.numberOfSections){
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:item.category.phase.orderIndex.integerValue] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = searchButton;
    //self.screenName = @"Checklist view controller";
    if (!_checklist){
        [self loadChecklist];
        [ProgressHUD show:@"Loading Checklist..."];
    }
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenChecklist]){
        initialOverlayBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth(), screenHeight()-49)];
        [initialOverlayBackground setAlpha:0.0];
        [initialOverlayBackground setBackgroundColor:[UIColor colorWithPatternImage:[self focusTabBar]]];
        [[[UIApplication sharedApplication].delegate window] addSubview:initialOverlayBackground];
        [UIView animateWithDuration:.25 animations:^{
            [initialOverlayBackground setAlpha:1.0];
        }];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenChecklist];
    }
    
    if (indexPathToExpand){
        //use indexPathToExpand row here because the indexPath is pulled from the detail view progress section
        if (!loading){
            Phase *phase = [_checklist.phases objectAtIndex:indexPathToExpand.row];
            phase.expanded = [NSNumber numberWithBool:YES];
            [rowDictionary setObject:phase.categories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPathToExpand.row]];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[_checklist.phases indexOfObject:phase]] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [self.tableView reloadData];
            indexPathToExpand = nil;
        }
    }
}

- (void)resetSegments {
    completed = NO;
    active = NO;
    inProgress = NO;
}

-(void)segmentedControlTapped:(UISegmentedControl*)sender {
    [self condenseTableView];
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (active){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self resetSegments];
                [self resetChecklist];
            } else {
                [self resetSegments];
                [self filterActive];
            }
            
            break;
        case 1:
            if (inProgress){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self resetSegments];
                [self resetChecklist];
            } else {
                [self resetSegments];
                [self filterInProgress];
            }
            
            break;
        case 2:
            if (completed){
                [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
                [self resetSegments];
                [self resetChecklist];
            } else {
                [self resetSegments];
                [self filterCompleted];
            }
            break;
        default:
            break;
    }
}

- (void)resetChecklist {
    _checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:_checklist.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
    [self.tableView reloadData];
}

- (void)filterActive {
    active = YES;
    _checklist.activePhases = [NSMutableArray array];
    NSPredicate *notComplete = [NSPredicate predicateWithFormat:@"state != %d",kItemCompleted];
    NSPredicate *applicable = [NSPredicate predicateWithFormat:@"state != %d",kNotApplicable];
    NSPredicate *testForActive = [NSCompoundPredicate andPredicateWithSubpredicates:@[notComplete,applicable]];
    for (Phase *phase in _checklist.phases){
        phase.activeCategories = [NSMutableArray array];
        
        for (Cat *category in phase.categories){
            category.activeItems = [NSMutableArray array];
            for (ChecklistItem *item in category.items){
                if([testForActive evaluateWithObject:item]) {
                    [category.activeItems addObject:item];
                }
            }
            if (category.activeItems.count) {
                [phase.activeCategories addObject:category];
            } else {
                //condense the phase
                phase.expanded = [NSNumber numberWithBool:NO];
            }
        }
        if (phase.activeCategories.count > 0) {
            [_checklist.activePhases addObject:phase];
        }
    }

    [self.tableView reloadData];
}

- (void)filterInProgress {
    inProgress = YES;
    if (_checklist.inProgressPhases){
        [_checklist.inProgressPhases removeAllObjects];
    } else {
        _checklist.inProgressPhases = [NSMutableArray array];
    }
    
    NSPredicate *testForProgress = [NSPredicate predicateWithFormat:@"state == %d",kItemInProgress];
    for (Phase *phase in _checklist.phases){
        phase.inProgressCategories = [NSMutableArray array];
        for (Cat *category in phase.categories){
            category.inProgressItems = [NSMutableArray array];
            for (ChecklistItem *item in category.items){
                if([testForProgress evaluateWithObject:item]) {
                    [category.inProgressItems addObject:item];
                }
            }
            if (category.inProgressItems.count) {
                [phase.inProgressCategories addObject:category];
            } else {
                //condense the phase
                phase.expanded = [NSNumber numberWithBool:NO];
            }
            
        }
        if (phase.inProgressCategories.count > 0) {
            [_checklist.inProgressPhases addObject:phase];
        }
    }

    [self.tableView reloadData];
}

- (void)filterCompleted {
    completed = YES;
    if (_checklist.completedPhases){
        [_checklist.completedPhases removeAllObjects];
    } else {
        _checklist.completedPhases = [NSMutableArray array];
    }
    NSPredicate *testForCompletion = [NSPredicate predicateWithFormat:@"state == %d",kItemCompleted];
    for (Phase *phase in _checklist.phases){
        phase.completedCategories = [NSMutableArray array];
        for (Cat *category in phase.categories){
            category.completedItems = [NSMutableArray array];
            for (ChecklistItem *item in category.items){
                if([testForCompletion evaluateWithObject:item]) {
                    [category.completedItems addObject:item];
                }
            }
            if (category.completedItems.count) {
                [phase.completedCategories addObject:category];
            } else {
                //condense the phase
                phase.expanded = [NSNumber numberWithBool:NO];
            }
        }
        if (phase.completedCategories.count > 0) {
            [_checklist.completedPhases addObject:phase];
        }
    }
    [self.tableView reloadData];
}

- (void)handleRefresh {
    [ProgressHUD show:@"Refreshing..."];
    [self loadChecklist];
}

- (void)loadChecklist {
    loading = YES;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [manager GET:[NSString stringWithFormat:@"%@/checklists/%@",kApiBaseUrl,project.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"checklist response: %@",[responseObject objectForKey:@"checklist"]);
        NSDictionary *checklistDict = [responseObject objectForKey:@"checklist"];
        _checklist = [Checklist MR_findFirstByAttribute:@"identifier" withValue:[checklistDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!_checklist){
            _checklist = [Checklist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [_checklist populateFromDictionary:checklistDict];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Checklist save: %u",success);
            loading = NO;
            if (refreshControl.isRefreshing) [refreshControl endRefreshing];
            [ProgressHUD dismiss];
            if (self.isViewLoaded && self.view.window){
                [self.tableView reloadData];
            }
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure loading checklist: %@",error.description);
        //[[[UIAlertView alloc] initWithTitle:nil message:@"We couldn't find a checklist associated with this project." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        if (refreshControl.isRefreshing) [refreshControl endRefreshing];
        [ProgressHUD dismiss];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:0]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    /*if (self.tableView.numberOfSections == 0){
        [self.tableView reloadData];
    }*/
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        ChecklistItem *item = (ChecklistItem*)sender;
        BHChecklistItemViewController *vc = segue.destinationViewController;
        [vc setItem:item];
        [vc setProject:project];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return 1;
    else if (completed) return _checklist.completedPhases.count;
    else if (active) return _checklist.activePhases.count;
    else if (inProgress) return _checklist.inProgressPhases.count;
    else return _checklist.phases.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) return filteredItems.count;
    else if (completed){
        Phase *phase = [_checklist.completedPhases objectAtIndex:section];
        if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            int count = phase.completedCategories.count + 1;
            for (Cat *category in phase.completedCategories){
                if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    count += category.completedItems.count;
                }
            }
            return count;
        } else {
            return 1;
        }
    } else if (active){
        Phase *phase = [_checklist.activePhases objectAtIndex:section];
        if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            int count = phase.activeCategories.count + 1;
            for (Cat *category in phase.activeCategories){
                if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    count += category.activeItems.count;
                }
            }
            return count;
        } else {
            return 1;
        }
    } else if (inProgress){
        Phase *phase = [_checklist.inProgressPhases objectAtIndex:section];
        if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            int count = phase.inProgressCategories.count + 1;
            for (Cat *category in phase.inProgressCategories){
                if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    count += category.inProgressItems.count;
                }
            }
            return count;
        } else {
            return 1;
        }
    } else {
        Phase *phase = [_checklist.phases objectAtIndex:section];
        
        if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            
            int count = phase.categories.count + 1;
            for (Cat *category in phase.categories){
                if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                    count += category.items.count;
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
        
        if (item.state && [item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryView.tintColor = [UIColor lightGrayColor];
        } else {
            [cell.textLabel setTextColor:kDarkGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.numberOfLines = 5;
        [cell.textLabel setFont:[UIFont fontWithName:kMyriadProLight size:19]];
        
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
        [cell.mainLabel setFont:[UIFont fontWithName:kMyriadProLight size:30]];
        [cell.mainLabel setNumberOfLines:5];
        
        
        Phase *phase;
        if (completed){
            phase = [_checklist.completedPhases objectAtIndex:indexPath.section];
        } else if (active) {
            phase = [_checklist.activePhases objectAtIndex:indexPath.section];
        } else if (inProgress){
            phase = [_checklist.inProgressPhases objectAtIndex:indexPath.section];
        } else {
            phase = [_checklist.phases objectAtIndex:indexPath.section];
        }
        
        if (indexPath.row == 0){
            cell.level = [NSNumber numberWithInt:0];
            [cell.mainLabel setText:phase.name];
            if (completed){
                [cell.detailLabel setText:[NSString stringWithFormat:@"Categories: %i",phase.completedCategories.count]];
            } else if (active){
                [cell.detailLabel setText:[NSString stringWithFormat:@"Categories: %i",phase.activeCategories.count]];
            } else if (inProgress){
                [cell.detailLabel setText:[NSString stringWithFormat:@"Categories: %i",phase.inProgressCategories.count]];
            } else {
                [cell.detailLabel setText:[NSString stringWithFormat:@"Categories: %i",phase.categories.count]];
            }
            [cell.detailLabel setFont:[UIFont fontWithName:kMyriadProLight size:19]];
            
            float count = phase.completedCount.floatValue + phase.notApplicableCount.floatValue;
            NSString *progressPercentage = [NSString stringWithFormat:@"%.1f%%",(count/phase.itemCount.integerValue)*100];
            [cell.progressPercentage setText:progressPercentage];
            [cell.progressPercentage setTextColor:[UIColor lightGrayColor]];
            [cell.photoImageView setHidden:YES];
            UILabel *progressLabel = [[UILabel alloc] init];
            [progressLabel setTextColor:[UIColor lightGrayColor]];
            [progressLabel setText:progressPercentage];
            cell.accessoryView = progressLabel;
            [cell setBackgroundColor:[UIColor whiteColor]];
            
        } else if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
            
            //add a border
            cell.layer.borderWidth = .5f;
            cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.2].CGColor;
            
            NSMutableOrderedSet *openRows = [rowDictionary objectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            if (openRows.count > indexPath.row-1){
                id item = [openRows objectAtIndex:indexPath.row-1];
                if (item && [item isKindOfClass:[Cat class]]){
                    Cat *category = (Cat*)item;
                    [cell.mainLabel setFont:[UIFont fontWithName:kMyriadProLight size:25]];
                    [cell.mainLabel setTextColor:[UIColor whiteColor]];
                    [cell.mainLabel setText:[NSString stringWithFormat:@" %@",category.name]];
                    if (completed){
                        [cell.detailLabel setText:[NSString stringWithFormat:@"  Items: %i",category.completedItems.count]];
                    } else if (active) {
                        [cell.detailLabel setText:[NSString stringWithFormat:@"  Items: %i",category.activeItems.count]];
                    } else if (inProgress) {
                        [cell.detailLabel setText:[NSString stringWithFormat:@"  Items: %i",category.inProgressItems.count]];
                    } else {
                        [cell.detailLabel setText:[NSString stringWithFormat:@"  Items: %i",category.items.count]];
                    }
                    [cell.detailLabel setFont:[UIFont fontWithName:kMyriadProLight size:18]];
                    [cell.detailLabel setTextColor:[UIColor whiteColor]];
                    float count = category.completedCount.floatValue + category.notApplicableCount.floatValue;
                    [cell.progressPercentage setText:[NSString stringWithFormat:@"%.1f%%",(count/category.items.count)*100]];
                    
                    [cell.progressPercentage setTextColor:[UIColor whiteColor]];
                    [cell.photoImageView setHidden:YES];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    [cell setBackgroundColor:kLightBlueColor];
                } else if (item) {
                    ChecklistItem *item = [openRows objectAtIndex:indexPath.row-1];
                    [cell.itemBody setText:item.body];
                    [cell.itemBody setFont:[UIFont fontWithName:kMyriadProLight size:19]];
                    [cell.progressPercentage setText:@""];
                    [cell setBackgroundColor:kBlueColor];
                    
                    if (item.state){
                        if ([item.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                            [cell.itemBody setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
                            cell.accessoryType = UITableViewCellAccessoryCheckmark;
                            [cell setTintColor:[UIColor whiteColor]];
                        } else if ([item.state isEqualToNumber:[NSNumber numberWithInteger:kItemInProgress]]){
                            [cell.itemBody setTextColor:[UIColor whiteColor]];
                            cell.accessoryType = UITableViewCellAccessoryNone;
                        } else {
                            UILabel *notApplicableLabel = [[UILabel alloc] init];
                            [notApplicableLabel setText:@"N/A"];
                            [cell.photoImageView setHidden:YES];
                            [notApplicableLabel setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
                            [cell.itemBody setTextColor:[UIColor colorWithWhite:1 alpha:.5]];
                            NSMutableAttributedString *attributedBody = cell.itemBody.attributedText.mutableCopy;
                            [attributedBody addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, attributedBody.length)];
                            cell.itemBody.attributedText = attributedBody;
                            cell.accessoryView = notApplicableLabel;
                        }
                    } else {
                        [cell.itemBody setTextColor:[UIColor whiteColor]];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    if (item.commentsCount.intValue > 0) {
                        [cell.chatImageView setHidden:NO];
                    } else {
                        [cell.chatImageView setHidden:YES];
                    }
                    
                    if (item.photosCount.intValue > 0) {
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
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) return 80;
    else return itemRowHeight;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        [self.segmentedControl setAlpha:0.0];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
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
        Phase *phase;
        if (completed){
            phase = [_checklist.completedPhases objectAtIndex:indexPath.section];
        } else if (active) {
            phase = [_checklist.activePhases objectAtIndex:indexPath.section];
        } else if (inProgress) {
            phase = [_checklist.inProgressPhases objectAtIndex:indexPath.section];
        } else {
            phase = [_checklist.phases objectAtIndex:indexPath.section];
        }
        
        if (indexPath.row == 0){
            if ([phase.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                phase.expanded = [NSNumber numberWithBool:NO];
                if (completed) {
                    for (Cat *category in phase.categories){
                        category.expanded = NO;
                    }
                } else if (active){
                    for (Cat *category in phase.activeCategories){
                        category.expanded = NO;
                    }
                } else if (inProgress){
                    for (Cat *category in phase.inProgressCategories){
                        category.expanded = NO;
                    }
                } else {
                    for (Cat *category in phase.categories){
                        category.expanded = NO;
                    }
                }
                
                [rowDictionary removeObjectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            } else {
                phase.expanded = [NSNumber numberWithBool:YES];
                if (completed) {
                    [rowDictionary setObject:phase.completedCategories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPath.section]];
                } else if (active){
                    [rowDictionary setObject:phase.activeCategories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPath.section]];
                } else if (inProgress){
                    [rowDictionary setObject:phase.inProgressCategories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPath.section]];
                } else {
                    [rowDictionary setObject:phase.categories.mutableCopy forKey:[NSString stringWithFormat:@"%d",indexPath.section]];
                }
            }
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        } else {
            NSMutableOrderedSet *openRows = [rowDictionary objectForKey:[NSString stringWithFormat:@"%d",indexPath.section]];
            if (openRows.count > indexPath.row-1){
                id item = [openRows objectAtIndex:indexPath.row-1];
                if ([item isKindOfClass:[Cat class]]){
                    Cat *category = [openRows objectAtIndex:indexPath.row-1];
                    if ([category.expanded isEqualToNumber:[NSNumber numberWithBool:YES]]){
                        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
                        int subIdx = [openRows indexOfObject:category];
                        
                        NSMutableArray *deletionArray;
                        if (completed){
                            deletionArray = category.completedItems;
                        } else if (active) {
                            deletionArray = category.activeItems;
                        } else if (inProgress) {
                            deletionArray = category.inProgressItems;
                        } else {
                            deletionArray = category.items.mutableCopy;
                        }
                        for (int idx = subIdx; idx < (deletionArray.count+subIdx); idx ++){
                            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx+2 inSection:indexPath.section];
                            [deleteIndexPaths addObject:newIndexPath];
                        }
                        
                        [openRows removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([openRows indexOfObject:category]+1, deletionArray.count)]];
                        
                        category.expanded = [NSNumber numberWithBool:NO];
                        
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                    } else {
                        category.expanded = [NSNumber numberWithBool:YES];
                        NSMutableArray *newIndexPaths = [NSMutableArray array];
                        int catIdx = [openRows indexOfObject:category];
                        int itemIdx = 0;
                        NSArray *insertionArray;
                        if (completed) {
                            insertionArray = category.completedItems;
                        } else if (active){
                            insertionArray = category.activeItems;
                        } else if (inProgress){
                            insertionArray = category.inProgressItems;
                        } else {
                            insertionArray = category.items.array;
                        }
                        
                        for (int idx = catIdx; idx < (insertionArray.count+catIdx); idx ++){
                            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx+2 inSection:indexPath.section];
                            [newIndexPaths addObject:newIndexPath];
                            [openRows insertObject:[insertionArray objectAtIndex:itemIdx] atIndex:idx+1];
                            itemIdx++;
                        }
                        
                        [self.tableView beginUpdates];
                        [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                        
                    }
                    
                } else {
                    ChecklistItem *item = [openRows objectAtIndex:indexPath.row-1];
                    [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
                }
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredItems removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];

    for (ChecklistItem *item in _checklist.items){
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

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:nil];
    if (searchString.length) return YES;
    else return NO;
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
    if (IDIOM == IPAD){
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
    NSString *text = @"The first section is the checklist.\n\nSearch for specific items or use the filters to quickly prioritize.";
    if (IDIOM == IPAD){
        checklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checklistiPad"]];
        [checklistScreenshot setFrame:CGRectMake(screenWidth()/2-355, 26, 710, 505)];
        [checklist configureText:text atFrame:CGRectMake(screenWidth()/4, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()/2, 120)];
    } else {
        checklistScreenshot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checklistScreenshot"]];
        [checklistScreenshot setFrame:CGRectMake(20, 20, 280, 330)];
        [checklist configureText:text atFrame:CGRectMake(20, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()-40, 120)];
    }
    [checklistScreenshot setAlpha:0.0];
    [checklist.tapGesture addTarget:self action:@selector(slide3:)];
    
    [UIView animateWithDuration:.35 animations:^{
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
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
    NSString *text = @"The full checklist will be downloaded and stored on your device. This enables you to access items whether or not you have an internet connection.";
    if (IDIOM == IPAD){
        [tapToExpand configureText:text atFrame:CGRectMake(screenWidth()/4, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()/2, 120)];
    } else {
        [tapToExpand configureText:text atFrame:CGRectMake(20, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()-40, 120)];
    }
    
    [tapToExpand.tapGesture addTarget:self action:@selector(slide4:)];
    
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

- (void)slide4:(UITapGestureRecognizer*)sender {
    BHOverlayView *tapToExpand = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"Tap any section to hide or expand the checklist items within.";
    if (IDIOM == IPAD){
        [tapToExpand configureText:text atFrame:CGRectMake(screenWidth()/4, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()/2, 100)];
    } else {
        [tapToExpand configureText:text atFrame:CGRectMake(20, checklistScreenshot.frame.size.height + checklistScreenshot.frame.origin.y, screenWidth()-40, 100)];
    }
    
    [tapToExpand.tapGesture addTarget:self action:@selector(endIntro:)];
    
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
    [super viewWillDisappear:animated];
}

- (void)condenseTableView {
    for (Phase *phase in _checklist.phases){
        phase.expanded = [NSNumber numberWithBool:NO];
        for (Cat *category in phase.categories){
            category.expanded = [NSNumber numberWithBool:NO];
        }
    }
    for (Phase *phase in _checklist.completedPhases){
        phase.expanded = [NSNumber numberWithBool:NO];
        for (Cat *category in phase.completedCategories){
            category.expanded = [NSNumber numberWithBool:NO];
        }
    }
    for (Phase *phase in _checklist.activePhases){
        phase.expanded = [NSNumber numberWithBool:NO];
        for (Cat *category in phase.activeCategories){
            category.expanded = [NSNumber numberWithBool:NO];
        }
    }
    for (Phase *phase in _checklist.inProgressPhases){
        phase.expanded = [NSNumber numberWithBool:NO];
        for (Cat *category in phase.inProgressCategories){
            category.expanded = [NSNumber numberWithBool:NO];
        }
    }
    [rowDictionary removeAllObjects];
}

- (void)dealloc {
    [self condenseTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
