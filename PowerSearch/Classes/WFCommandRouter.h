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
//  This class is used to send commands from one view to other. It
//  knows the pointers to pretty much everywhere. It also acts as
//  delegate for tab bar controller (maybe not the best place but
//  the easiest ;)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "WFAboutViewController.h"
#import "constants.h"

@class WFResultsModel;
@class WFVectorMapView;

@interface WFCommandRouter : NSObject <UITabBarControllerDelegate,
                                        ABUnknownPersonViewControllerDelegate,
                                        UINavigationControllerDelegate>
{
    NSMutableDictionary *pointerList; // Contains the used pointers
    WFResultsModel *categoryResults;
    WFResultsModel *textResults;
    WFVectorMapView *mapView;
    WFAboutViewController *aboutViewCtrl;
    
    BOOL animating;
}

+ (WFCommandRouter *)SharedCommandRouter;

- (void) setPointer:(id)ptr forId:(pointerId)ptrId;

- (WFResultsModel *) getResultModelForType:(searchType)type;

- (void) showItemOnMap:(NSDictionary *)item;
- (void) showRouteTo:(NSDictionary *)item routeType:(routingType)routeType;
- (void) clearResultsOnMap;
- (void) zoomMapToNearestResults;
- (void) showMoreResultsOnMap;
- (void) showVisibleItemsOnMap;

- (void) didReceiveInitialLocation;
- (void) didStartFollowingLocation;
- (void) didStopFollowingLocation;
- (void) didFinishUpdatingLocation;
- (void) setControlsActive:(BOOL)active;

- (void) addAboutButtonTo:(UINavigationItem *)navItem;
- (void) showAboutView:(id) sender;
- (void) closeAboutView;
- (void) openAddressBookWithData:(NSDictionary *) itemInfo forNavController:(id) controller;
// animation callback
- (void) animationComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

- (void) applicationWillTerminate;

// Other common routines
- (NSString *)distanceToString:(NSNumber *)distance;

@end
