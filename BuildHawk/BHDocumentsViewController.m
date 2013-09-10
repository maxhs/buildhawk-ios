//
//  BHDocumentsViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 8/30/13.
//  Copyright (c) 2013 BuildHawk. All rights reserved.
//

#import "BHDocumentsViewController.h"

@interface BHDocumentsViewController ()

-(IBAction)backToDashboard;
@end

@implementation BHDocumentsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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

@end
