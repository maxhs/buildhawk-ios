//
//  BHWebViewController.h
//  BuildHawk
//
//  Created by Max Haines-Stiles on 2/22/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

@interface BHWebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) Photo *photo;
@end
