//
//  CustomMapViewController.m
//  CustomMapComponent
//
//  Created by Optimus Information on 16/10/12.
//  Copyright (c) 2012 Optimus Information. All rights reserved.
//

#import "CustomMapViewController.h"
#import "FormDetailsViewController.h"

@interface CustomMapViewController ()

@end

@implementation CustomMapViewController

#define MAP_OFFSET 268435456
#define MAP_RADIUS 85445659.44705395

int zoomCounter;
int scrollCounter;

/*
 Check user device
 */
- (BOOL) isPad
{
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	    
    // Add title on the navigation bar.
    [self.navigationItem setTitle:@"Custom Map"];
    
    // Set mapview delegate.
    [self.myMapView setDelegate:self];
    
    if([CLLocationManager locationServicesEnabled])
    {
        self.locationManager = [[CLLocationManager alloc] init];
        
        // Set locationmanager delegate.
        [self.locationManager setDelegate:self];
        
        self.locationManager.distanceFilter = kCLDistanceFilterNone;        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        [self.locationManager startUpdatingLocation];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Location services is not enabled" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    // Add a long press gester reconizer to show a flag on the map by tapping on the map.
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnMap)];
    [self.myMapView addGestureRecognizer:longPressGesture];
    
    
    // Add a TapGestureRecognizer to close map pop-up view.
    singleTapGester = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMapPopUp:)];
    singleTapGester.delegate = self;
    singleTapGester.numberOfTouchesRequired =1;
    
    // Add gesture recognize to mapview.
    [self.myMapView addGestureRecognizer:singleTapGester];
}

/*
 Delegate method return the default device location coordinates.
 */
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(newLocation.coordinate.latitude !=0.0 && newLocation.coordinate.longitude!=0.0)
    {
        NSLog(@"lat %f and long %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
        defaultLocation = newLocation;
        
        [self.locationManager stopUpdatingLocation];
        
        // Navigate to user default location.
        [self showDefaultLocation:nil];
        
        // Fetch default location details using reverse geocoding.
        [self defaultLocationInformation:defaultLocation.coordinate.latitude :defaultLocation.coordinate.longitude];        
    }
}

/*
 Method navigate to user default location by tapping 'Default Location' button.
 */
