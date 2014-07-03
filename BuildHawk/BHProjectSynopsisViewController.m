//
//  BHProjectSynopsisViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHProjectSynopsisViewController.h"
#import "Constants.h"
#import "BHTabBarViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "ChecklistItem.h"
#import "Photo.h"
#import "WorklistItem+helper.h"
#import "BHRecentDocumentCell.h"
#import "UIButton+WebCache.h"
#import "MWPhotoBrowser.h"
#import "Flurry.h"
#import "BHChecklistViewController.h"
#import "BHChecklistItemViewController.h"
#import "BHTaskViewController.h"
#import "BHProgressCell.h"
#import "BHOverlayView.h"
#import <LDProgressView/LDProgressView.h>
#import "BHAppDelegate.h"
#import "User+helper.h"
#import "Phase+helper.h"
#import "Activity+helper.h"
#import "BHActivityCell.h"
#import "BHReminderCell.h"
#import "BHActivitiesViewController.h"
#import "Worklist+helper.h"
#import "Reminder+helper.h"
#import "Address+helper.h"

@interface BHProjectSynopsisViewController () <UIScrollViewDelegate, MWPhotoBrowserDelegate> {
    AFHTTPRequestOperationManager *manager;
    UIScrollView *documentsScrollView;
    BOOL iPad;
    CGRect screen;
    NSMutableArray *browserPhotos;
    UIView *overlayBackground;
    UIImageView *screenshotView;
    NSDateFormatter *formatter;
    NSDateFormatter *reminderFormatter;
    CGRect screenRect;
}

@end

@implementation BHProjectSynopsisViewController

