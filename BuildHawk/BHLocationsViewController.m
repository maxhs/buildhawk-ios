//
//  BHLocationsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/12/15.
//  Copyright (c) 2015 BuildHawk. All rights reserved.
//

#import "BHLocationsViewController.h"
#import "BHLocationCell.h"
#import "BHAppDelegate.h"


@interface BHLocationsViewController () {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSMutableOrderedSet *_locations;
    NSMutableOrderedSet *_filteredLocations;
    BOOL searching;
    UIBarButtonItem *cancelButton;
    NSString *searchText;
}
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Task *task;
@end

@implementation BHLocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.task = [Task MR_findFirstByAttribute:@"identifier" withValue:_taskId  inContext:[NSManagedObjectContext MR_defaultContext]];
    if (_projectId){
        self.project = [Project MR_findFirstByAttribute:@"identifier" withValue:_projectId inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project.identifier == %@",_project.identifier];
    _locations = [NSMutableOrderedSet orderedSetWithArray:[Location MR_findAllWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]]];
    _filteredLocations = [NSMutableOrderedSet orderedSetWithOrderedSet:_locations];
    _tableView.rowHeight = 54.f;
    [_tableView reloadData];
    
    searching = NO;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    [self.searchBar setPlaceholder:@"Add a new location..."];
    self.tableView.tableHeaderView = self.searchBar;
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kOpenSans] size:0]];
            break;
        }
    }
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(endSearch)];
}

#pragma mark <UICTableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searching){
        if (_filteredLocations.count == 0){
            return 1;
        } else {
            return _filteredLocations.count;
        }
    } else {
        return _locations.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BHLocationCell *cell = (BHLocationCell*)[tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    if (searching && _filteredLocations.count == 0){
        [cell configureToAdd:searchText];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        Location *location = searching ? _filteredLocations[indexPath.item] : _locations[indexPath.item];
        [cell configureForLocation:location];
        if ([self.task.locations containsObject:location]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

- (void)createNewLocation {
    [ProgressHUD show:@"Creating new location..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_project.identifier forKey:@"project_id"];
    [parameters setObject:searchText forKey:@"name"];
    [manager POST:@"locations" parameters:@{@"location":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new location: %@",responseObject);
        Location *newLocation = [Location MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [newLocation populateFromDictionary:[responseObject objectForKey:@"location"]];
        [_locations addObject:newLocation];
        [self.task addLocation:newLocation];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            searching = NO;
            [ProgressHUD dismiss];
            [self endSearch];
            [self.tableView reloadData];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Location error" message:@"Sorry, but something went wrong while trying to create this location. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Error creating location: %@",error.description);
    }];
}

#pragma mark <UITableViewDelegate>
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (searching && _filteredLocations.count == 0 && searchText.length){
        [self createNewLocation];
    } else {
        Location *l = searching ? _filteredLocations[indexPath.item] : _locations[indexPath.item];
        Location *location = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        if ([self.task.locations containsObject:location]){
            [self.task removeLocation:location];
            if (self.locationsDelegate && [self.locationsDelegate respondsToSelector:@selector(locationRemoved:)]){
                [self.locationsDelegate locationRemoved:location];
            }
        } else {
            [self.task addLocation:location];
            if (self.locationsDelegate && [self.locationsDelegate respondsToSelector:@selector(locationAdded:)]){
                [self.locationsDelegate locationAdded:location];
            }
        }
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    [_filteredLocations removeAllObjects]; // First clear the filtered array.
    searchText = text;
    for (Location *location in _locations){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        if([predicate evaluateWithObject:location.name]) {
            [_filteredLocations addObject:location];
        }
    }
    [self.tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length){
        searching = YES;
        [self filterContentForSearchText:newText scope:nil];
    } else {
        searching = NO;
        [self.tableView reloadData];
    }
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
}

- (void)endSearch {
    searching = NO;
    [self.searchBar resignFirstResponder];
    [self.searchBar endEditing:YES];
    self.navigationItem.rightBarButtonItem = nil;
}
@end
