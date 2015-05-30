//
//  BHWebViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHWebViewController.h"
#import <MessageUI/MessageUI.h>
#import "Photo+helper.h"
#import "Project+helper.h"
#import "BHAppDelegate.h"

@interface BHWebViewController () <MFMailComposeViewControllerDelegate> {
    UIBarButtonItem *xButton;
}

@end

@implementation BHWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.photo){
        self.photo = [self.photo MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        if (self.photo.localFilePath.length){
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.photo.localFilePath]]];
        } else {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.photo.original]]];
        }
        UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
        self.navigationItem.rightBarButtonItem = shareButton;
    } else if (self.url) {
        xButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = xButton;
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

- (void)share {
    [ProgressHUD show:@"Preparing to share project doc..."];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self actuallyEmailPhoto];
    });
}
    
- (void)actuallyEmailPhoto {
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setDefaultAppearances];
    MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
    emailer.mailComposeDelegate = self;
    
    [emailer setSubject:[NSString stringWithFormat:@"%@: \"%@\"",self.photo.project.name, self.photo.fileName]];
    if ([self.photo.original rangeOfString:@"pdf"].location == NSNotFound){
        //[emailer addAttachmentData:UIImagePNGRepresentation(self.photo) mimeType:@"png" fileName:photo.photo.fileName];
    } else {
        NSData *pdfData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.photo.original]];
        [emailer addAttachmentData:pdfData mimeType:@"application/pdf" fileName:self.photo.fileName];
    }
    
    if (IDIOM == IPAD) {
        emailer.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    
    [self presentViewController:emailer animated:YES completion:^{
        [ProgressHUD dismiss];
    }];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
                                                        message:NSLocalizedString(@"Email failed to send. Please try again.", nil)
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
    }
    [(BHAppDelegate*)[UIApplication sharedApplication].delegate setToBuildHawkAppearances];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [ProgressHUD show:@"Loading..."];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
    [ProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [ProgressHUD dismiss];
}

- (void)viewDidDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewDidDisappear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
