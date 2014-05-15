//
//  BHWebViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHWebViewController.h"

@interface BHWebViewController ()

@end

@implementation BHWebViewController

@synthesize photo = _photo;

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
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_photo.original]]];
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
