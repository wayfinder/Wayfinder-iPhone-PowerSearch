/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFCommandRouter.h"
#import "WFResultsModel.h"
#import "WFFavoriteModel.h"
#import "WFVectorMapView.h"
#import "WFAboutViewController.h"
#import "WFVectorMapViewController.h"
#import "WFSearchViewController.h"
#import "WFCategoryListController.h"
#import "WFAddrParser.h"

@interface WFCommandRouter()
- (void) setMapVisible;
- (void) setMapTabActive;
- (void) setShadowsHidden:(BOOL) hidden;
@end

@implementation WFCommandRouter


static WFCommandRouter *SharedCommandRouter;

+ (WFCommandRouter*) SharedCommandRouter
{
	if(SharedCommandRouter == nil) 
	{
		SharedCommandRouter = [[self alloc] init];
    }
	
	return SharedCommandRouter;
}

- (id)init
{
    if (self = [super init])
	{
        pointerList = [[NSMutableDictionary dictionary] retain];
    }
    
    return self;
}

- (void) dealloc
{
    [pointerList release];
    [super dealloc];
}

- (void) setPointer:(id)ptr forId:(pointerId)ptrId
{
    [pointerList setObject:ptr forKey:[NSNumber numberWithInt:ptrId]];
    
    if (ptrId == mapViewPtr && [ptr respondsToSelector:@selector(clearResultsOnMap)]) {
        // Map view is used so often that save it separately
        mapView = ptr;
    }
}

- (WFResultsModel *) getResultModelForType:(searchType)type
{
    switch (type) {
        case categorySearchType:
            if (!categoryResults)
                categoryResults = [[WFResultsModel alloc] init];
            return categoryResults;
            break;
        case textSearchType:
            if (!textResults)
                textResults = [[WFResultsModel alloc] init];
            return textResults;
        default:
            return nil;
            break;
    }
}

// Closes details view is is open on map
- (void) setMapVisible
{
    UITabBarController *tabBarCtrl = [pointerList objectForKey:[NSNumber numberWithInt:tabBarPtr]];
    UINavigationController *mapNaviCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapTabNaviCtrlPtr]];
    WFVectorMapViewController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapViewCtrl]];
    
    if (mapView && tabBarCtrl && mapNaviCtrl && mapCtrl) {
        if ([mapView respondsToSelector:@selector(showItemOnMap:)] &&
            [tabBarCtrl respondsToSelector:@selector(setViewControllers:animated:)] &&
            [mapNaviCtrl respondsToSelector:@selector(popViewControllerAnimated:)] &&
            [mapCtrl respondsToSelector:@selector(showDetailsForItem:)]) {
            BOOL animate = NO;
            if (0 == tabBarCtrl.selectedIndex) {
                // We are in map view, animate transition if detail view is on
                animate = YES;
            }
            
            if ([mapNaviCtrl topViewController] != (UIViewController *)mapCtrl) {
                [mapNaviCtrl popToViewController:(UIViewController *)mapCtrl animated:animate];
            }
        }
        else
            NSLog(@"Invalid pointers in setMapVisible");
    }
    else
        NSLog(@"Pointers not set in setMapVisible");
}

- (void) setMapTabActive
{
    UITabBarController *tabBarCtrl = [pointerList objectForKey:[NSNumber numberWithInt:tabBarPtr]];
    
    if (tabBarCtrl && [tabBarCtrl respondsToSelector:@selector(setViewControllers:animated:)]) {
        if (0 != tabBarCtrl.selectedIndex)
            tabBarCtrl.selectedIndex = 0;
    }
}

- (void) showItemOnMap:(NSDictionary *)item
{
    if (mapView) {
        [mapView showItemOnMap:item];
        [self setMapVisible];
        [self setMapTabActive];
    }
}

- (void) showRouteTo:(NSDictionary *)item routeType:(routingType)routeType
{
    if (mapView) {
        [mapView showRouteTo:item routeType:routeType];
        [self setMapVisible];
        [self setMapTabActive];
    }
}

- (void) clearResultsOnMap
{
    if (mapView) {
        [mapView clearResultsOnMap];
    }
}

- (void) zoomMapToNearestResults
{
    if (mapView)
        [mapView zoomToNearestResults];
}

- (void) showMoreResultsOnMap
{
    if (mapView)
        [mapView showMoreResults];
}

- (void) showVisibleItemsOnMap
{
    if (mapView)
        [mapView showVisibleItemsOnMap];
}

