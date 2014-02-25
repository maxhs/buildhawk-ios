//
//  BHWebViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHPhoto.h"

@interface BHWebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) BHPhoto *photo;
@end