@synthesize project = _project;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        iPad = YES;
    }
    screenRect = [[UIScreen mainScreen] applicationFrame];
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.title = _project.name;
    screen = [UIScreen mainScreen].bounds;

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, 66)];
    [footerView setBackgroundColor:kDarkGrayColor];
    UIButton *goToProjectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goToProjectButton setTitle:@"Go to Project" forState:UIControlStateNormal];
    [goToProjectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [goToProjectButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:18]];
    [goToProjectButton addTarget:self action:@selector(goToProject:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:goToProjectButton];
    [goToProjectButton setFrame:footerView.frame];
    self.tableView.tableFooterView = footerView;
    
    manager = [(BHAppDelegate*)[UIApplication sharedApplication].delegate manager];
    [Flurry logEvent:[NSString stringWithFormat: @"Viewing dashboard for %@",_project.name]];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kHasSeenDashboardDetail]){
        overlayBackground = [(BHAppDelegate*)[UIApplication sharedApplication].delegate addOverlayUnderNav:NO];
        [self slide1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasSeenDashboardDetail];
    }
    NSLog(@"how many reminders? %d",_project.reminders.count);
    NSLog(@"how many worklist activities: %d",_project.worklist.activities.count);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if (_project.reminders.count > 3){
                return 3;
            } else {
                return _project.reminders.count;
            }
            break;
        case 1:
            return [(NSArray*)_project.upcomingItems count];
            break;
        case 2:
            if (_project.activities.count > 3){
                return 3;
            } else {
                return _project.activities.count;
            }
            
            break;
        case 3:
            return [(NSArray*)_project.phases count];
            break;
        case 4:
            if (_project.checklist.activities.count > 3){
                return 3;
            } else {
                return _project.checklist.activities.count;
            }
            break;
        case 5:
            if (_project.recentDocuments.count > 0) return 1;
            else return 0;
            break;
        case 6:
            if (_project.worklist.activities.count > 3){
                return 3;
            } else {
                return _project.worklist.activities.count;
            }
            break;
        case 7:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            BHReminderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReminderCell"];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHReminderCell" owner:self options:nil] lastObject];
            }
            
            Reminder *reminder = _project.reminders[indexPath.row];

            if (reminder.checklistItem){
                [cell.reminderLabel setText:[NSString stringWithFormat:@"%@:\n%@",[formatter stringFromDate:reminder.reminderDate],reminder.checklistItem.body]];
            } else {
                [cell.reminderLabel setText:@""];
            }
            if ([reminder.reminderDate compare:[NSDate date]] == NSOrderedAscending){
                [cell.reminderLabel setTextColor:[UIColor redColor]];
            } else {
                [cell.reminderLabel setTextColor:[UIColor blackColor]];
            }
            if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
                [cell.activeButton setTitle:@"Hide" forState:UIControlStateNormal];
            } else {
                [cell.activeButton setTitle:@"Enable" forState:UIControlStateNormal];
            }
            cell.activeButton.tag = indexPath.row;
            [cell.activeButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:13]];
            [cell.activeButton addTarget:self action:@selector(reminderButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            return cell;
        }
            
            break;
        case 1: {
            static NSString *CellIdentifier = @"UpcomingItemCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            ChecklistItem *checklistItem = [_project.upcomingItems objectAtIndex:indexPath.row];
            [cell.textLabel setText:checklistItem.body];
            if (checklistItem.criticalDate) {
                NSLog(@"should be showing cricital date: %@", checklistItem.criticalDate);
                [cell.detailTextLabel setText:[NSString stringWithFormat:@"Deadline: %@",[formatter stringFromDate:checklistItem.criticalDate]]];
                [cell.detailTextLabel setTextColor:[UIColor darkGrayColor]];
            } else {
                [cell.detailTextLabel setText:@"No critical date listed"];
                [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
            }
            if ([checklistItem.state isEqualToNumber:[NSNumber numberWithInteger:kItemCompleted]]){
                [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            }
            if ([[checklistItem type] isEqualToString:@"Com"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"communicateOutlineDark"]];
            } else if ([[checklistItem type] isEqualToString:@"S&C"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"stopAndCheckOutlineDark"]];
            } else {
                [cell.imageView setImage:[UIImage imageNamed:@"documentsOutlineDark"]];
            }
            return cell;
        }
            
            break;
        case 2: {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.activities objectAtIndex:indexPath.row];
            [cell configureActivityForSynopsis:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            
            return cell;
        }
            
            break;
        case 3: {
            BHProgressCell *progressCell = [tableView dequeueReusableCellWithIdentifier:@"ProgressCell"];
            [progressCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            progressCell = [[[NSBundle mainBundle] loadNibNamed:@"BHProgressCell" owner:self options:nil] lastObject];
    
            Phase *phase = [_project.phases objectAtIndex:indexPath.row];
            [progressCell.itemLabel setText:phase.name];
            CGFloat progress_count = [phase.progressCount floatValue];
            CGFloat all = [phase.itemCount floatValue];
            [progressCell.progressLabel setText:[NSString stringWithFormat:@"%.1f%%",(100*progress_count/all)]];
            LDProgressView *progressView;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                progressView = [[LDProgressView alloc] initWithFrame:CGRectMake(415, 25, 300, 16)];
                progressCell.progressLabel.transform = CGAffineTransformMakeTranslation(140, 0);
            } else {
                progressView = [[LDProgressView alloc] initWithFrame:CGRectMake(215, 25, 100, 16)];
            }
            if (progress_count && all){
                progressView.progress = (progress_count/all);
            } else {
                progressView.progress = 0.f;
            }
            
            progressView.color = kBlueColor;
            progressView.showText = @NO;
            progressView.type = LDProgressSolid;
            [progressCell addSubview:progressView];
            
            progressCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return progressCell;
        }
        break;
        case 4: {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.activities objectAtIndex:indexPath.row];
            [cell configureActivityForSynopsis:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            
            return cell;
        }
            break;
        case 5: {
            BHRecentDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentPhotosCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHRecentDocumentCell" owner:self options:nil] lastObject];
            }
            CGRect frame = cell.frame;
            frame.size.width = screen.size.width;
            [cell setFrame:frame];
            if (!documentsScrollView) {
                documentsScrollView = [[UIScrollView alloc] initWithFrame:cell.frame];
                [cell addSubview:documentsScrollView];
            }
            [self showDocuments];
            return cell;
        }
        
            break;
        case 6: {
            BHActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActivityCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            if (cell == nil) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"BHActivityCell" owner:self options:nil] lastObject];
            }
            Activity *activity = [_project.worklist.activities objectAtIndex:indexPath.row];
            [cell configureForActivity:activity];
            [cell.timestampLabel setText:[formatter stringFromDate:activity.createdDate]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
            break;
        case 7: {
            static NSString *CellIdentifier = @"SynopsisCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (_project.address.formattedAddress){
                [cell.textLabel setText:_project.address.formattedAddress];
            } else if (_project.address){
                [cell.textLabel setText:[NSString stringWithFormat:@"%@, %@, %@ %@",_project.address.street1,_project.address.city,_project.address.state,_project.address.zip]];
            }
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"Number of personnel: %u",_project.users.count]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel setFont:[UIFont fontWithName:kHelveticaNeueLight size:16]];
            return cell;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 5) return 110;
    else return 80;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 2:
            if (_project.recentDocuments.count){
                return 40;
            } else {
                return 0;
            }
            break;
        case 3:
            if ([(NSArray*)_project.upcomingItems count]){
                return 40;
            } else {
                return 0;
            }
            break;
        case 4:
            if ([(NSArray*)_project.recentItems count]){
                return 40;
            } else {
                return 0;
            }
            break;
        default:
            return 40;
            break;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView* headerView;
    if (section == 2 && _project.recentDocuments.count == 0) {
        return nil;
    } else if (section == 4 && [(NSArray*)_project.recentItems count] == 0) {
        return nil;
    } else if (section == 3 && [(NSArray*)_project.upcomingItems count] == 0) {
        return nil;
    } else {
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, 40.0)];
    }
    
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    // Add the label
    UILabel *headerLabel;
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, screenRect.size.width, 40.0)];
    headerLabel.backgroundColor = kLighterGrayColor;
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.font = [UIFont fontWithName:kHelveticaNeueLight size:16];
    headerLabel.numberOfLines = 0;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:headerLabel];
    
    switch (section) {
        case 0:
        {
            [headerLabel setText:@"Reminders"];
            if (_project.reminders.count > 3){
                UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [allButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:12]];
                [allButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                [allButton setFrame:CGRectMake(screenRect.size.width-44, 0, 44, 44)];
                [allButton setTitle:@"ALL" forState:UIControlStateNormal];
                [allButton addTarget:self action:@selector(loadReminders) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:allButton];
            }
        }
            break;
        case 1:
        {
            [headerLabel setText:@"Deadlines"];
            UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [allButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:12]];
            [allButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [allButton setFrame:CGRectMake(screenRect.size.width-44, 0, 44, 44)];
            [allButton setTitle:@"ALL" forState:UIControlStateNormal];
            [allButton addTarget:self action:@selector(loadDeadlines) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:allButton];
        }
            break;
        case 2:
        {
            [headerLabel setText:@"Other Alerts"];
            if (_project.activities.count > 3){
                UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [allButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueMedium size:12]];
                [allButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                [allButton setFrame:CGRectMake(screenRect.size.width-44, 0, 44, 44)];
                [allButton setTitle:@"ALL" forState:UIControlStateNormal];
                [allButton addTarget:self action:@selector(loadActivities) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:allButton];
            }
        }
            break;
        case 3:
            [headerLabel setText:@"Progress"];
            break;
        case 4:
            [headerLabel setText:@"Checklist"];
            break;
        case 5:
            [headerLabel setText:@"Documents"];
            break;
        case 6:
            [headerLabel setText:@"Worklist"];
            break;
        case 7:
            [headerLabel setText:@"Project Summary"];
            break;
            
        default:
            return nil;
            break;
    }
    return headerView;
}