- (void) didReceiveInitialLocation
{
    WFVectorMapViewController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapViewCtrl]];
    
    // Set different buttons active
    [self setControlsActive:YES];
    
    if (mapCtrl && [mapCtrl respondsToSelector:@selector(didReceiveInitialLocation)]) {
        [mapCtrl didReceiveInitialLocation];
    }
    else
        NSLog(@"didReceiveInitialLocation: Map controller pointer invalid");
    
    [[WFFavoriteModel SharedFavoriteArray] didReceiveInitialLocation];
}

- (void) didStartFollowingLocation
{
    // Called when map starts to follow user indipendently
    WFVectorMapViewController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapViewCtrl]];
    
    if (mapCtrl && [mapCtrl respondsToSelector:@selector(didStartFollowingLocation)]) {
        [mapCtrl didStartFollowingLocation];
    }
    else
        NSLog(@"didStartFollowingLocation: Map controller pointer invalid");
}

- (void) didStopFollowingLocation
{
    // Called when map is no longer centered on user constantly
    WFVectorMapViewController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapViewCtrl]];
    
    if (mapCtrl && [mapCtrl respondsToSelector:@selector(didStopFollowingLocation)]) {
        [mapCtrl didStopFollowingLocation];
    }
    else
        NSLog(@"didStopFollowingLocation: Map controller pointer invalid");
}

- (void) didFinishUpdatingLocation
{
    WFVectorMapViewController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapViewCtrl]];
    
    if (mapCtrl && [mapCtrl respondsToSelector:@selector(didFinishUpdatingLocation)]) {
        [mapCtrl didFinishUpdatingLocation];
    }
    else
        NSLog(@"didFinishUpdatingLocation: Map controller pointer invalid");
}

- (void) setControlsActive:(BOOL)active
{
    // Set tab bar buttons activity
    // We can't get a direct pointer to UITabBar so we must set the button enabled state
    // through view controllers
    UINavigationController *mapCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapTabNaviCtrlPtr]];
    UINavigationController *searchCtrl = [pointerList objectForKey:[NSNumber numberWithInt:searchTabNaviCtrlPtr]];
    UINavigationController *catCtrl = [pointerList objectForKey:[NSNumber numberWithInt:categoryTabNaviCtrlPtr]];
    UINavigationController *favCtrl = [pointerList objectForKey:[NSNumber numberWithInt:favoriteTabNavCtrlPtr]];
    
    UIBarButtonItem *locBtn = [pointerList objectForKey:[NSNumber numberWithInt:locateButtonPtr]];
    UIBarButtonItem *abtBtn = [pointerList objectForKey:[NSNumber numberWithInt:aboutButtonPtr]];
    
    if (mapCtrl)
        mapCtrl.tabBarItem.enabled = active;
    if (searchCtrl)
        searchCtrl.tabBarItem.enabled = active;
    if (catCtrl)
        catCtrl.tabBarItem.enabled = active;
    if (favCtrl)
        favCtrl.tabBarItem.enabled = active;
    if (locBtn)
        locBtn.enabled = active;
    if (abtBtn)
        abtBtn.enabled = active;
}

// UITabBarControllerDelegate methods
- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    UINavigationController *srcPtr = [pointerList objectForKey:[NSNumber numberWithInt:searchTabNaviCtrlPtr]];
    UINavigationController *catPtr = [pointerList objectForKey:[NSNumber numberWithInt:categoryTabNaviCtrlPtr]];
    UINavigationController *favPtr = [pointerList objectForKey:[NSNumber numberWithInt:favoriteTabNavCtrlPtr]];
    
    // When user selects the text or category search window, set those
    // results visible in the map.
    if (viewController == srcPtr) {
        if (mapView)
            [mapView setResultModel:textResults];
#ifdef SHOW_RESULT_AMOUNT_IN_BADGE
        // Place a badge to the tab which results are shown on map
        viewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [textResults getResultsCount]];
        catPtr.tabBarItem.badgeValue = nil;
#endif
    }
    else if (viewController == catPtr) {
        if (mapView)
            [mapView setResultModel:categoryResults];
#ifdef SHOW_RESULT_AMOUNT_IN_BADGE
        // Place a badge to the tab which results are shown on map
        viewController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [categoryResults getResultsCount]];
        srcPtr.tabBarItem.badgeValue = nil;
#endif
    }
    else if (viewController == favPtr) {
        if (mapView)
            [mapView setResultModel:[WFFavoriteModel SharedFavoriteArray]];
    }
}

