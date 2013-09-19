//
//  BHReportsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 9/1/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHReportsViewController.h"
#import "BHReportPickerCell.h"
#import "BHReportSectionCell.h"
#import <RestKit/RestKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "BHTabBarViewController.h"
#import "BHProject.h"

@interface BHReportsViewController () <UIActionSheetDelegate, UITextViewDelegate, UIScrollViewDelegate> {
    NSMutableArray *reports;
    NSDateFormatter *dateFormatter;
    BOOL iPhone5;
}

- (IBAction)backToDashboard;
@end

@implementation BHReportsViewController

@synthesize report = _report;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([UIScreen mainScreen].bounds.size.height == 568 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        iPhone5 = YES;
    } else {
        NSLog(@"self view origin y: %f and scrollview origin: %f",self.view.frame.origin.y, self.scrollView.frame.origin.y);
        iPhone5 = NO;
    }
	// Do any additional setup after loading the view.
    self.navigationItem.title = [NSString stringWithFormat:@"%@: Reports",[[(BHTabBarViewController*)self.tabBarController project] name]];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    if (!reports) reports = [NSMutableArray array];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableViewLeft setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableViewRight setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //disable scrollview's vertical scrolling, but keep the tableview vertically scrolling.
    [self.scrollView setContentSize:CGSizeMake(640,self.scrollView.frame.size.height-113)];
    [self.scrollView setContentInset:UIEdgeInsetsMake(0, 320, 0, 0)];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [SVProgressHUD showWithStatus:@"Fetching reports..."];
    [self loadReportsForProject:[(BHTabBarViewController*)self.tabBarController project]];
}


- (void)loadNext {
    [SVProgressHUD showWithStatus:@"Loading next report..."];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
}

- (void)loadPrevious {
    [SVProgressHUD showWithStatus:@"Loading previous report..."];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
}

- (void)dismissOverlay {
    [SVProgressHUD dismiss];
    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"We couldnt' find a report that fit those criteria" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    static NSInteger previousPage = 0;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        NSLog(@"page changed! %i",page);
        if (page == 1) [self loadNext];
        else if (page == -1) [self loadPrevious];
        previousPage = page;
    }
}