- (void)reminderButtonTapped:(UIButton*)button{
    Reminder *reminder = _project.reminders[button.tag];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([reminder.active isEqualToNumber:[NSNumber numberWithBool:YES]]){
        [parameters setObject:@NO forKey:@"active"];
        [reminder setActive:[NSNumber numberWithBool:NO]];
    } else {
        [parameters setObject:@YES forKey:@"active"];
        [reminder setActive:[NSNumber numberWithBool:YES]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [manager PATCH:[NSString stringWithFormat:@"%@/reminders/%@",kApiBaseUrl,reminder.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success updating reminder state: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to update remidner: %@",error.description);
    }];
}

- (void)loadReminders {
    [self performSegueWithIdentifier:@"Alerts" sender:_project.reminders];
}

- (void)loadDeadlines {
    [self performSegueWithIdentifier:@"Alerts" sender:nil];
}

- (void)loadActivities {
    [self performSegueWithIdentifier:@"Alerts" sender:_project.activities];
}

#pragma mark - Display events

- (void)showDocuments {
    [documentsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    documentsScrollView.showsHorizontalScrollIndicator = NO;
    documentsScrollView.pagingEnabled = YES;
    documentsScrollView.delegate = self;
    int index = 0;
    int width = 105;
    CGRect photoRect = CGRectMake(5,5,100,100);
    for (Photo *photo in _project.recentDocuments) {
        if (index > 0) photoRect.origin.x += width;
        __weak UIButton *eventButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [documentsScrollView addSubview:eventButton];
        [eventButton setFrame:photoRect];
        [eventButton setTag:index];
        if (photo.urlSmall) [eventButton setImageWithURL:[NSURL URLWithString:photo.urlSmall] forState:UIControlStateNormal];
        else if (photo.urlThumb) [eventButton setImageWithURL:[NSURL URLWithString:photo.urlThumb] forState:UIControlStateNormal];
        [eventButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        eventButton.imageView.clipsToBounds = YES;
        [eventButton addTarget:self action:@selector(showPhotoDetail:) forControlEvents:UIControlEventTouchUpInside];
        [eventButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        index++;
    }
    [documentsScrollView setContentSize:CGSizeMake((_project.recentDocuments.count*105) + 5,documentsScrollView.frame.size.height)];
    documentsScrollView.layer.shouldRasterize = YES;
    documentsScrollView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)showPhotoDetail:(UIButton*)button {
    browserPhotos = [NSMutableArray new];
    for (Photo *photo in _project.recentDocuments) {
        MWPhoto *mwPhoto;
        mwPhoto = [MWPhoto photoWithURL:[NSURL URLWithString:photo.urlLarge]];
        [mwPhoto setPhoto:photo];
        if (photo.caption.length){
            mwPhoto.caption = photo.caption;
        }
        [browserPhotos addObject:mwPhoto];
    }
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = YES; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)

    [self.navigationController pushViewController:browser animated:YES];
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:button.tag];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return browserPhotos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < browserPhotos.count)
        return [browserPhotos objectAtIndex:index];
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        Reminder *reminder = _project.reminders[indexPath.row];
        if (reminder.checklistItem){
            [self performSegueWithIdentifier:@"ChecklistItem" sender:reminder.checklistItem];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == 1){
        ChecklistItem *item = [_project.upcomingItems objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"ChecklistItem" sender:item];
    } else if (indexPath.section == 3){
        [self performSegueWithIdentifier:@"Project" sender:indexPath];
    } else if (indexPath.section == 5){
        
    }
}

- (void)goToProject:(UIButton*)button {
    [self performSegueWithIdentifier:@"Project" sender:button];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Project"]) {
        BHTabBarViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[NSIndexPath class]]){
            [vc setChecklistIndexPath:(NSIndexPath*)sender];
        }
        [vc setProject:_project];
    } else if ([segue.identifier isEqualToString:@"ChecklistItem"]) {
        BHChecklistItemViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[ChecklistItem class]])
            [vc setItem:(ChecklistItem*)sender];
    } else if ([segue.identifier isEqualToString:@"WorklistItem"]) {
        BHTaskViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[WorklistItem class]])
            [vc setWorklistItem:(WorklistItem*)sender];
    } else if ([segue.identifier isEqualToString:@"Alerts"]) {
        BHActivitiesViewController *vc = [segue destinationViewController];
        NSOrderedSet *set;
        if ([sender isKindOfClass:[NSOrderedSet class]]){
            set = (NSOrderedSet*)sender;
            if ([set.firstObject isKindOfClass:[Activity class]]){
                [vc setActivities:set];
            } else if ([set.firstObject isKindOfClass:[Reminder class]]){
                
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Intro Stuff
- (void)slide1 {
    BHOverlayView *phases = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"The summary view shows a high-level breakdown for the project.";
    if (iPad){
        screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"synopsisiPad"]];
        [screenshotView setFrame:CGRectMake(screenWidth()/2-355, 30, 710, 700)];
        [phases configureText:text atFrame:CGRectMake(screenWidth()/4, screenshotView.frame.origin.y + screenshotView.frame.size.height + 0, screenWidth()/2, 100)];
    } else {
        screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"detailScreenshot"]];
        [screenshotView setFrame:CGRectMake(20, 30, 280, 330)];
        [phases configureText:text atFrame:CGRectMake(20, screenshotView.frame.origin.y + screenshotView.frame.size.height + 10, screenWidth()-40, 100)];
    }
    [screenshotView setAlpha:0.0];
    
    [phases.tapGesture addTarget:self action:@selector(slide2:)];
    [overlayBackground addSubview:phases];
    
    [overlayBackground addSubview:screenshotView];
    [UIView animateWithDuration:.25 animations:^{
        [phases setAlpha:1.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.25 animations:^{
            [screenshotView setAlpha:1.0];
        }];
    }];
}