- (void) addAboutButtonTo:(UINavigationItem *)navItem
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [button setImage:[UIImage imageNamed:@"heart_info_inactive.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAboutView:) forControlEvents:UIControlEventTouchUpInside];
    navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    [button release];
}

- (void) showAboutView:(id) requestingViewPtr
{
    if (!animating) {
        animating = YES;
        UINavigationController *mainNavCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mainNavPtr]];
        if (!aboutViewCtrl)
            aboutViewCtrl = [[WFAboutViewController alloc] initWithNibName:nil bundle:nil];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration: 1.0];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:mainNavCtrl.view cache:YES];
        [mainNavCtrl pushViewController:aboutViewCtrl animated:NO];
        [UIView commitAnimations];
        [self setShadowsHidden:YES];
    }
}

- (void) closeAboutView
{
    UINavigationController *mainNavCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mainNavPtr]];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.75];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:mainNavCtrl.view cache:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector: @selector(animationComplete:finished:context:) ];
    [mainNavCtrl popViewControllerAnimated:NO];
    [UIView commitAnimations];
}

- (void) openAddressBookWithData:(NSDictionary *) itemInfo forNavController:(id) controller
{
    NSDictionary *info = [itemInfo objectForKey:@"info"];
    
    CFErrorRef *error = NULL;
    
    
    // Create a record.
    ABRecordRef person = ABPersonCreate();
    
    // name
    if ([itemInfo objectForKey:@"itemName"]) {
        //ABRecordSetValue(person, kABPersonFirstNameProperty, @"kate" , nil);
        ABRecordSetValue(person, kABPersonLastNameProperty, [itemInfo objectForKey:@"itemName"], nil);
    }
    
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);    
    NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
    
    // Address
    if (info) {
        // house & street
        NSString *numAddress = @"";
        
        WFAddrParser *parser = [[WFAddrParser alloc] init];
        numAddress = [parser parseStreetAddressForDict:itemInfo];
        [parser release];
        
        [addressDictionary setObject:numAddress forKey:(NSString *) kABPersonAddressStreetKey];
        
        if ([info objectForKey:@"state"]) {
            [addressDictionary setObject:[[info objectForKey:@"state"] objectForKey:@"value"] 
                                  forKey:(NSString *)kABPersonAddressStateKey];
        }
        
        if ([info objectForKey:@"vis_zip_code"]) {
            [addressDictionary setObject:[[info objectForKey:@"vis_zip_code"] objectForKey:@"value"] 
                                  forKey:(NSString *)kABPersonAddressZIPKey];
        }
        
    }
    
    if (info && [info objectForKey:@"vis_zip_area"]) {
        NSString *city = [[info objectForKey:@"vis_zip_area"] objectForKey:@"value"];
        [addressDictionary setObject:city forKey:(NSString *)kABPersonAddressCityKey];
    }
    else if ([itemInfo objectForKey:@"location_name"]) {
        [addressDictionary setObject:[itemInfo objectForKey:@"location_name"] forKey:(NSString *)kABPersonAddressCityKey];
    }
    
    
    
    ABMultiValueAddValueAndLabel(multi, addressDictionary, kABHomeLabel, NULL);   
    ABRecordSetValue(person, kABPersonAddressProperty, multi, NULL);
    
    // numbers
    if (info) {
        if ([info objectForKey:@"phone_number"]) {
            ABMutableMultiValueRef phoneNumberMultiValue = 
            ABMultiValueCreateMutable(kABStringPropertyType);
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue,[[info objectForKey:@"phone_number"] objectForKey:@"value"], 
                                         kABPersonPhoneMainLabel, NULL);
            ABRecordSetValue(person, kABPersonPhoneProperty,
                             phoneNumberMultiValue, error);
        }
        
        if ([info objectForKey:@"mobile_number"]) {
            ABMutableMultiValueRef phoneNumberMultiValue = 
            ABMultiValueCreateMutable(kABStringPropertyType);
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue,[[info objectForKey:@"mobile_number"] objectForKey:@"value"], 
                                         kABPersonPhoneMobileLabel, NULL);
            ABRecordSetValue(person, kABPersonPhoneProperty,
                             phoneNumberMultiValue, error);
        }        
        
        // URL
        if ([info objectForKey:@"url"]) {
            ABMutableMultiValueRef urlMultiValue = 
            ABMultiValueCreateMutable(kABStringPropertyType);
            ABMultiValueAddValueAndLabel(urlMultiValue,[[info objectForKey:@"url"] objectForKey:@"value"],
                                         kABPersonHomePageLabel, NULL);
            ABRecordSetValue(person, kABPersonURLProperty, urlMultiValue, error);                
        }
        
        // email
        if ([info objectForKey:@"email"]) {
            // a single email address
            ABMutableMultiValueRef emailMultiValue = 
            ABMultiValueCreateMutable(kABStringPropertyType);
            ABMultiValueAddValueAndLabel(emailMultiValue,[[info objectForKey:@"email"] objectForKey:@"value"], 
                                         kABHomeLabel, NULL);
            ABRecordSetValue(person, kABPersonEmailProperty, emailMultiValue, error);
        }
        // note
        
        // image
        if ([info objectForKey:@"image_url"]) {
            id path = [[info objectForKey:@"image_url"] objectForKey:@"value"];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];
            UIImage *img = [[UIImage alloc] initWithData:data];
            CFDataRef dataRef = CGDataProviderCopyData(CGImageGetDataProvider(img.CGImage));
            ABPersonSetImageData (person, dataRef, error);            
        }
        
    } // end info check
    
    
    ABUnknownPersonViewController *unknownPersonViewController =
    [[ABUnknownPersonViewController alloc] init];
    
    unknownPersonViewController.displayedPerson = person;
    unknownPersonViewController.allowsActions = YES;
    unknownPersonViewController.allowsAddingToAddressBook = YES;
    unknownPersonViewController.unknownPersonViewDelegate = self;
    CFRelease(person);
    

    [controller pushViewController:unknownPersonViewController animated:YES];
    [self setShadowsHidden:YES];
    [unknownPersonViewController release];
}