-(IBAction)showDefaultLocation:(id)sender
{    
    [self.myMapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    self.myMapView.showsUserLocation = YES;
}

/*
  Method to drop a pin on the map by tapping on the map. 
 */
-(void)handleTapOnMap
{
    @try
    {
        if(longPressGesture.state != UIGestureRecognizerStateBegan)
        {
            // If the gesture recognizer has received touch objects recognized as a continuos gesture, then return.
            return;
        }
        
        // Here we get the CGPoint for the touch and convert it to latitude and longitude coordinates to display on the map
        CGPoint touchPoint = [longPressGesture locationInView:self.myMapView];
        touchLocationCordinate = [self.myMapView convertPoint:touchPoint toCoordinateFromView:self.myMapView];
        [self locationInformation:touchLocationCordinate.latitude:touchLocationCordinate.longitude];
    }
    @catch (NSException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Can not find location coordinates" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

/*
 Method return information for location touched on the map.
 */
-(void)locationInformation:(float)latitudeValue:(float)longitudeValue
{    
    NSLog(@"latitudeValue %f",latitudeValue);
    NSLog(@"longitudeValue %f",longitudeValue);
    
    // Remove older pin before drawing a new pin.
    if (pindropAnnotation != nil)
    {
        [self.myMapView removeAnnotation:pindropAnnotation];
    }    
    
    locationInfoDictionary = [[NSMutableDictionary alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitudeValue longitude:longitudeValue];
    
    // Use CLGeocoder class to find the information for the location.
    myGeocoder = [[CLGeocoder alloc] init];
    
    [myGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if(error == nil && [placemarks count] > 0)
        {
            CLPlacemark *placeMark = [placemarks objectAtIndex:0];
           NSString *touchedLocation = [[placeMark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];                          
            NSString *isoCountryCode = placeMark.ISOcountryCode;           
            NSString *country = placeMark.country;           
            NSString *postalCode = placeMark.postalCode;      
            NSString *subAdminArea = placeMark.subAdministrativeArea;          
            NSString *locality = placeMark.locality;          
            NSString *subLocality = placeMark.subLocality;            
            [locationInfoDictionary setValue:touchedLocation forKey:@"touchedLocation"];
            [locationInfoDictionary setValue:isoCountryCode forKey:@"ISOcountryCode"];
            [locationInfoDictionary setValue:country forKey:@"country"];
            [locationInfoDictionary setValue:postalCode forKey:@"postalCode"];
            [locationInfoDictionary setValue:subAdminArea forKey:@"subdomainArea"];
            [locationInfoDictionary setValue:locality forKey:@"locality"];
            [locationInfoDictionary setValue:subLocality forKey:@"subLocality"];
            NSLog(@"location info dict %@", locationInfoDictionary);            
        }
        else if(error ==nil && [placemarks count] == 0)
        {
            NSLog(@"No result found");
        }
        else if(error !=nil)
        {
            NSLog(@"An error occurred = %@", error);
        }
        
        // Create the annotation and add it to the map
        pindropAnnotation = [[CustomAnnotation alloc] initWithCoordinates:location.coordinate];        
        pindropAnnotation.detailsDictionary = locationInfoDictionary;
        [self.myMapView addAnnotation:pindropAnnotation];

    }];
}

/*
 Method return information for user default location.
 This method is same as "locationInformation" method, only  annotation class is different. 
 We can use same method by taking a bool varibale and check condition based on that.
 But for library purpose i am making two seprate function.
 */
-(void)defaultLocationInformation:(float)latitudeValue:(float)longitudeValue
{
    NSLog(@"latitudeValue %f",latitudeValue);
    NSLog(@"longitudeValue %f",longitudeValue);
       
    userDefaultLocationInfoDictionary = [[NSMutableDictionary alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitudeValue longitude:longitudeValue];
    
    // Use CLGeocoder class to find the information for the location.
    myGeocoder = [[CLGeocoder alloc] init];
    
    [myGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if(error == nil && [placemarks count] > 0)
        {
            CLPlacemark *placeMark = [placemarks objectAtIndex:0];
            NSString *touchedLocation = [[placeMark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
            NSString *isoCountryCode = placeMark.ISOcountryCode;
            NSString *country = placeMark.country;
            NSString *postalCode = placeMark.postalCode;
       
            NSString *subAdminArea = placeMark.subAdministrativeArea;
            NSString *locality = placeMark.locality;
            NSString *subLocality = placeMark.subLocality;
          
            [userDefaultLocationInfoDictionary setValue:touchedLocation forKey:@"touchedLocation"];
            [userDefaultLocationInfoDictionary setValue:isoCountryCode forKey:@"ISOcountryCode"];
            [userDefaultLocationInfoDictionary setValue:country forKey:@"country"];
            [userDefaultLocationInfoDictionary setValue:postalCode forKey:@"postalCode"];
            [userDefaultLocationInfoDictionary setValue:subAdminArea forKey:@"subdomainArea"];
            [userDefaultLocationInfoDictionary setValue:locality forKey:@"locality"];
            [userDefaultLocationInfoDictionary setValue:subLocality forKey:@"subLocality"];           
        }
        else if(error ==nil && [placemarks count] == 0)
        {
            NSLog(@"No result found");
        }
        else if(error !=nil)
        {
            NSLog(@"An error occurred = %@", error);
        }
        NSLog(@"location info dict %@", userDefaultLocationInfoDictionary);      
    }];
}

/*
 Delegate method to customize pin 
 */
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{ 
    if([annotation isKindOfClass:[MKUserLocation class]])
    {        
        static NSString *annotationIdentifier = @"Annotation";
        MKAnnotationView *cutomAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        
        if (cutomAnnotationView == nil)
        {
            // If we fail to reuse the pin, we will create a new one.
            cutomAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        cutomAnnotationView.canShowCallout = NO;        
        cutomAnnotationView.image = [UIImage imageNamed:@"icon_check.png"];
        cutomAnnotationView.frame = CGRectMake(0.0f, 0.0f, 38.0f, 38.0f);
        return cutomAnnotationView;
    }
    else if ([annotation isKindOfClass:[CustomAnnotation class]])
    {
        static NSString *annotationIdentifier = @"CustomAnnotation";
        MKAnnotationView *customView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        
        if (customView == nil)
        {
            // If we fail to reuse the pin, we will create a new one.
            customView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        
        customView.canShowCallout = NO;
        customView.image = [UIImage imageNamed:@"flag.png"];
        customView.frame = CGRectMake(0.0f, 0.0f, 38.0f, 38.0f);
        return customView;     
        
    }
    return nil;
}

/*
 Delegate method: when user taps on the annotation the tap event captured in this method.
 I am showing custom callout, so here i am creating a custom view to show as map callout. 
 
 By fetching location details using reverseGeocodeLocation class, here i am showing few details on the callout.
 */
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    [timer invalidate];
    [zoomTimer invalidate];
    annotationItemsDict = [[NSMutableDictionary alloc] init];
    
    if ([view.annotation isKindOfClass:[MKUserLocation class]])
    {
        [annotationItemsDict  setDictionary:userDefaultLocationInfoDictionary];       
    }
    else if ([view.annotation isKindOfClass:[CustomAnnotation class]])
    {
        CustomAnnotation *customAnnotation = view.annotation;
        [annotationItemsDict setDictionary:customAnnotation.detailsDictionary];        
    }
    
    CGPoint annotationCenter = [mapView convertCoordinate:view.annotation.coordinate toPointToView:mapView];
     NSLog(@"annotationCenter.x %f annotationCenter.y %f", annotationCenter.x, annotationCenter.y);    

    NSLog(@"annotationItemsDict %@", annotationItemsDict);
    NSString *touchedLocation = [annotationItemsDict valueForKey:@"touchedLocation"];
    NSString *country = [annotationItemsDict valueForKey:@"country"];
    NSString *zipCode = [annotationItemsDict valueForKey:@"postalCode"];    
    
    customCalloutView = [[UIView alloc] init];
    
    UILabel *touchedLocationLabel = [[UILabel alloc]initWithFrame:CGRectMake(15.0f, 10.0f, 160.0f, 30.0f)];
    [touchedLocationLabel setBackgroundColor:[UIColor clearColor]];
    [touchedLocationLabel setText:touchedLocation];
    touchedLocationLabel.font = [UIFont boldSystemFontOfSize:16];
    [customCalloutView addSubview:touchedLocationLabel];
    
    UILabel *countryLabel = [[UILabel alloc]initWithFrame:CGRectMake(15.0f, 40.0f, 160.0f, 30.0f)];
    [countryLabel setBackgroundColor:[UIColor clearColor]];
    [countryLabel setText:country];
    countryLabel.font = [UIFont boldSystemFontOfSize:16];
    [customCalloutView addSubview:countryLabel];
    
    UILabel *zipCodeLabel = [[UILabel alloc]initWithFrame:CGRectMake(15.0f, 70.0f, 160.0f, 30.0f)];
    [zipCodeLabel setBackgroundColor:[UIColor clearColor]];
    [zipCodeLabel setText:zipCode];
    zipCodeLabel.font = [UIFont boldSystemFontOfSize:16];
    [customCalloutView addSubview:zipCodeLabel];
    
    customCalloutView.backgroundColor = [UIColor whiteColor];
    
    UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    accessoryButton.frame = CGRectMake(240.0f, 10.0f, 30.0f, 30.0f);
    [accessoryButton addTarget:self action:@selector(showDetailsForm) forControlEvents:UIControlEventTouchUpInside];
    [customCalloutView addSubview:accessoryButton];
    
    if([self isPad])
    {
        customCalloutView.frame = CGRectMake(10.0f, 50.0f, 280.0f, 160.0f);

        CustomMapViewController *presentViewController = [[CustomMapViewController alloc] init];
        
        popOverController = [[UIPopoverController alloc] initWithContentViewController:presentViewController];
        [presentViewController setView:customCalloutView];
        
        // Declare the size of popover controller contents.
        popOverController.popoverContentSize = CGSizeMake(280.0f, 170.0f);
        
        // Show the popover next to the annotation view (pin)
        [popOverController presentPopoverFromRect:view.bounds inView:view
                         permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        customCalloutView.frame = CGRectMake(10.0f, 50.0f, 280.0f, 160.0f);
        customCalloutView.layer.borderWidth = 6.0f;
        customCalloutView.layer.cornerRadius = 8.0f;
        customCalloutView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        [self.view addSubview:customCalloutView];
    }
    selectedAnnotation = view;
}

-(void)showDetailsForm
{      
    [self.myMapView deselectAnnotation:selectedAnnotation.annotation animated:YES];
    
    FormDetailsViewController *formDetailsControlller = [self.storyboard instantiateViewControllerWithIdentifier:@"formDetailsController"];
    formDetailsControlller.locationInformationDictionary =annotationItemsDict;
    
    [self.navigationController pushViewController:formDetailsControlller animated:YES];
    
    if([self isPad])
    {
        // Close popOverController.
        [popOverController dismissPopoverAnimated:YES];
    }
    else
    {
        // Close map callout view.
        [customCalloutView removeFromSuperview];
    }
}

/*
Method to recognize tap gesture along with map gesture events.
*/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:
(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

/*
 Method to close custom callout by tapping on the map.
 */
-(void)closeMapPopUp:sender
{
    // Removing the custom callout view from the main view by tapping on the map outside the custom callout view.
    
    if(![self isPad])
    {
        // Close map callout view.
        [customCalloutView removeFromSuperview];
    }
    [self.myMapView deselectAnnotation:selectedAnnotation.annotation animated:YES];
}

/*
 MKMapView delegate method indicating map region is changed.
 */
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"animated %d",animated);
    changedRegion = self.myMapView.region;
    
    if(animated)
    {
        [timer invalidate];
        [zoomTimer invalidate];
        
        // Timer to show location coordinate after 3 seconds of map zoom.
        NSTimer *theTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownZoomTracker:) userInfo:nil repeats:YES];
        
        // Assume a there's a property timer that will retain the created timer for future reference.
        zoomTimer = theTimer;
        
        // Counter that track the number of seconds before count down reach.
        zoomCounter = 3;
    }
    else
    {        
        [timer invalidate];
        [zoomTimer invalidate];
        
        // Timer to show location coordinate after 3 seconds of map scroll.
        NSTimer *theTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownScrollTracker:) userInfo:nil repeats:YES];
        
        // Assume a there's a property timer that will retain the created timer for future reference.
        timer = theTimer;
        
        // Counter that track the number of seconds before count down reach.
        scrollCounter = 3;
    }
}

/*
 Method to log location coordinate after 3 seconds of map scrolling.
 */
- (void)countdownScrollTracker:(NSTimer *)theTimer
{
    scrollCounter--;
    if (scrollCounter < 0)
    {
        [timer invalidate];
        timer = nil;
        scrollCounter = 0;
        
        // Show new region coordinate.
        [self showCurrentRegionCoordinates];        
    }
}

/* 
 Method to log zoom level after 3 seconds of map zooming.
 */
- (void)countdownZoomTracker:(NSTimer *)theTimer
{
    zoomCounter--;
    if (zoomCounter < 0)
    {
        [zoomTimer invalidate];
        zoomTimer = nil;
        zoomCounter = 0;
        
        // Show Zoom level
        [self showCurrentZoomLevel];
    }
}

/*
 Method to calculate zoom level if user change map zoom level.
 */
-(void)showCurrentZoomLevel
{
     double centerPixelX = [self longitudeToPixelSpaceX: changedRegion.center.longitude];
     double topLeftPixelX = [self longitudeToPixelSpaceX: changedRegion.center.longitude - changedRegion.span.longitudeDelta / 2];
     
     double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
     CGSize mapSizeInPixels = self.myMapView.bounds.size;
     double zoomScale = scaledMapWidth / mapSizeInPixels.width;
     
     double zoomExponent = log(zoomScale) / log(2);
     double zoom = 20 - zoomExponent;
     
     NSLog(@"Zoom level is %f", zoom);
}

/*
 Method use to find zoom level.
 */
- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MAP_OFFSET + MAP_RADIUS * longitude * M_PI / 180.0);
}

/*
 Method to get new location coordinate after user scroll a map.
 */
-(void)showCurrentRegionCoordinates
{
    float newLatitude = changedRegion.center.latitude;
    float newLongitude = changedRegion.center.longitude;
    
    NSLog(@" new latitude is %f", newLatitude);
    NSLog(@" new longitude is %f", newLongitude);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