- (void)slide2:(UITapGestureRecognizer*)sender {
    BHOverlayView *percentages = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"Progress percentages are based on the number of completed items in each checklist phase.";
    if (IDIOM == IPAD){
        [percentages configureText:text atFrame:CGRectMake(screenWidth()/4, screenshotView.frame.origin.y + screenshotView.frame.size.height + 0, screenWidth()/2, 100)];
    } else {
        [percentages configureText:text atFrame:CGRectMake(20, screenshotView.frame.origin.y + screenshotView.frame.size.height + 0, screenWidth()-40, 100)];
    }
    
    [percentages.tapGesture addTarget:self action:@selector(slide3:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:percentages];
        [UIView animateWithDuration:.25 animations:^{
            [percentages setAlpha:1.0];
        }];
    }];
}

- (void)slide3:(UITapGestureRecognizer*)sender {
    BHOverlayView *scroll = [[BHOverlayView alloc] initWithFrame:screen];
    NSString *text = @"Scrolling down will show you recent documents as well as upcoming critical items.";
    if (IDIOM == IPAD){
        [scroll configureText:text atFrame:CGRectMake(screenWidth()/4, screenshotView.frame.origin.y + screenshotView.frame.size.height + 0, screenWidth()/2, 100)];
    } else {
        [scroll configureText:text atFrame:CGRectMake(20, screenshotView.frame.origin.y + screenshotView.frame.size.height + 0, screenWidth()-40, 100)];
    }
    
    [scroll.tapGesture addTarget:self action:@selector(scroll:)];
    
    [UIView animateWithDuration:.25 animations:^{
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
        [overlayBackground addSubview:scroll];
        [UIView animateWithDuration:.25 animations:^{
            [scroll setAlpha:1.0];
        }];
    }];
}

- (void)scroll:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.25 animations:^{
        [screenshotView setAlpha:0.0];
        [sender.view setAlpha:0.0];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.25 animations:^{
            [overlayBackground setAlpha:0.0];
            [sender.view removeFromSuperview];
            [screenshotView removeFromSuperview];
        }completion:^(BOOL finished) {
            if (_project.recentDocuments.count > 0)[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [overlayBackground removeFromSuperview];
        }];
    }];
}

- (void)endIntro:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:.25 animations:^{
        [overlayBackground setAlpha:0.0];
    }completion:^(BOOL finished) {
        [overlayBackground removeFromSuperview];
    }];
}

@end
