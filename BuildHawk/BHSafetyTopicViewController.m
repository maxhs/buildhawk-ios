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
    [infoTextView setFont:[UIFont systemFontOfSize:17]];
    [infoTextView setScrollEnabled:NO];
    textViewHeight = [infoTextView sizeThatFits:CGSizeMake(self.tableView.frame.size.width-8, CGFLOAT_MAX)].height;
    [infoTextView setFrame:CGRectMake(4, 0, self.tableView.frame.size.width-8, textViewHeight)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [cell.textLabel setFont:[UIFont boldSystemFontOfSize:18]];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
