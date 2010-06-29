/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//
// A global location management object.
//
#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CLLocationManager.h>

#import "WFLocationManager.h"
#import "WFAppStateStore.h"

#define LOCATION_UPDATE_TIMEOUT 40.0

#ifdef FAKE_LOCATION_DEMO
@interface WFLocationManager()
- (void)accuracyTimerFired:(NSTimer*)theTimer;
@end
#endif

static WFLocationManager *theLocationManager;

NSString *LAST_LONGITUDE_KEY = @"lastLocationLongitude";
NSString *LAST_LATITUDE_KEY = @"lastLocationLatitude";
NSString *LAST_LOCATION_DATE_KEY = @"lastLocationDate";

@implementation WFLocationManager

@dynamic currentLocation;

- (CLLocation *)currentLocation { return currentLocation; }
- (void)setCurrentLocation:(CLLocation *)value
{
    if (value != currentLocation) {
        [currentLocation release];
        currentLocation = [value retain];
        [[WFAppStateStore sharedStateStore]
            setObject:currentLocation
               forKey:@"WFLocationManager:currentLocation"];
    }
}

+ (WFLocationManager *)sharedManager
{
    if (theLocationManager == nil) {
        [[self alloc] init]; // assignment not done here
    }
    return theLocationManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    if (theLocationManager == nil) {
        theLocationManager = [super allocWithZone:zone];
        return theLocationManager;  // assignment and return on first allocation
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)init
{
    if (self = [super init]) {
        currentLocation = nil;
        usingFakeLocation = NO;
        delegateArray = [[NSMutableArray alloc] init];


        // fire up initial location
        if (locationQueryTimeout) {
            [locationQueryTimeout invalidate]; // must do this, otherwise runLoop will retain this
            [locationQueryTimeout release];
        }

        locationQueryTimeout = [[NSTimer scheduledTimerWithTimeInterval:LOCATION_UPDATE_TIMEOUT
                                         target:self
                                         selector:@selector(locationQueryTimedOut:)
                                         userInfo:nil
                                         repeats:NO] retain];



        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self startUpdatingLocation];
        
        // Create fake location list
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"60.178404", @"lat",
                              @"24.938965", @"lon", nil];
        fakeLocations = [NSMutableDictionary dictionaryWithCapacity:10];
        [fakeLocations setObject:dict forKey:@"Helsinki"];
        
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"65.015491", @"lat",
                @"25.472832", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Oulu"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"55.703903", @"lat",
                @"13.205566", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Lund"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"48.857261", @"lat",
                @"2.354164", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Paris"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"51.503474", @"lat",
                @"-0.117041", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"London"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"40.75766", @"lat",
                @"-73.983307", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"New York"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"60.185254", @"lat",
                @"24.814596", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Espoo"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"59.331592", @"lat",
                @"18.036439", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Stockholm"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"41.90199", @"lat",
                @"12.461522", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Rome"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"40.414542", @"lat",
                @"-3.688595", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Madrid"];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                @"52.514445", @"lat",
                @"13.352251", @"lon", nil];
        [fakeLocations setObject:dict forKey:@"Berlin"];
    }
    return self;
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // Ignore checks if we are using fake location
    if (!usingFakeLocation) {
        // Check that received location is valid
        if (newLocation.horizontalAccuracy < 0 || fabs([newLocation.timestamp timeIntervalSinceNow]) > 60) {
            // Location invalid. Ignore it.
            return;
        }
        self.currentLocation = newLocation;
    }

    if (locationQueryTimeout) {
        [locationQueryTimeout invalidate];
        locationQueryTimeout = nil;
    }

    for (NSObject<CLLocationManagerDelegate> *delegate in delegateArray) {
        if ([delegate
            respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
        {
            [delegate locationManager:manager didUpdateToLocation:currentLocation
                         fromLocation:oldLocation];
        }
    }
}

- (void) locationQueryTimedOut:(NSTimer *) timer
{
    UIAlertView *alert = 
        [[UIAlertView alloc] 
            initWithTitle:@"Your location could not be determined" message:@"Please try again"
            delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];    
}

- (void)addDelegate:(id<CLLocationManagerDelegate>)delegate
{
    [delegateArray addObject:delegate];
}

- (void)removeDelegate:(id)delegate
{
    [delegateArray removeObject:delegate];
}

- (void)startUpdatingLocation
{
    if (!usingFakeLocation) {
        [locationManager startUpdatingLocation];

        if (!currentLocation) {
            currentLocation = [[[WFAppStateStore sharedStateStore]
                objectForKey:@"WFLocationManager:currentLocation"] retain];

            if (currentLocation) {
                [self locationManager:locationManager
                  didUpdateToLocation:currentLocation fromLocation:nil];
            }
        }
    }
    else
        [self locationManager:locationManager didUpdateToLocation:currentLocation fromLocation:nil];
}

- (void)stopUpdatingLocation
{
    [locationManager stopUpdatingLocation];
}

- (void)dealloc
{
    
    [delegateArray release];
        // fire up initial location
    if (locationQueryTimeout) 
        [locationQueryTimeout invalidate]; // must do this, otherwise runLoop will retain this

    [locationQueryTimeout release];

    [locationManager release];
    [super dealloc];
}

- (void)setFakeLocation:(CLLocationCoordinate2D)coordinate accuracy:(CLLocationAccuracy)accuracy
{
    if (coordinate.latitude != 0 && coordinate.longitude != 0 && accuracy != 0) {
        usingFakeLocation = YES;
#ifdef FAKE_LOCATION_DEMO
        //accuracyArray = [[NSMutableArray alloc] init];
        NSNumber *high = [NSNumber numberWithDouble:accuracy * 4];
        NSNumber *middle = [NSNumber numberWithDouble:accuracy * 2];
        if ([high doubleValue] < 500)
            high = [NSNumber numberWithDouble:500];;
        if ([middle doubleValue] < 100)
            middle = [NSNumber numberWithDouble:100];
        accuracyArray = [[NSArray arrayWithObjects:high, middle, [NSNumber numberWithDouble:accuracy], nil] retain];
        
        CLLocation *fakeLoc = [[CLLocation alloc] initWithCoordinate:coordinate
                                                            altitude:1
                                                  horizontalAccuracy:[high doubleValue]
                                                    verticalAccuracy:[high doubleValue]
                                                           timestamp:[NSDate date]];
        
        accuracyTimer = [[NSTimer scheduledTimerWithTimeInterval:3
                                                          target:self
                                                        selector:@selector(accuracyTimerFired:)
                                                        userInfo:[NSNumber numberWithInt:1]
                                                         repeats:NO] retain];
#else
        CLLocation *fakeLoc = [[CLLocation alloc] initWithCoordinate:coordinate
                                                            altitude:1
                                                  horizontalAccuracy:accuracy
                                                    verticalAccuracy:accuracy
                                                           timestamp:[NSDate date]];
#endif
        
        self.currentLocation = fakeLoc;
        [fakeLoc release];
    }
    else {
        usingFakeLocation = NO;
    }
}

- (BOOL)setFakePlace:(NSString *)nameOfThePlace accuracy:(CLLocationAccuracy)accuracy
{
    if (nil != [fakeLocations objectForKey:nameOfThePlace]) {
        NSDictionary *dict = [fakeLocations objectForKey:nameOfThePlace];
        CLLocationCoordinate2D coords = {[[dict objectForKey:@"lat"] floatValue],
            [[dict objectForKey:@"lon"] floatValue]};
        
        [self setFakeLocation:coords accuracy:accuracy];
    }
    else
        return NO;
    
    return YES;
}

#ifdef FAKE_LOCATION_DEMO
- (void)accuracyTimerFired:(NSTimer*)theTimer
{
    if (usingFakeLocation) {
        int index = [[theTimer userInfo] intValue];
        NSNumber *newAcc = nil;
        if (index < [accuracyArray count])
            newAcc = [accuracyArray objectAtIndex:index];
        if (newAcc) {
            CLLocation *fakeLoc = [[CLLocation alloc] initWithCoordinate:self.currentLocation.coordinate
                                                                altitude:1
                                                      horizontalAccuracy:[newAcc doubleValue]
                                                        verticalAccuracy:[newAcc doubleValue]
                                                            timestamp:[NSDate date]];
            self.currentLocation = fakeLoc;
            [fakeLoc release];
            
            [accuracyTimer invalidate];
            [accuracyTimer release];
            accuracyTimer = nil;

            accuracyTimer = [[NSTimer scheduledTimerWithTimeInterval:3
                                                              target:self
                                                            selector:@selector(accuracyTimerFired:)
                                                            userInfo:[NSNumber numberWithInt:index + 1]
                                                             repeats:NO] retain];
            
            [self locationManager:locationManager didUpdateToLocation:currentLocation fromLocation:nil];
        }
    }
}
#endif

/* Singleton stuff */
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}
 
- (void)release
{
    //do nothing
}
 
- (id)autorelease
{
    return self;
}

@end
