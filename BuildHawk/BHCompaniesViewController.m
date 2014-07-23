//
//  BHCompaniesViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/12/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHCompaniesViewController.h"
#import "BHAppDelegate.h"
#import "BHChoosePersonnelCell.h"
#import "Company+helper.h"

@interface BHCompaniesViewController () {
    BHAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *backButton;
}

@end

@implementation BHCompaniesViewController

@synthesize searchTerm = _searchTerm;
@synthesize project = _project;
@synthesize searchResults = _searchResults;

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = (BHAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addCompany {
    [ProgressHUD show:@"Creating company..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (_searchTerm.length){
        [parameters setObject:_searchTerm forKey:@"name"];
    }
    [parameters setObject:_project.identifier forKey:@"project_id"];
    [manager POST:[NSString stringWithFormat:@"%@/companies/add",kApiBaseUrl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success adding a company to project companies: %@",responseObject);
        
        Company *company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [company populateWithDict:[responseObject objectForKey:@"company"]];
        [_project addCompany:company];
     
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCompany" object:nil userInfo:@{@"company":company}];
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [ProgressHUD dismiss];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong while trying to add this company. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        NSLog(@"Failed to add company to project companies: %@",error.description);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchResults.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BHChoosePersonnelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"BHChoosePersonnelCell" owner:self options:nil] lastObject];
    }
    if (indexPath.row == _searchResults.count){
        [cell.textLabel setText:[NSString stringWithFormat:@"Add \"%@\"",_searchTerm]];
        [cell.textLabel setFont:[UIFont italicSystemFontOfSize:16]];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
    } else {
        
        NSDictionary *companyDict = _searchResults[indexPath.row];
        [cell.textLabel setText:[companyDict objectForKey:@"name"]];
        [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
        [cell.textLabel setTextColor:[UIColor blackColor]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == _searchResults.count){
        [self addCompany];
    } else {
        NSDictionary *companyDict = _searchResults[indexPath.row];
        if ([companyDict objectForKey:@"id"] && [companyDict objectForKey:@"id"] != [NSNull null]){
            Company *company = [Company MR_findFirstByAttribute:@"identifier" withValue:[companyDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!company){
                company = [Company MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [company populateWithDict:companyDict];
            [_project addCompany:company];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCompany" object:nil userInfo:@{@"company":company}];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)back {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
