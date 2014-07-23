//
//  BHWebViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHWebViewController.h"

@interface BHWebViewController () {
    UIBarButtonItem *xButton;
}

@end

@implementation BHWebViewController

@synthesize url = _url;
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
    if (_photo){
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_photo.original]]];
    } else if (_url) {
        xButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = xButton;
        [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
    }
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
