//
//  BHSafetyTopicViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 6/3/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHSafetyTopicViewController.h"

@interface BHSafetyTopicViewController () {
    UIBarButtonItem *backButton;
    NSAttributedString *attributedInfo;
    UITextView *infoTextView;
    CGFloat textViewHeight;
}

@end

@implementation BHSafetyTopicViewController
@synthesize  safetyTopic = _safetyTopic;

- (void)viewDidLoad
{
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    attributedInfo = [[NSAttributedString alloc] initWithData:[_safetyTopic.info dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    infoTextView = [[UITextView alloc] initWithFrame:CGRectMake(4, 0, self.tableView.frame.size.width-8, self.tableView.frame.size.height)];
    [infoTextView setAttributedText:attributedInfo];
    [infoTextView setTextColor:[UIColor blackColor]];
    [infoTextView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
    [infoTextView setScrollEnabled:NO];
    infoTextView.editable = NO;
    textViewHeight = [infoTextView sizeThatFits:CGSizeMake(self.tableView.frame.size.width-8, CGFLOAT_MAX)].height;
    [infoTextView setFrame:CGRectMake(4, 0, self.tableView.frame.size.width-8, textViewHeight)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [ProgressHUD dismiss];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TitleCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.textLabel setText:_safetyTopic.title];
        [cell.textLabel setTextColor:[UIColor blackColor]];
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadProSemibold] size:0]];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.textLabel setNumberOfLines:0];
        if (_safetyTopic.info.length){
            [cell addSubview:infoTextView];
            [cell.textLabel setHidden:YES];
        } else {
            [cell.textLabel setHidden:NO];
            [cell.textLabel setText:@"No description..."];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        }
        [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMyriadPro] size:0]];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 80;
    } else {
        return textViewHeight;
    }
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