- (void)loadReportsForProject:(BHProject*)project {
    RKObjectManager *manager = [RKObjectManager sharedManager];
    
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[BHUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{
                                                         @"_id":@"identifier",
                                                         @"fullname":@"fullname"
                                                         }];
    
    RKObjectMapping *reportsMapping = [RKObjectMapping mappingForClass:[BHReport class]];
    [reportsMapping addAttributeMappingsFromArray:@[@"title", @"type",@"createdOn", @"body"]];
    [reportsMapping addAttributeMappingsFromDictionary:@{
                                                         @"_id" : @"identifier",
                                                         }];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"user"
                                                                                             toKeyPath:@"user"
                                                                                           withMapping:userMapping];
    [reportsMapping addPropertyMapping:relationshipMapping];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *reportsDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:reportsMapping method:RKRequestMethodAny pathPattern:@"reports" keyPath:@"rows" statusCodes:statusCodes];
    

    /*RKObjectMapping *projectMapping = [RKObjectMapping requestMapping];
    [projectMapping addAttributeMappingsFromDictionary:@{@"project":project}];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:projectMapping objectClass:[BHProject class] rootKeyPath:nil method:RKRequestMethodAny];
    [manager addRequestDescriptor:requestDescriptor];*/
    
    [SVProgressHUD showWithStatus:@"Fetching projects..."];
    [manager addResponseDescriptor:reportsDescriptor];
    [manager getObjectsAtPath:@"reports" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"mapping result for reports: %@",mappingResult.firstObject);
        reports = [mappingResult.array mutableCopy];
        [SVProgressHUD dismiss];
        _report = [reports objectAtIndex:0];
        [self.tableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching projects for dashboard: %@",error.description);
        [SVProgressHUD dismiss];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backToDashboard {
    [self dismissViewControllerAnimated:YES completion:^{
        
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
    else return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ReportPickerCell";
        BHReportPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportPickerCell" owner:self options:nil] lastObject];
        }
        [cell.typePickerButton setTitle:_report.type forState:UIControlStateNormal];
        [cell.typePickerButton addTarget:self action:@selector(tapTypePicker) forControlEvents:UIControlEventTouchUpInside];
        NSDate *formattedDate = [dateFormatter dateFromString:_report.createdOn];
        NSDateFormatter *newFormatter = [[NSDateFormatter alloc] init];
        [newFormatter setDateStyle:NSDateFormatterLongStyle];
        [newFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [cell.datePickerButton setTitle:[newFormatter stringFromDate:formattedDate] forState:UIControlStateNormal];
        [cell.datePickerButton addTarget:self action:@selector(setDate:) forControlEvents:UIControlEventTouchUpInside];
        [cell configure];
        return cell;
    } else {
        static NSString *CellIdentifier = @"ReportSectionCell";
        BHReportSectionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReportSectionCell" owner:self options:nil] lastObject];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.reportSectionLabel setText:_report.title];
        [cell.reportBodyTextView setDelegate:self];
        [cell.reportBodyTextView setText:_report.body];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return 100;
    else {
        return 300;
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    NSLog(@"textview ended typing");
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)doneEditing {
    [self.view endEditing:YES];
}

-(void)tapTypePicker {
    [[[UIActionSheet alloc] initWithTitle:@"Choose Report Type" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Daily",@"Monthly",@"Safety", nil] showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]){
        _report.type = [actionSheet buttonTitleAtIndex:buttonIndex];
    }
    [self.tableView reloadData];
}

- (void)loadDate:(UIDatePicker *)sender {
    NSLog(@"Should be loading a report for: %@", sender.date);
    [SVProgressHUD showWithStatus:@"Fetching report..."];
    _report.createdOn = [dateFormatter stringFromDate:sender.date];
    [self.tableView reloadData];
    [self performSelector:@selector(dismissOverlay) withObject:nil afterDelay:1.0];
}

- (void)dismissDatePicker:(id)sender {
    CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height, 320, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height+44, 320, 216);

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view viewWithTag:9].alpha = 0;
        [self.view viewWithTag:10].frame = datePickerTargetFrame;
        [self.view viewWithTag:11].frame = toolbarTargetFrame;
    } completion:^(BOOL finished) {
        [[self.view viewWithTag:9] removeFromSuperview];
        [[self.view viewWithTag:10] removeFromSuperview];
        [[self.view viewWithTag:11] removeFromSuperview];
    }];
    
}

- (void)setDate:(id)sender {
    if ([self.view viewWithTag:9]) {
        return;
    }
    //CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height-216-44-49, 320, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height-216-49, 320, 216);
    
    UIView *buttonLayer = [[UIView alloc] initWithFrame:self.view.bounds];
    buttonLayer.alpha = 0;
    buttonLayer.backgroundColor = [UIColor blackColor];
    buttonLayer.tag = 9;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker:)];
    [buttonLayer addGestureRecognizer:tapGesture];
    [self.view addSubview:buttonLayer];
    
    UIView *backgroundLayer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height+44, 320, 216)];
    backgroundLayer.tag = 10;
    [backgroundLayer setBackgroundColor:[UIColor whiteColor]];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
    [datePicker setDatePickerMode:UIDatePickerModeDate];
    [datePicker addTarget:self action:@selector(loadDate:) forControlEvents:UIControlEventValueChanged];
    
    [backgroundLayer addSubview:datePicker];
    [self.view addSubview:backgroundLayer];
    
    /*UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, 320, 44)];
    toolBar.tag = 11;
    [toolBar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDatePicker:)];
    [doneButton setTintColor:[UIColor blackColor]];
    [toolBar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    [self.view addSubview:toolBar];*/
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //toolBar.frame = toolbarTargetFrame;
        backgroundLayer.frame = datePickerTargetFrame;
        buttonLayer.alpha = 0.7;
    } completion:^(BOOL finished) {
        
    }];
}

@end
