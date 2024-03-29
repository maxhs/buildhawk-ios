//
//  BHMapViewController.m
//  BuildHawk
//
//  Created by Max Haines-Stiles on 7/17/14.
//  Copyright (c) 2014 BuildHawk. All rights reserved.
//

#import "BHMapViewController.h"
#import "Address.h"

@interface BHMapViewController () <CLLocationManagerDelegate, MKMapViewDelegate> {
    UIBarButtonItem *backButton;
    UIBarButtonItem *mapTypeBarButton;
    BOOL mapMode;
    MKMapView *_mapView;
    MKPointAnnotation *annotation;
}

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BHMapViewController

@synthesize locationManager = _locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    self.title = _project.name;
    
    _locationManager = [[CLLocationManager alloc] init];
    if (SYSTEM_VERSION >= 8.f){
        [_locationManager requestAlwaysAuthorization];
        //[_locationManager requestWhenInUseAuthorization];
    }
    
    _mapView = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [_mapView setShowsUserLocation:YES];
    [_mapView setMapType:MKMapTypeHybrid];
    
    [self.view addSubview:_mapView];
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake([_project.address.latitude floatValue], [_project.address.longitude floatValue]);
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.001;
    span.longitudeDelta = 0.001;
    
    region.span = span;
    region.center = location;
    
    [_mapView setRegion:region animated:YES];
    [_mapView regionThatFits:region];
    [_mapView setZoomEnabled:YES];
    [_mapView setScrollEnabled:YES];
    [_mapView setShowsUserLocation:YES];
    
    annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:location];
    [annotation setTitle:_project.name];
    [annotation setSubtitle:_project.address.formattedAddress];
    [_mapView addAnnotation:annotation];
    
    mapTypeBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapType)];
    self.navigationItem.rightBarButtonItem = mapTypeBarButton;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_mapView selectAnnotation:annotation animated:YES];
}

- (void)toggleMapType {
    if (mapMode){
        [_mapView setMapType:MKMapTypeSatellite];
        [mapTypeBarButton setTitle:@"Map"];
        mapMode = NO;
    } else {
        [_mapView setMapType:MKMapTypeStandard];
        [mapTypeBarButton setTitle:@"Satellite"];
        mapMode = YES;
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