// ABUnknownPersonViewControllerDelegate

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController
                 didResolveToPerson:(ABRecordRef)person 
{
    NSLog(@"Dismiss address book with person @%", person);
    UINavigationController *mapNaviCtrl = [pointerList objectForKey:[NSNumber numberWithInt:mapTabNaviCtrlPtr]]; 
    [mapNaviCtrl popViewControllerAnimated:YES];
    [self setShadowsHidden:NO];
}

- (void) setShadowsHidden:(BOOL) hidden
{
    UIImageView *up = [pointerList objectForKey:[NSNumber numberWithInt:upperShadowPtr]];
    UIImageView *down = [pointerList objectForKey:[NSNumber numberWithInt:lowerShadowPtr]];
    down.hidden = up.hidden = hidden;
}

- (void) animationComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    animating = NO;
    [self setShadowsHidden:NO];
}


- (void) navigationController:(UINavigationController *)navigationController 
                    didShowViewController:(UIViewController *)viewController 
                                                    animated:(BOOL)animated
{
    // no need for anything?
}

- (void) applicationWillTerminate
{
    // Call save for favorites
    [[WFFavoriteModel SharedFavoriteArray] saveFavorites];
    WFSearchViewController *srcPtr = [pointerList objectForKey:[NSNumber numberWithInt:searchViewCtrl]];
    if (srcPtr)
        [srcPtr saveWords];
}

/* Converts distance to target to suitable string according
 * to location accuracy etc.
 */
- (NSString *)distanceToString:(NSNumber *)distance
{
    NSString *result;
    NSLocale *userLocale = [NSLocale currentLocale];
    float kmMult = 1; // Use 1 for metric system
    float meterMult = 1; // Use 1 for metric system
    float showAsKmFromMult = 1; // Under km show as meters
    //double accuracy = 0;
    NSString *kmAbbr = [NSString stringWithString:@"km"];
    NSString *mAbbr = [NSString stringWithString:@"m"];
    
    /* If the distance is unknown (indicated by it being FLT_MAX), return
     * string "Unknown" as the distance value */
    if ([distance floatValue] == FLT_MAX)
        return NSLocalizedString(@"Unknown", @"");
    
    // Check which measurement system to use
    if (NO == [[userLocale objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        kmMult = 1.609344;
        meterMult = 0.30480;
        showAsKmFromMult = 0.1; // Under 0.1 mi show as feet
        kmAbbr = [NSString stringWithString:@"mi"];
        mAbbr = [NSString stringWithString:@"ft"];
    }
    
    if ([distance unsignedIntValue] > (1000 * kmMult * showAsKmFromMult)) {
        result = [NSString stringWithFormat:@"%5.1f %@", ([distance floatValue] / (1000 * kmMult)), kmAbbr];
    }
    else
        result = [NSString stringWithFormat:@"%5.0f %@", [distance floatValue] / meterMult, mAbbr];
    
    return result;
}

- (id) mutableCopyWithZone:(NSZone *)zone
{
	return self;
}

- (id) copyWithZone:(NSZone *)zone 
{
	return self;
}


- (id)retain
{
    return self;
}


- (unsigned)retainCount
{
    return UINT_MAX;  
}


- (void)release
{
}


- (id)autorelease
{
    return self;
}

@end
