/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocation.h>
#import "WFLocationManager.h"
#import "WFXMLService.h"

@class WFMapLibWrapper;
@class MapResultItem;
@class WFVectorMapView;
@class WFXMLService;
@class WFResultsModel;
@class WFVectorMapViewController;

@interface WFVectorMapView : UIView <CLLocationManagerDelegate, WFXMLServiceDelegate>
{
@private
    /* MapLib */
    WFMapLibWrapper *mapLibPtr;

    BOOL drawing;
    BOOL moving;

    CGLayerRef drawingLayer;
    CGLayerRef resultsLayer;
    CGLayerRef headerLayer;
    CGLayerRef gpsLayer;

    MapResultItem *headerAtItem;
    BOOL headerVisible;
    NSMutableArray *resultsArray;
    UIImage *resultIcon;
    //UIImageView *infoHeaderImage;
    UIImage *infoBubbleImage;
    CLLocationCoordinate2D currentCenter;
    double currentScale;
    CLLocationAccuracy locationAccuracy;
    CLLocationAccuracy prevLocationAccuracy;
    BOOL fetchNewResults;
    BOOL displayGPSIcon;
    BOOL shouldCenterUserLocation;
    BOOL shouldStopLocUpdate;
    WFLocationManager *myLocManager;
    CGPoint doubleTappedPoint;

    UIApplication *application;

    CLLocationCoordinate2D newUserLocation;
    CLLocationCoordinate2D oldUserLocation;
    BOOL doubleTapZooming;

    UIView *gpsView;
    UIImageView *gpsImageView;
    UIImageView *gpsIconView;
    CGImageRef myImage;    
    CGFloat zoomScale;
    NSTimeInterval timeOfLastTouch;
    CGFloat lastTouchDistance;
    int touchCount;
    BOOL routeZooming;
    
    WFXMLService *xmlService;
    NSString *usedRouteId;
    
    id resultModel;
    WFVectorMapViewController *mapCtrl;
    
#ifdef PREMIUM_VERSION
    UIView *infoPanel;
    UILabel *speedLabel;
    UISegmentedControl *rerouteButton;
    BOOL isPanelOpen;
    NSTimer *showRouteTimer;
    UIImageView *routeIcon;
    UILabel *distanceLabel;
    NSDictionary *routeTarget;
    routingType usedRouteType;
    BOOL startedRouting;
    BOOL selfZoomed;
    float speedMultiplier;
    NSString *speedAbbr;
#endif
    CLLocationCoordinate2D routeTargetCoord;
}

@property (nonatomic) CLLocationCoordinate2D mapCenter;
@property (nonatomic) double mapScale;
@property (nonatomic,assign) WFMapLibWrapper *mapLibPtr;
@property (nonatomic) BOOL shouldStopLocUpdate;
@property (nonatomic) BOOL shouldCenterUserLocation;
@property (nonatomic,assign) id resultModel;
@property (nonatomic,assign) WFVectorMapViewController *mapCtrl;
#ifdef PREMIUM_VERSION
@property (nonatomic) BOOL startedRouting;
@property (nonatomic,assign) NSDictionary *routeTarget;
#endif

- (void)zoomToNearestResults;
- (void)viewResults:(NSArray *)results;
- (void)clearResultsOnMap;
- (void)showVisibleItemsOnMap;
- (void)showItemOnMap:(NSDictionary *)item;
- (void)showRouteTo:(NSDictionary *)item routeType:(routingType)routeType;
- (void)displayGPSIconOnMap;
- (void)drawUnCertainityCircleWithGradiant:(CGRect)circleBounds withContext:(CGContextRef)context;
- (void)showCurrentLocationOnMap;
- (void)showMoreResults;

- (void)animateGPSLocationTo:(CGPoint)newPt withBounds:(CGRect)bounds;
@end
