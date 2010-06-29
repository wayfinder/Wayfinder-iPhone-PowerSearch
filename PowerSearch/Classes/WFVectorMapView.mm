/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WFVectorMapView.h"
#import "WFCommandRouter.h"
#import "WFVectorMapViewController.h"
//#import "WFSearchBarViewController.h"
//#import "WFSearchController.h"
#import "WFLocationManager.h"
#import "WFImageLoader.h"
#import "WFAppStateStore.h"
#import "WFResultsModel.h"

#import "TileMapHandler.h"
#import "IPhoneMapRenderer.h"
#import "IPhoneMapLib.h"
#import "IPhoneDBufRequestListener.h"
#import "BitBuffer.h"
#import "IPhoneSharedHttpDBufRequester.h"
#import "IPhoneHttpClientConnection.h"
#import "IPhoneHttpClientListener.h"
#import "IPhoneTCPConnectionHandler.h"
#import "IPhoneTileMapToolkit.h"
#import "constants.h"
#import "RouteID.h" 

#define BG_R (51.0 / 255)
#define BG_G (51.0 / 255)
#define BG_B (51.0 / 255)
#define BG_OPACITY 1.0

#define OFFSET 40
#define RADIUS 4
#define HEADER_IMAGE_OFFSET_TO_CENTER 22
#define HEADER_IMAGE_SHADOW_HEIGHT 8
#define HEADER_IMAGE_RIGHT_OFFSET 35 // Pixels from "arrow" to right edge
#define HEADER_TEXT_OFFSET 10
#define TRIANGLE_OFFSET_FROM_CENTER 15
#define HEADERFONTSIZE 16.0
#define HEADERFILL_R 0.275
#define HEADERFILL_G 0.275
#define HEADERFILL_B 0.275
#define HEADER_OPACITY 1.0
#define TEXTFONT_R 1.0
#define TEXTFONT_G 1.0
#define TEXTFONT_B 1.0
#define SHADOWFONT_R 0.0
#define SHADOWFONT_B 0.0
#define SHADOWFONT_G 0.0
#define DISCLOSURE_BTN_OFFSET 200
#define GRADIANT_OPACITY 0.5
#define HEADER_UPPER_FILL_COLOR (50.0 / 255.0)
#define HEADER_LOWER_FILL_COLOR (185 / 255.0)
#define HEADER_LOWER_GRADIENT_FILL_COLOR (75 / 255.0)

#define ZOOM_RATIO 3.0
#define TRANSLATE_RATIO 0.22
#define DEFAULT_METERS_PER_PIXEL 2
#define MAX_METERS_PER_PIXEL 10

#define ROUTE_MOVE_DOWN_PIXELS 90

CGPoint panelOpenPos = CGPointMake(160, 25);
CGPoint panelClosePos = CGPointMake(160, -26);

/* Address and port of the WF map server */
#ifdef USEHEADSERVER
#define SERVER_ADDRESS "http://oss-xml.services.wayfinder.com"
#define SERVER_PORT 80
#else
#define SERVER_ADDRESS "http://oss-xml.services.wayfinder.com"
#define SERVER_PORT 80
#endif

/* How much border to add around the results when calculating the bounding box
 * for the first five results */
#define RESULT_BOUNDS_RATIO 0.15
#define RESULT_BOUNDS_RATIO_ROUTING 0.25
#define SHOWONMAP_ZOOM_SCALE 0.9

/* Set memory cache size to 5 and disk cache size to 50 megabytes */
#define MAPLIB_MEM_CACHE_SIZE (5 * (1 << 20))
#define MAPLIB_DISK_CACHE_SIZE (50 * (1 << 20))

static CGImageRef createGradientImage (int pixelsWide, int pixelsHigh, CGPoint origin);

/* iPhone specific MapLib.  */
class PowerSearchMapLib : public IPhoneMapLib 
{
public:
   /**
    *   Constructor
    *   @param mapConn DBufConnection to get the tiles from
    *   @param control Control to draw the map in.
    *   @param fs      File server session.
    */
    PowerSearchMapLib(IPhoneSharedHttpDBufRequester *mapReq, int width, int
                      height) :
        IPhoneMapLib(mapReq, width, height) {}

   /**
    *   Returns the mapplotter.
    */
    isab::IPhoneMapRenderer* getIPhoneMapPlotter() { return m_mapPlotter; }
};


/* A helper class for updating the map view when MapLib has finished drawing */
class MyUpdater : public isab::ReadyForUpdate
{
public:
	MyUpdater(id parent)
	{
		parentClass = parent;
        showStartUp = YES;
	}
	
	void callUpdate();

private:
    BOOL showStartUp;
	id parentClass;
};

// A wrapper class for hiding C++ stuff from header
@interface WFMapLibWrapper : NSObject {
@public
    PowerSearchMapLib *mapLib;
    MapMovingInterface *mapHandler;
    MapDrawingInterface *mapViewHandler;
    MyUpdater *myUpdater;
    IPhoneHttpClientConnection *connection;
}
@end

@implementation WFMapLibWrapper

@end


/* A helper class for storing the current results in a bit more effective
 * format */
@interface MapResultItem : NSObject {
@public
    int32 lat;
    int32 lon;
    CGRect bounds;
    CGRect header;
@private
    NSDictionary *item;
}
@property (nonatomic,retain) NSDictionary *item;

+ (MapResultItem *)item;
@end

@implementation MapResultItem
@synthesize item;

+ (MapResultItem *)item
{
    return [[[MapResultItem alloc] init] autorelease];
}
@end


/* Implementation of WFVectorMapView start here */
@interface WFVectorMapView()
- (void)createMapLib;
- (void)terminationCallback:(id)sender;
- (void)drawHeaderWithObject:(MapResultItem *)item;
- (void)getResults;
- (UILabel *)newLabelWithFontSize:(CGFloat)fontSize bold:(BOOL)bold;
#ifdef PREMIUM_VERSION
- (void)reroutePressed:(id)sender;
- (void)setInfoPanelOpen:(BOOL)panelOpen animate:(BOOL)animate;
- (void)showRouteTimerFired:(NSTimer *) timer;
#endif
@end

@implementation WFVectorMapView

@dynamic mapCenter, mapScale, shouldStopLocUpdate, shouldCenterUserLocation, resultModel;
#ifdef PREMIUM_VERSION
@dynamic startedRouting, routeTarget;
#endif
@synthesize mapLibPtr, mapCtrl;


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.multipleTouchEnabled = YES;
        mapLibPtr = [[WFMapLibWrapper alloc] init];
        resultsArray = [[NSMutableArray alloc] init];
        resultIcon = [[UIImage
            imageNamed:@"search-item-number-icon-for-map.png"] retain];
        infoBubbleImage = [UIImage imageNamed:@"info_pop_up.png"];
        
        NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
        [nCenter addObserver:self selector:@selector(terminationCallback:)
                        name:UIApplicationWillTerminateNotification
                      object:nil];
        fetchNewResults = YES;
        headerVisible = NO;
        shouldCenterUserLocation = YES;
        touchCount = 0;
        routeZooming = NO;
        /* At startup, find location within 100m. If user presses locate button,
         * keep updating location until button is pressed again. */
        shouldStopLocUpdate = YES;
        myLocManager = [WFLocationManager sharedManager];
        [myLocManager addDelegate:self];
        [myLocManager startUpdatingLocation];
        
        application = [UIApplication sharedApplication];
        
        gpsView = [[UIView alloc] initWithFrame:CGRectZero];
        UIImage *gpsImage = [UIImage imageNamed:@"gps-position-icon.png"];
        gpsIconView = [[UIImageView alloc] initWithImage:gpsImage];
        gpsImageView = [[UIImageView alloc] initWithImage:nil];
        
        [gpsView addSubview:gpsImageView];
        [gpsView addSubview:gpsIconView];
        
        [gpsIconView release];
        [gpsImageView release];
        [self addSubview:gpsView];
        [self bringSubviewToFront:gpsView];
        
        gpsView.hidden = YES;
        gpsView.center = self.center;
        oldUserLocation.latitude = 0.0;
        oldUserLocation.longitude = 0.0;
        
        xmlService = [[WFXMLService alloc] init];
        xmlService.delegate = self;
        
        resultModel = [[WFCommandRouter SharedCommandRouter] getResultModelForType:textSearchType];

#ifdef PREMIUM_VERSION
        // Create info panel
        isPanelOpen = NO;
        infoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        infoPanel.multipleTouchEnabled = YES;
        UIImageView *panelBgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map-info-panel.png"]];
        panelBgImage.opaque = NO;
        panelBgImage.alpha = 0.8;
        
        [infoPanel addSubview:panelBgImage];
        [panelBgImage release];
        infoPanel.center = CGPointMake(160, -26);
        
        startedRouting = NO;
        selfZoomed = NO;
        NSLocale *userLocale = [NSLocale currentLocale];
        if (NO == [[userLocale objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
            // Use imperial
            speedMultiplier = 2.23693629;
            speedAbbr = @"mph";
        }
        else {
            // Use metric
            speedMultiplier = 3.6;
            speedAbbr = @"km/h";
        }
        
        routeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"car_icon.png"]];
        routeIcon.frame = CGRectMake(4, (int)(infoPanel.frame.size.height / 2 - routeIcon.image.size.height / 2),
                                     routeIcon.image.size.width, routeIcon.image.size.height);
        routeIcon.opaque = NO;
        routeIcon.alpha = 0.9;
        
        distanceLabel = [self newLabelWithFontSize:20 bold:YES];
        distanceLabel.frame = CGRectMake(42, 12, 90, 25);
        distanceLabel.adjustsFontSizeToFitWidth = YES;
        distanceLabel.minimumFontSize = 14;
        distanceLabel.text = @"-";
        speedLabel = [self newLabelWithFontSize:20 bold:YES];
        speedLabel.frame = CGRectMake(135, 12, 90, 25);
        speedLabel.adjustsFontSizeToFitWidth = YES;
        speedLabel.minimumFontSize = 14;
        speedLabel.text = [NSString stringWithFormat:@"0 %@", speedAbbr];
        
        rerouteButton = [[UISegmentedControl alloc]
                         initWithItems:[NSArray arrayWithObject:[NSString stringWithString:NSLocalizedString(@"Start", nil)]]];
        rerouteButton.tintColor = [UIColor grayColor];
        rerouteButton.momentary = YES;
        rerouteButton.segmentedControlStyle = UISegmentedControlStyleBar;
        rerouteButton.frame = CGRectMake(230, 10, 85, 30);
        [rerouteButton addTarget:self
                          action:@selector(reroutePressed:)
                forControlEvents:UIControlEventValueChanged];
        
        [infoPanel addSubview:routeIcon];
        [infoPanel addSubview:distanceLabel];
        [infoPanel addSubview:speedLabel];
        [infoPanel addSubview:rerouteButton];
        [self addSubview:infoPanel];
        [self bringSubviewToFront:infoPanel];
//#endif

        CLLocation *center = [[WFAppStateStore sharedStateStore]
            objectForKey:@"WFVectorMapView:currentCenter"];
        if (center) {
            [self getResults];

            currentScale = [[[WFAppStateStore sharedStateStore]
                objectForKey:@"WFVectorMapView:currentScale"] doubleValue];
            self.mapCenter = currentCenter = center.coordinate;
            locationAccuracy = center.horizontalAccuracy;
            self.mapScale = currentScale;

            newUserLocation = myLocManager.currentLocation.coordinate;

            timeOfLastTouch = 0.0;
        }
        
        NSDictionary *savedRoute = [[WFAppStateStore sharedStateStore]
                                    objectForKey:@"WFVectorMapView:route"];
        if (savedRoute && ![savedRoute isEqual:@""]) {
            routeTargetCoord.latitude = [[savedRoute objectForKey:@"routeLat"] doubleValue];
            routeTargetCoord.longitude = [[savedRoute objectForKey:@"routeLon"] doubleValue];
            
            [xmlService routeRequestFrom:newUserLocation to:routeTargetCoord
                               routeType:(routingType)[[savedRoute objectForKey:@"routeType"] intValue]
                              oldRouteId:nil];
            [self setInfoPanelOpen:YES animate:YES];
        }
        
        routeTarget = [[WFAppStateStore sharedStateStore]
                       objectForKey:@"WFVectorMapView:routeTarget"];
        if ([routeTarget count] > 0) {
            MapResultItem *it = [MapResultItem item];
             it->lat = [[routeTarget valueForKey:@"lat"] intValue];
             it->lon = [[routeTarget valueForKey:@"lon"] intValue];
             it.item = routeTarget;
            
            [resultsArray addObject:it];
            
            fetchNewResults = NO;
            
            // Also push this to result model so details can be fetched
            [resultModel addResult:routeTarget];
        }
        else
            routeTarget = nil;
        
        NSNumber *centerOnUser = [[WFAppStateStore sharedStateStore]
                                  objectForKey:@"WFVectorMapView:shouldCenterUserLocation"];
        
        if (centerOnUser) {
            shouldCenterUserLocation = [centerOnUser boolValue];
        }
        
        NSNumber *stopLoc = [[WFAppStateStore sharedStateStore]
                             objectForKey:@"WFVectorMapView:shouldStopLocUpdate"];
        
        if (stopLoc) {
            shouldStopLocUpdate = [stopLoc boolValue];
        }
        
        NSNumber *routing = [[WFAppStateStore sharedStateStore]
                             objectForKey:@"WFVectorMapView:startedRouting"];
        
        if (routing) {
            startedRouting = [routing boolValue];
            if (startedRouting) {
                speedLabel.text = [NSString stringWithFormat:@"0 %@", speedAbbr];
                [self showCurrentLocationOnMap];
                [[WFCommandRouter SharedCommandRouter] didStartFollowingLocation];
                [rerouteButton setTitle:NSLocalizedString(@"Reroute", nil) forSegmentAtIndex:0];
            }
        }
        
#endif
        
        // Report our pointer to command router
        [[WFCommandRouter SharedCommandRouter] setPointer:self forId:mapViewPtr];
    }
    return self;
}


- (void)reroutePressed:(id)sender
{
#ifdef PREMIUM_VERSION
    if (routeTarget != nil) {
        if (startedRouting) {
            if (showRouteTimer && [showRouteTimer isValid]) {
                [showRouteTimer invalidate];
                [showRouteTimer release];
                showRouteTimer = nil;
            }
            // Routing is ongoing. Button is for rerouting
            [self showRouteTo:routeTarget routeType:usedRouteType];
            // Show the total route for a few seconds and return to routing
            showRouteTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0
                                                               target:self
                                                             selector:@selector(showRouteTimerFired:)
                                                             userInfo:nil
                                                              repeats:NO] retain];
        }
        else {
            // Start routing
            self.startedRouting = YES;
            speedLabel.text = [NSString stringWithFormat:@"0 %@", speedAbbr];
            [self showCurrentLocationOnMap];
            [[WFCommandRouter SharedCommandRouter] didStartFollowingLocation];
            [rerouteButton setTitle:NSLocalizedString(@"Reroute", nil) forSegmentAtIndex:0];
        }
    }
#else
    [[UIApplication sharedApplication]
     openURL:[NSURL URLWithString:@"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=300542847&mt=8"]];
#endif
}


- (void)terminationCallback:(id)sender
{
    delete mapLibPtr->mapLib;
    mapLibPtr->mapLib = nil;
}


- (void)dealloc
{
    if (mapLibPtr->mapLib)
        delete mapLibPtr->mapLib;
    if (mapLibPtr->myUpdater)
        delete mapLibPtr->myUpdater;

    CGLayerRelease(drawingLayer);
    CGLayerRelease(resultsLayer);
    CGLayerRelease(headerLayer);
    CGLayerRelease(gpsLayer);

    [resultsArray release];
    [resultIcon release];
    [mapLibPtr release];
    
    [gpsView release];
    [xmlService release];
    [super dealloc];
}

- (void)createMapLib
{
    if (!mapLibPtr->mapLib) {
        mapLibPtr->connection = new
        IPhoneHttpClientConnection(SERVER_ADDRESS, SERVER_PORT,
                                   new IPhoneHttpClientListener(),
                                   new IPhoneTCPConnectionHandler());
        NSString *urlParam = [NSString stringWithFormat:@"?uin=%@&c=%@",
                              STR_XMLUIN, STR_CLIENTTYPE];
        IPhoneSharedHttpDBufRequester *req = new
        IPhoneSharedHttpDBufRequester(mapLibPtr->connection, "/TMap", [urlParam UTF8String]);
        mapLibPtr->mapLib = new PowerSearchMapLib(req, self.bounds.size.width,
                                                  self.bounds.size.height);
        
        /* Copyright string */
        MC2Point copyrightPosition(5, self.bounds.size.height - 5);
        mapLibPtr->mapLib->setCopyrightPos(copyrightPosition);
        mapLibPtr->mapLib->showCopyright(true);
        
        mapLibPtr->myUpdater = new MyUpdater(self);
        mapLibPtr->mapLib->getIPhoneMapPlotter()->setCallBack(mapLibPtr->myUpdater);
        
        mapLibPtr->mapHandler = mapLibPtr->mapLib->getMapMovingInterface();
        mapLibPtr->mapViewHandler = mapLibPtr->mapLib->getMapDrawingInterface();
        
        mapLibPtr->mapLib->setMemoryCacheSize(MAPLIB_MEM_CACHE_SIZE);
        
        NSArray *cacheDirs =
        NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                            NSUserDomainMask,
                                            YES);
        NSString *mapCachePath = [[cacheDirs objectAtIndex:0]
                                  stringByAppendingPathComponent:@"PowerSearch"];
        
        mapLibPtr->mapLib->addDiskCache([mapCachePath UTF8String],
                                        MAPLIB_DISK_CACHE_SIZE);
        mapLibPtr->mapLib->setDiskCacheSize(MAPLIB_DISK_CACHE_SIZE);
    }
}

- (void)repaint
{
    if (!mapLibPtr->mapViewHandler)
        [self createMapLib];
    mapLibPtr->mapViewHandler->requestRepaint();
}


- (void)drawRect:(CGRect)rect
{
    if (!mapLibPtr->mapLib) {
        UIImage *backgroundImage = [UIImage
            imageNamed:@"background-overlay.png"];

        // Stupid drawAsPatternInRect draws images upside down 
        self.transform = CGAffineTransformScale(self.transform, 1.0, -1.0);
        [backgroundImage drawAsPatternInRect:self.bounds];
        self.transform = CGAffineTransformIdentity;

        return;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    if (!drawingLayer) {
        drawingLayer = CGLayerCreateWithContext(ctx, self.bounds.size, NULL);
        resultsLayer = CGLayerCreateWithContext(ctx, self.bounds.size, NULL);
        headerLayer = CGLayerCreateWithContext(ctx, self.bounds.size, NULL);
        gpsLayer = CGLayerCreateWithContext(ctx, self.bounds.size, NULL);
        mapLibPtr->mapLib->getIPhoneMapPlotter()->setContext(CGLayerGetContext(drawingLayer),
                                                  self.bounds.size.width,
                                                  self.bounds.size.height);
    }
    if (CGPointEqualToPoint(doubleTappedPoint , CGPointZero)) {        
        if (doubleTapZooming){
            MC2Point pt(0, 0);
            WGS84Coordinate wgs84coord(oldUserLocation.latitude, oldUserLocation.longitude);
            mapLibPtr->mapHandler->transform(pt, MC2Coordinate(wgs84coord));
            gpsView.center = CGPointMake(pt.getX(), pt.getY()); 
            doubleTapZooming = NO;
        }
        self.transform = CGAffineTransformIdentity;
    }
    CGContextDrawLayerAtPoint(ctx, CGPointZero, drawingLayer);
    [self displayGPSIconOnMap];
    CGContextDrawLayerAtPoint(ctx, CGPointZero, gpsLayer);
    
    if (moving){
        MC2Point pt(0, 0);
        WGS84Coordinate wgs84coord(oldUserLocation.latitude, oldUserLocation.longitude);
        mapLibPtr->mapHandler->transform(pt, MC2Coordinate(wgs84coord));
        gpsView.center = CGPointMake(pt.getX(), pt.getY());
    }
    
    if ([resultsArray count] > 0) {
        [self showVisibleItemsOnMap];
        CGContextDrawLayerAtPoint(ctx, CGPointZero, resultsLayer);
    }
    if (headerAtItem) {
        CGPoint pt = CGPointMake(headerAtItem->bounds.origin.x + (resultIcon.size.width / 2), 
                                 headerAtItem->bounds.origin.y + (resultIcon.size.height / 2) );
        if(CGRectContainsPoint(self.bounds, pt)) {
            headerVisible = YES;
            [self drawHeaderWithObject:headerAtItem];
        }
        else {
            headerVisible = NO;
            CGContextClearRect(CGLayerGetContext(headerLayer), self.bounds);
        }
        CGContextDrawLayerAtPoint(ctx, CGPointZero, headerLayer);
    }
    
    if (mapLibPtr->connection->getNbrSent()) {
        if( [application isNetworkActivityIndicatorVisible] == NO) {  
            [application setNetworkActivityIndicatorVisible:YES]; 
        }
    }
    else {
        if( [application isNetworkActivityIndicatorVisible] == YES) {  
            [application setNetworkActivityIndicatorVisible:NO]; 
        }
    }

    CLLocationCoordinate2D newCenter = self.mapCenter;
    if (currentCenter.latitude != newCenter.latitude ||
        currentCenter.longitude != newCenter.longitude) {
        currentCenter = newCenter;
        CLLocation *loc = [[CLLocation alloc]
            initWithCoordinate:newCenter altitude:0.0
            horizontalAccuracy:locationAccuracy verticalAccuracy:0.0
                     timestamp:[NSDate date]];
        [[WFAppStateStore sharedStateStore]
            setObject:loc forKey:@"WFVectorMapView:currentCenter"];
        [loc release];
    }
    if (currentScale != self.mapScale) {
        currentScale = self.mapScale;
        [[WFAppStateStore sharedStateStore]
            setObject:[NSNumber numberWithDouble:currentScale]
            forKey:@"WFVectorMapView:currentScale"];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    if ([[touches anyObject] phase] == UITouchPhaseBegan) {
        if (timeOfLastTouch == 0.0) 
            timeOfLastTouch = [(UITouch *)[touches anyObject] timestamp];
        
        touchCount = touchCount + [touches count];
        if (touchCount > 1 && shouldCenterUserLocation) {
            routeZooming = YES;
#ifdef PREMIUM_VERSION
            selfZoomed = YES;
#endif
        }
    }

    displayGPSIcon = NO;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    if (routeZooming)
        if ([touches count] < 2)
            return;
    mapLibPtr->mapHandler->setMovementMode(true);
    moving = YES;
    
    if ([touches count] == 1) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint loc = [touch locationInView:self];
        CGPoint prevLoc = [touch previousLocationInView:self];
        
        mapLibPtr->mapHandler->move(prevLoc.x - loc.x, prevLoc.y - loc.y);
        
        self.shouldCenterUserLocation = NO;
    }
    else if ([touches count] == 2) {
        /* Only process two-finger events if the previous event was also
         * two-fingered */
        UITouch *t1 = [[touches allObjects] objectAtIndex:0];
        UITouch *t2 = [[touches allObjects] objectAtIndex:1];
        
        CGPoint loc1 = [t1 locationInView:self];
        CGPoint loc2 = [t2 locationInView:self];
        CGPoint prevLoc1 = [t1 previousLocationInView:self];
        CGPoint prevLoc2 = [t2 previousLocationInView:self];        
        
        /* Zoom center */
        CGPoint center = CGPointMake((loc1.x + loc2.x) / 2, (loc1.y + loc2.y) / 2);
        CGPoint prevCenter = CGPointMake((prevLoc1.x + prevLoc2.x) / 2,
                                         (prevLoc1.y + prevLoc2.y) / 2);
        
        /* Zoom amount */
        CGFloat lastDist = hypot(prevLoc1.x - prevLoc2.x,
                                 prevLoc1.y - prevLoc2.y);
        CGFloat dist = hypot(loc1.x - loc2.x, loc1.y - loc2.y);
        
        lastTouchDistance += fabs(lastDist - dist);
        if (!routeZooming)
            mapLibPtr->mapHandler->move(prevCenter.x - center.x, prevCenter.y - center.y);
        
        MC2Coordinate mc2centerCoord;
        MC2Point mc2centerPt(center.x, center.y);
        mapLibPtr->mapHandler->inverseTransform(mc2centerCoord, mc2centerPt);
        mapLibPtr->mapHandler->zoom(lastDist / dist, mc2centerCoord, mc2centerPt);
    }
    
    [self repaint];
}


- (CGRect) adjustHeaderToFitView:(CGPoint)location withHeaderFrame:(CGRect)frame
{
    CGRect viewFrame = [self frame];
    bool containsRect = CGRectContainsRect(viewFrame, frame);
    
    if(!containsRect)
    {
        int HeaderWidth = frame.origin.x + frame.size.width;
        int HeaderHeight = frame.origin.y  + frame.size.height;
        int ViewWidth = viewFrame.size.width ;
        int ViewHeight = viewFrame.size.height;
        int offset = 0;
        
        if(HeaderWidth > ViewWidth)
        {
            offset = ( HeaderWidth - ViewWidth) ;
            frame.origin.x = frame.origin.x - (offset + 10);            
        }
        else if(HeaderWidth < frame.size.width)
        {
            offset = ( frame.size.width - HeaderWidth  ) ;
            frame.origin.x = frame.origin.x + (offset + 10);            
        }        
        
        if(HeaderHeight < frame.size.height)
        {
            frame.origin.y = location.y + 30;
        }
        else if(HeaderHeight > ViewHeight)
        {
            frame.origin.y = location.y - 30;
        }        
        return frame;
    }            
    return frame;
}


- (void) drawHeaderWithObject:(MapResultItem *)item
{
    NSDictionary *obj = item.item;
    CGPoint pt = {
        item->bounds.origin.x + item->bounds.size.width / 2,
        item->bounds.origin.y + item->bounds.size.height / 2
    };
    
    pt.y = pt.y - OFFSET;
    CGRect rrect = CGRectMake((pt.x - (infoBubbleImage.size.width/2)),
                              (pt.y - (infoBubbleImage.size.height/2)),
                              infoBubbleImage.size.width, infoBubbleImage.size.height);
    
    rrect = [self adjustHeaderToFitView:item->bounds.origin withHeaderFrame:rrect];
    
    rrect.origin.x = (int)rrect.origin.x;
    rrect.origin.y = (int)rrect.origin.y;
    
    UIGraphicsPushContext(CGLayerGetContext(headerLayer));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    
    [infoBubbleImage drawAtPoint:CGPointMake(rrect.origin.x , rrect.origin.y )];
    
    CGPoint startPt,endPt,midPt = CGPointMake(0,0);
    CGGradientRef gradient;
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    if(rrect.origin.y < item->bounds.origin.y)
    {
        startPt = CGPointMake(pt.x - TRIANGLE_OFFSET_FROM_CENTER , pt.y + (rrect.size.height/2) - 10);
        endPt = CGPointMake(pt.x + TRIANGLE_OFFSET_FROM_CENTER, pt.y + (rrect.size.height/2) - 10);
        midPt = CGPointMake(pt.x, item->bounds.origin.y + 3);
        CGContextSetRGBFillColor(context, HEADER_UPPER_FILL_COLOR, HEADER_UPPER_FILL_COLOR, 
                                 HEADER_UPPER_FILL_COLOR, HEADER_OPACITY);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, HEADER_OPACITY);        
        
        CGFloat colors[] =
        {            
            HEADER_UPPER_FILL_COLOR, HEADER_UPPER_FILL_COLOR, HEADER_UPPER_FILL_COLOR, GRADIANT_OPACITY,
            0 , 0 , 0, GRADIANT_OPACITY,              
        };
        
        gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 
                                                       sizeof(colors)/(sizeof(colors[0])*4));        
    }
    else
    {
        pt.y = item->bounds.origin.y + OFFSET - 10;
        
        startPt = CGPointMake(pt.x - TRIANGLE_OFFSET_FROM_CENTER , pt.y  + 1   );
        endPt = CGPointMake(pt.x + TRIANGLE_OFFSET_FROM_CENTER, pt.y  + 1  );
        midPt = CGPointMake(pt.x , item->bounds.origin.y + 20 );
        CGContextSetRGBFillColor(context, HEADER_LOWER_FILL_COLOR, HEADER_LOWER_FILL_COLOR, 
                                 HEADER_LOWER_FILL_COLOR, HEADER_OPACITY);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, GRADIANT_OPACITY);
        
        CGFloat colors[] =
        {            
            HEADER_LOWER_FILL_COLOR, HEADER_LOWER_FILL_COLOR, HEADER_LOWER_FILL_COLOR, GRADIANT_OPACITY,
            HEADER_LOWER_GRADIENT_FILL_COLOR, HEADER_LOWER_GRADIENT_FILL_COLOR, HEADER_LOWER_GRADIENT_FILL_COLOR, GRADIANT_OPACITY,             
        };
        gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 
                                                       sizeof(colors)/(sizeof(colors[0])*4));
       
    }    
     CGColorSpaceRelease(rgb);
    
    if(startPt.x < (rrect.origin.x + 3))
        startPt.x = (rrect.origin.x + 3);
    
    if(endPt.x > (rrect.origin.x + rrect.size.width - 3))
        endPt.x = (rrect.origin.x + rrect.size.width - 3);
    CGPoint points[3] =
    {
        startPt,
        midPt,
        endPt,
    };
    
    CGContextMoveToPoint(context, points[0].x, points[0].y);
	CGContextAddLines(context, points, sizeof(points)/sizeof(points[0]));
    CGContextDrawPath(context, kCGPathFillStroke);       
    
    CGContextMoveToPoint(context, points[0].x, points[0].y);
	CGContextAddLines(context, points, sizeof(points)/sizeof(points[0]));   
    CGContextSaveGState(context);
    CGContextClip(context);    
    CGContextDrawLinearGradient(context, gradient, midPt, CGPointMake((startPt.x + endPt.x) / 2, startPt.y), 
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGContextRestoreGState(context);    
    CGGradientRelease(gradient);
    
    CGRect textRect =  CGRectMake(rrect.origin.x + HEADER_TEXT_OFFSET,
                                   (int)(rrect.origin.y + (rrect.size.height - HEADER_IMAGE_SHADOW_HEIGHT) / 2 - HEADERFONTSIZE / 2),
                                   (infoBubbleImage.size.width - HEADER_TEXT_OFFSET - HEADER_IMAGE_RIGHT_OFFSET), 25);
    
    // The insect for the text, shadow if you will...
    CGRect shadowRect =  CGRectMake(rrect.origin.x + HEADER_TEXT_OFFSET + 1,
                                   (int)(rrect.origin.y + (rrect.size.height - HEADER_IMAGE_SHADOW_HEIGHT) / 2 - HEADERFONTSIZE / 2) + 1,
                                   (infoBubbleImage.size.width - HEADER_TEXT_OFFSET - HEADER_IMAGE_RIGHT_OFFSET), 25);
    
    NSString *str = [obj valueForKey:@"name"];
    
    if([str length] > 0)
        CGContextSetRGBFillColor(context, SHADOWFONT_R, SHADOWFONT_G, SHADOWFONT_B, HEADER_OPACITY);
        [str drawInRect:shadowRect 
               withFont:[UIFont boldSystemFontOfSize:HEADERFONTSIZE]   
          lineBreakMode:UILineBreakModeTailTruncation]; 
        CGContextSetRGBFillColor(context, TEXTFONT_R, TEXTFONT_G, TEXTFONT_B, HEADER_OPACITY);  
        [str drawInRect: textRect
               withFont:[UIFont boldSystemFontOfSize:HEADERFONTSIZE]
                      lineBreakMode:UILineBreakModeTailTruncation];

    item->header = rrect;
    
    UIGraphicsPopContext();
}


- (void) processSingleTapAtPoint:(CGPoint)pt
{    
    if (headerVisible && headerAtItem)
        for(MapResultItem *item in resultsArray)
            if(item == headerAtItem)
                if (CGRectContainsPoint(item->header, pt)) {
                    [mapCtrl showDetailsForItem:item.item];
                    return;
                }

    for (MapResultItem *item in resultsArray)            
        if(CGRectContainsPoint(item->bounds, pt)) {
            headerAtItem = item;
            [self repaint];
            return;
        }
    
    CGContextClearRect(CGLayerGetContext(headerLayer), self.bounds);
    headerAtItem = nil;
    [self repaint];
}


- (void) processDoubleTapAtPoint:(CGPoint)pt mapCenter:(CGPoint)mapMidPoint
{ 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:
     @selector(mapAnimationStopped:finished:context:)];
    
    CGAffineTransform translate =  CGAffineTransformTranslate(self.transform, 
                                                              ((mapMidPoint.x - pt.x) * TRANSLATE_RATIO *zoomScale)  ,  
                                                              ((mapMidPoint.y - pt.y) * TRANSLATE_RATIO *zoomScale) ); 
    
    CGAffineTransform scale = CGAffineTransformScale(self.transform,
                                                     zoomScale,
                                                     zoomScale);
    
    self.transform = CGAffineTransformConcat(translate , scale);
    [UIView commitAnimations];
}


- (void)mapAnimationStopped:(id)animationID
                   finished:(BOOL)done
                    context:(id)context
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    MC2Coordinate mc2centerCoord;
    MC2Point mc2centerPt(doubleTappedPoint.x, doubleTappedPoint.y);
    mapLibPtr->mapHandler->inverseTransform(mc2centerCoord, mc2centerPt);
    if(zoomScale > 1) // zoom in
        mapLibPtr->mapHandler->zoom(1/zoomScale, mc2centerCoord, mc2centerPt);
    else // zoom out
        mapLibPtr->mapHandler->zoom(1/zoomScale);
    doubleTappedPoint = CGPointZero;
    [self repaint];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount = touchCount - [touches count];
    if (touchCount < 0)
        touchCount = 0;
    
    if ([touches count] == [[event touchesForView:self] count])
    {
        touchCount = 0;
        // last finger has lifted....
        if (!mapLibPtr->mapHandler)
            [self createMapLib];
        mapLibPtr->mapHandler->setMovementMode(false);
        moving = FALSE;
        [self repaint];
                
        if([touches count] == 1) {
            if ([[touches anyObject] tapCount] == 1) {
                UITouch *touch = [[event allTouches] anyObject];
                CGPoint pt = [touch locationInView:self];
                [self processSingleTapAtPoint:pt];                
            } 
            else if ([[touches anyObject] tapCount] == 2)
            {
                UITouch *t1 = [[touches allObjects] objectAtIndex:0];            
                CGPoint touchLoc = [t1 locationInView:self];
                CGPoint mapMidPoint = {(self.bounds.origin.x + self.bounds.size.width)/2, 
                (self.bounds.origin.y + self.bounds.size.height)/2 } ;  
                doubleTappedPoint = touchLoc;
                zoomScale = ZOOM_RATIO;
                [self processDoubleTapAtPoint:touchLoc mapCenter:mapMidPoint];            
            }   
        }
        else if ([touches count] == 2)
        {              
            double timeInterval = [(UITouch *)[touches anyObject] timestamp] - timeOfLastTouch ;
            if (timeInterval < 0.4 && lastTouchDistance < 10)
            {
                UITouch *touch1 = [[touches allObjects] objectAtIndex:0];
                UITouch *touch2 = [[touches allObjects] objectAtIndex:1];
            
                CGPoint touchLoc1 = [touch1 locationInView:self];
                CGPoint touchLoc2 = [touch2 locationInView:self];                
                CGPoint touchLoc = CGPointMake((touchLoc1.x + touchLoc2.x)/2 , 
                                                    (touchLoc1.y + touchLoc2.y)/2);
                CGPoint mapMidPoint = {(self.bounds.origin.x + self.bounds.size.width)/2, 
                                            (self.bounds.origin.y + self.bounds.size.height)/2 } ;  
                doubleTappedPoint = touchLoc;
                zoomScale = 1/ZOOM_RATIO;
                [self processDoubleTapAtPoint:touchLoc mapCenter:mapMidPoint];
            }
        }
        timeOfLastTouch = 0.0;
        lastTouchDistance = 0.0;
    }
    if (touchCount < 2 && routeZooming)
        routeZooming = NO;
}


void MyUpdater::callUpdate()
{
    if (showStartUp) {
        [[WFCommandRouter SharedCommandRouter] didReceiveInitialLocation];
        showStartUp = NO;
    }

    [parentClass setNeedsDisplay];
}


- (double)mapScale
{
    if (mapLibPtr->mapHandler)
        return mapLibPtr->mapHandler->getScale();
    else
        return 0;
}


- (void)setMapScale:(double)metersPerPixel
{
    if (mapLibPtr->mapHandler) {
        mapLibPtr->mapHandler->setScale(metersPerPixel);
        [self repaint];
    }
}


- (CLLocationCoordinate2D)mapCenter
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    WGS84Coordinate wgs84coord(mapLibPtr->mapHandler->getCenter());
    CLLocationCoordinate2D center = { wgs84coord.latDeg, wgs84coord.lonDeg };

    return center;
}


- (void)setMapCenter:(CLLocationCoordinate2D)coordinate
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    displayGPSIcon = YES;
    WGS84Coordinate wgs84coord(coordinate.latitude, coordinate.longitude);
#ifdef PREMIUM_VERSION
    if (startedRouting && shouldCenterUserLocation && carRoute == usedRouteType) {
        MC2Point pt(160, 280);
        mapLibPtr->mapHandler->setPoint(MC2Coordinate(wgs84coord), pt);
    }
    else
        mapLibPtr->mapHandler->setCenter(MC2Coordinate(wgs84coord));
#else
    mapLibPtr->mapHandler->setCenter(MC2Coordinate(wgs84coord));
#endif
    [self repaint];
}

- (id)resultModel
{
    return resultModel;
}

- (void)setResultModel:(id)newModel
{
    if (newModel != resultModel) {
        // Show new models results (if any)
        resultModel = newModel;
        [self clearResultsOnMap];
        [self showVisibleItemsOnMap];
        if ([mapCtrl.navigationController topViewController] != (UIViewController *)mapCtrl) {
            [mapCtrl.navigationController popToViewController:(UIViewController *)mapCtrl animated:NO];
        }
    }
}

- (BOOL)shouldStopLocUpdate
{
    return shouldStopLocUpdate;
}

- (void)setShouldStopLocUpdate:(BOOL)stopOrNot
{
    shouldStopLocUpdate = stopOrNot;
    [[WFAppStateStore sharedStateStore]
     setObject:[NSNumber numberWithBool:stopOrNot] forKey:@"WFVectorMapView:shouldStopLocUpdate"];
}

- (BOOL)shouldCenterUserLocation
{
    return shouldCenterUserLocation;
}

- (void)setShouldCenterUserLocation:(BOOL)centerOrNot
{
    if (shouldCenterUserLocation && NO == centerOrNot) {
        // No longer following users location. Notify this
        [[WFCommandRouter SharedCommandRouter] didStopFollowingLocation];
        
#ifdef PREMIUM_VERSION
        if (!mapLibPtr->mapHandler)
            [self createMapLib];
        // Rotate map back to north
        mapLibPtr->mapHandler->setAngle(0);
#endif
    }
    shouldCenterUserLocation = centerOrNot;
    [[WFAppStateStore sharedStateStore]
     setObject:[NSNumber numberWithBool:centerOrNot] forKey:@"WFVectorMapView:shouldCenterUserLocation"];
}

#ifdef PREMIUM_VERSION
- (BOOL)startedRouting
{
    return startedRouting;
}

- (void)setStartedRouting:(BOOL)routingStarted
{
    startedRouting = routingStarted;
    [[WFAppStateStore sharedStateStore]
     setObject:[NSNumber numberWithBool:routingStarted] forKey:@"WFVectorMapView:startedRouting"];
}

- (NSDictionary *)routeTarget
{
    return routeTarget;
}

- (void)setRouteTarget:(NSDictionary *)target
{
    routeTarget = target;
    if (nil == target)
        [[WFAppStateStore sharedStateStore]
         setObject:[NSDictionary dictionary] forKey:@"WFVectorMapView:routeTarget"];
    else
        [[WFAppStateStore sharedStateStore]
         setObject:target forKey:@"WFVectorMapView:routeTarget"];
}
#endif

- (void)getResults
{
    if(fetchNewResults)
    {
        // As results array changes, header item could be invalid.
        // Clear it so we won't crash if this happens.
        headerAtItem = nil;
        [resultsArray removeAllObjects];
        for (NSMutableDictionary *item in [resultModel getResults])
        {
            MapResultItem *it = [MapResultItem item];
            it->lat = [[item valueForKey:@"lat"] intValue];
            it->lon = [[item valueForKey:@"lon"] intValue];
            it.item = item;

            [resultsArray addObject:it];
        }
        fetchNewResults = NO;
    }
}


- (void)clearResultsOnMap
{
    if (!mapLibPtr->mapLib)
        [self createMapLib];
    // Clear old route
    mapLibPtr->mapLib->clearRouteID();
    mapLibPtr->mapLib->setRouteVisibility(false);
    [usedRouteId release];
    usedRouteId = nil;
#ifdef PREMIUM_VERSION
    self.routeTarget = nil;
    distanceLabel.text = @"-";
    [self setInfoPanelOpen:NO animate:YES];
    [rerouteButton setTitle:NSLocalizedString(@"Start", nil) forSegmentAtIndex:0];
    self.startedRouting = NO;
#endif
    [[WFAppStateStore sharedStateStore]
     setObject:@"" forKey:@"WFVectorMapView:route"];
    fetchNewResults = YES;
    [resultsArray removeAllObjects];
    headerAtItem = nil;
    [self repaint];
}


- (void)viewResults:(NSArray *)results
{
    CLLocation *currentLocation = [myLocManager currentLocation];

    /* Make sure that the current location is always visible on the map */
    double maxLat = currentLocation.coordinate.latitude, minLat = maxLat,
           maxLon = currentLocation.coordinate.longitude, minLon = maxLon;

    for (id result in results) {
        double rlat = [[result objectForKey:@"lat"] doubleValue] / MC2_SCALE;
        double rlon = [[result objectForKey:@"lon"] doubleValue] / MC2_SCALE;

        if (0 != rlat && 0 != rlon) {
            maxLat = fmax(maxLat, rlat);
            minLat = fmin(minLat, rlat);
            maxLon = fmax(maxLon, rlon);
            minLon = fmin(minLon, rlon);
        }
    }
    
    /* Add a small border around the results to make them fit better */
#ifdef PREMIUM_VERSION
    double heightCorrection;
    if (nil != routeTarget && 1 == [results count]) {
        /* Most likely just showing the target and starting point. Zoom out
           a little more so info panel does not cover the route or target. */
        heightCorrection = (maxLat - minLat) * RESULT_BOUNDS_RATIO_ROUTING;
    }
    else
        heightCorrection = (maxLat - minLat) * RESULT_BOUNDS_RATIO;
#else
    double heightCorrection = (maxLat - minLat) * RESULT_BOUNDS_RATIO;
#endif
    maxLat += heightCorrection;
    minLat -= heightCorrection;

    double widthCorrection = (maxLon - minLon) * RESULT_BOUNDS_RATIO;
    maxLon += widthCorrection;
    minLon -= widthCorrection;

    CLLocationCoordinate2D upperLeft;
    CLLocationCoordinate2D lowerRight;
    /* First, fix the upper left corner of the new bounding box */
    upperLeft.latitude = maxLat;
    upperLeft.longitude = minLon;

    /* Keep the aspect ratio so that all the results still fit on the map.
     *
     * Also adjust the bounding box so that the results are approximately in
     * the center of the map. */
    CGFloat aspectRatio = self.bounds.size.width / self.bounds.size.height;
    if (((maxLon - minLon) / (maxLat - minLat)) > aspectRatio) {
        /* A wide box, set the sides and then calculate the height of the box
         * based on the view aspect ratio */
        lowerRight.longitude = maxLon;
        lowerRight.latitude = maxLat - (maxLon - minLon) * aspectRatio;

        /* Then move the upper and lower sides so that the results are
         * approximately in the middle of the screen */
        CGFloat adjust = (minLat - lowerRight.latitude) / 2;
        upperLeft.latitude += adjust;
        lowerRight.latitude += adjust;
    } else {
        /* A tall box, now fix the upper and lower edges and calculate width */
        lowerRight.latitude = minLat;
        lowerRight.longitude = minLon + (maxLat - minLat) / aspectRatio;

        /* And then adjust the box sideways */
        CGFloat adjust = (lowerRight.longitude - maxLon) / 2;
        upperLeft.longitude -= adjust;
        lowerRight.longitude -= adjust;
    }

    MC2Coordinate nw(WGS84Coordinate(upperLeft.latitude,
                                     upperLeft.longitude));
    MC2Coordinate se(WGS84Coordinate(lowerRight.latitude,
                                     lowerRight.longitude));

    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    mapLibPtr->mapHandler->setWorldBox(nw, se);
    [self getResults];
    [self repaint];
}


- (void)showVisibleItemsOnMap
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    UIGraphicsPushContext(CGLayerGetContext(resultsLayer));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);

    [self getResults];
    int i = 1;
    for (MapResultItem *item in resultsArray)
    {
        // Check that item has coordinates
        if (item->lat != 0 && item->lon != 0) {
            MC2Point pt(0, 0);
            mapLibPtr->mapHandler->transform(pt, MC2Coordinate(item->lat,
                                                               item->lon));
            CGPoint point = CGPointMake(pt.getX(), pt.getY());
            
            item->bounds = CGRectMake(point.x - (resultIcon.size.width / 2) - 2,
                                      point.y - (resultIcon.size.height / 2) - 2,
                                      resultIcon.size.width + 2,
                                      resultIcon.size.height + 2);
            
            if (CGRectContainsPoint(self.bounds, point)) {
                NSString *str = [NSString stringWithFormat:@"%d", i];
                
                CGPoint drawPt = CGPointMake(item->bounds.origin.x + 2, item->bounds.origin.y + 2);
                
                [resultIcon drawAtPoint:drawPt];
                CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
                if (i < 10)
                    [str drawAtPoint:CGPointMake(pt.getX()-4,pt.getY()-9)
                            withFont:[UIFont boldSystemFontOfSize:14.0]];
                else if (i < 100)
                    [str drawAtPoint:CGPointMake(pt.getX()-8,pt.getY()-9)
                            withFont:[UIFont boldSystemFontOfSize:14.0]];
                else
                    [str drawAtPoint:CGPointMake(pt.getX()-10,pt.getY()-7)
                            withFont:[UIFont boldSystemFontOfSize:12.0]];
            }
        }
        
        i++;
    }
    UIGraphicsPopContext();
    [self setNeedsDisplay];
}

- (void)displayGPSIconOnMap
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    MC2Point pt(0, 0);
    BOOL animateIconMovement = NO;
    WGS84Coordinate wgs84coord(newUserLocation.latitude, newUserLocation.longitude); 
    mapLibPtr->mapHandler->transform(pt, MC2Coordinate(wgs84coord));
    CGPoint point = CGPointMake(pt.getX(), pt.getY());   
    
    // if the point goes out of current bounds, center it on map   
    if (!CGRectContainsPoint(self.bounds, point) && displayGPSIcon &&
        shouldCenterUserLocation)
        [self setMapCenter:newUserLocation];    
    
    // if there is a change in location or its accuracy, show the GPSView to animate the change
    if (((oldUserLocation.latitude != newUserLocation.latitude) || 
         (oldUserLocation.longitude != newUserLocation.longitude)) || 
       prevLocationAccuracy != locationAccuracy) 
    {
        gpsView.hidden = NO;
        animateIconMovement = YES;
        oldUserLocation = newUserLocation;
        prevLocationAccuracy = locationAccuracy;
    }    
    else {
        gpsView.hidden = YES;
    }    
       
    CGFloat accuracy = locationAccuracy / mapLibPtr->mapHandler->getScale();
    
    // if the accuracy circle bounds is greater than the current map bounds,
    // then change the mapscale so that the circle fits better 
    if (accuracy > (self.bounds.size.width / 2 - 10)  && displayGPSIcon)
    {
        mapLibPtr->mapHandler->setScale( locationAccuracy / (self.bounds.size.width / 2 - 20) );
        accuracy = locationAccuracy / mapLibPtr->mapHandler->getScale();
    }
    
    CGContextRef context = CGLayerGetContext(gpsLayer); 
    CGContextClearRect(context, self.bounds);
    UIGraphicsPushContext(context);   

    CGRect uncertainityCircle = CGRectMake(point.x - accuracy, point.y - accuracy,
                                           accuracy * 2, accuracy * 2);
    if (locationAccuracy < 100.0 || accuracy < 30.0) { 
        // show the little guy only when the accuracy is less than 100 or
        // when the circle radius is less than 40 pixels
        if(accuracy > 30.0)
            [self drawUnCertainityCircleWithGradiant:uncertainityCircle withContext:context];
        gpsIconView.hidden = NO;
    }
    else {
        [self drawUnCertainityCircleWithGradiant:uncertainityCircle withContext:context]; 
        gpsIconView.hidden = YES;
    }
    
    // If there is no change in the location or its accuracy then draw the gradiantcircle and 
    // the GPSIcon on the gpsLayer. Else show the GpsView to animate the change.
    if (!animateIconMovement){
        CGContextDrawImage(context, uncertainityCircle, myImage);
        UIImage *image = [UIImage imageNamed:@"gps-position-icon.png"];
        if (locationAccuracy < 100.0 || accuracy < 30.0)
            [image drawAtPoint:CGPointMake( (point.x - (image.size.width /2) ), 
                                           (point.y - (image.size.height /2) ) ) ];
    }   
    else
        [self animateGPSLocationTo:point withBounds:uncertainityCircle];    
    
#ifdef PREMIUM_VERSION
    // Draw also compass if map is rotated
    if (shouldCenterUserLocation && mapLibPtr->mapLib && nil != mapLibPtr->mapLib->getRouteID() && startedRouting) {
        UIImage *compassBg = [UIImage imageNamed:@"compass-background.png"];
        int cSize = compassBg.size.width / 2; // compass radius
        int aWidth = 3;
        int angle = myLocManager.currentLocation.course * -1;
        
        CGPoint cCntr = CGPointMake(self.frame.size.width - compassBg.size.width, self.frame.size.height - compassBg.size.height);
        CGPoint tip = CGPointMake(cCntr.x + sin((angle) * M_PI / 180) * cSize, cCntr.y - cos((angle) * M_PI / 180) * cSize);
        CGPoint bTip = CGPointMake(cCntr.x + sin((angle + 180) * M_PI / 180) * cSize, cCntr.y - cos((angle + 180) * M_PI / 180) * cSize);
        CGPoint leftWing = CGPointMake(cCntr.x + sin((angle - 90) * M_PI / 180) * aWidth, cCntr.y - cos((angle - 90) * M_PI / 180) * aWidth);
        CGPoint rightWing = CGPointMake(cCntr.x + sin((angle + 90) * M_PI / 180) * aWidth, cCntr.y - cos((angle + 90) * M_PI / 180) * aWidth);
        [compassBg drawAtPoint:CGPointMake(cCntr.x - cSize, cCntr.y - cSize) blendMode:kCGBlendModeNormal alpha:0.8];
        
        // Red arrow, left side
        CGContextSetRGBStrokeColor(context, 1.0, 0.5, 0.5, 1.0);
        CGContextSetRGBFillColor(context, 1.0, 0.5, 0.5, 1.0);
        
        CGContextMoveToPoint(context, cCntr.x, cCntr.y);
        CGContextAddLineToPoint(context, leftWing.x, leftWing.y);
        CGContextAddLineToPoint(context, tip.x, tip.y);
        CGContextAddLineToPoint(context, cCntr.x, cCntr.y);
        CGContextDrawPath(context, kCGPathEOFillStroke);
        
        // Red arrow, right side
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        
        CGContextMoveToPoint(context, cCntr.x, cCntr.y);
        CGContextAddLineToPoint(context, rightWing.x, rightWing.y);
        CGContextAddLineToPoint(context, tip.x, tip.y);
        CGContextAddLineToPoint(context, cCntr.x, cCntr.y);
        CGContextDrawPath(context, kCGPathEOFillStroke);
        
        // Black arrow, left side
        CGContextSetRGBStrokeColor(context, 0.4, 0.4, 0.4, 1.0);
        CGContextSetRGBFillColor(context, 0.4, 0.4, 0.4, 1.0);
        
        CGContextMoveToPoint(context, cCntr.x, cCntr.y);
        CGContextAddLineToPoint(context, leftWing.x, leftWing.y);
        CGContextAddLineToPoint(context, bTip.x, bTip.y);
        CGContextAddLineToPoint(context, cCntr.x, cCntr.y);
        CGContextDrawPath(context, kCGPathEOFillStroke);
        
        // Black arrow, right side
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
        CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
        
        CGContextMoveToPoint(context, cCntr.x, cCntr.y);
        CGContextAddLineToPoint(context, rightWing.x, rightWing.y);
        CGContextAddLineToPoint(context, bTip.x, bTip.y);
        CGContextAddLineToPoint(context, cCntr.x, cCntr.y);
        CGContextDrawPath(context, kCGPathEOFillStroke);
    }
#endif
    
    UIGraphicsPopContext(); 
}


- (void) animateGPSLocationTo:(CGPoint)newPt withBounds:(CGRect)bounds
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];   
    
    gpsView.center  = gpsImageView.center = gpsIconView.center =  newPt;
    gpsView.bounds = gpsImageView.bounds = bounds;
    
    [UIView commitAnimations];    
}


- (void) drawUnCertainityCircleWithGradiant:(CGRect)circleBounds withContext:(CGContextRef)context
{
    myImage = createGradientImage(circleBounds.size.width, circleBounds.size.height, circleBounds.origin); 
    UIImage *myUIImage = [UIImage imageWithCGImage:myImage];
    gpsImageView.image = myUIImage;   
    CGImageRelease(myImage);
}


CGImageRef createGradientImage (int pixelsWide, int pixelsHigh, CGPoint origin)
{
    CGContextRef gradientBitmapContext = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
	CGGradientRef grayScaleGradient;	
    colorSpace = CGColorSpaceCreateDeviceRGB();
    bitmapData = malloc(pixelsWide * pixelsHigh * 8);
	
    if (bitmapData == NULL)
        return NULL;
	
    gradientBitmapContext = CGBitmapContextCreate (bitmapData, pixelsWide, pixelsHigh,
												   8, pixelsWide *4, colorSpace, kCGImageAlphaPremultipliedLast);
	
    if (gradientBitmapContext== NULL) {
        CGColorSpaceRelease(colorSpace);
        free(bitmapData);
        return NULL;
    }
	
	CGFloat colors[] =
    {            
        204.0 / 255.0, 224.0 / 255.0, 244.0 / 255.0, GRADIANT_OPACITY,
        222.0 / 255.0,  237.0 / 255.0, 255.0 / 255.0, GRADIANT_OPACITY,
        180.0 / 255.0 , 215.0 / 255.0 , 228.0 / 255.0 , GRADIANT_OPACITY,
        167.0 / 255.0, 213.0 / 255.0, 254.0 / 255.0 , GRADIANT_OPACITY,
        135.0 / 255.0, 206.0 / 255.0, 235.0 / 255.0 , GRADIANT_OPACITY,
        29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, GRADIANT_OPACITY, 
        0.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0, GRADIANT_OPACITY,
    };
	
	grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, sizeof(colors)/(sizeof(colors[0])*5));
	
	CGRect rect = CGRectMake(0,0,pixelsWide,pixelsHigh);
    
    CGContextClipToRect(gradientBitmapContext, rect);
    CGFloat r = rect.size.width < rect.size.height ? rect.size.width : rect.size.height;
    CGPoint start, end;
    start = end = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGContextDrawRadialGradient(gradientBitmapContext, grayScaleGradient, start, (r * 0.125), end, (r * 0.5), kCGGradientDrawsBeforeStartLocation);
	
    CGImageRef theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);

	CGColorSpaceRelease(colorSpace);
    CGGradientRelease(grayScaleGradient);
	CGContextRelease(gradientBitmapContext);
    free(bitmapData);
	
    return theCGImage;
}


- (void)showItemOnMap:(NSDictionary *)item
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    [self getResults];
    for (MapResultItem *it in resultsArray)
        if ([it.item isEqualToDictionary:item]) {
            mapLibPtr->mapHandler->setCenter(MC2Coordinate(it->lat, it->lon));
            if(mapLibPtr->mapHandler->getScale() > SHOWONMAP_ZOOM_SCALE)
                mapLibPtr->mapHandler->setScale(SHOWONMAP_ZOOM_SCALE);
            headerAtItem = it;
            self.shouldCenterUserLocation = NO;
            [self repaint];
            /*NSArray *tempArray = [NSArray arrayWithObject:item];
            headerAtItem = it;
            self.shouldCenterUserLocation = NO;
            [self viewResults:tempArray];*/
        }
}


- (void)showRouteTo:(NSDictionary *)item routeType:(routingType)routeType
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    [self getResults];
    for (MapResultItem *it in resultsArray)
        if ([it.item isEqualToDictionary:item]) {
            // Clear old route
            mapLibPtr->mapLib->clearRouteID();
            mapLibPtr->mapLib->setRouteVisibility(false);
            // Request route from server
            routeTargetCoord.latitude = [[item objectForKey:@"lat"] doubleValue] / MC2_SCALE;
            routeTargetCoord.longitude = [[item objectForKey:@"lon"] doubleValue] / MC2_SCALE;
#ifdef PREMIUM_VERSION
            if (item != routeTarget || routeType != usedRouteType) {
                // Different route requested.
                //[self setInfoPanelOpen:NO animate:YES];
                speedLabel.text = @"-";
                self.startedRouting = NO;
                [rerouteButton setTitle:NSLocalizedString(@"Start", nil) forSegmentAtIndex:0];
                if (pedestrianRoute == routeType)
                    [routeIcon setImage:[UIImage imageNamed:@"foot_icon.png"]];
                else
                    [routeIcon setImage:[UIImage imageNamed:@"car_icon.png"]];
            }
            self.routeTarget = item;
            usedRouteType = routeType;
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:routeTargetCoord.latitude longitude:routeTargetCoord.longitude];
            CLLocation *curLoc = [[CLLocation alloc] initWithLatitude:newUserLocation.latitude longitude:newUserLocation.longitude];
            distanceLabel.text = [[WFCommandRouter SharedCommandRouter]
                                  distanceToString:[NSNumber numberWithDouble:[curLoc getDistanceFrom:loc]]];
            [self setInfoPanelOpen:YES animate:YES];
#endif
            
            [xmlService routeRequestFrom:newUserLocation to:routeTargetCoord routeType:routeType oldRouteId:usedRouteId];
            
            // Save route target
            NSDictionary *routeDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithDouble:routeTargetCoord.latitude], @"routeLat",
                                       [NSNumber numberWithDouble:routeTargetCoord.longitude], @"routeLon",
                                       [NSNumber numberWithInt:routeType], @"routeType", nil];
            [[WFAppStateStore sharedStateStore]
             setObject:routeDict forKey:@"WFVectorMapView:route"];
            
            // Clear header
            headerAtItem = nil;
            
            // Zoom to show own location and target
            NSArray *tempArray = [NSArray arrayWithObject:item];
            self.shouldCenterUserLocation = NO;
            [self viewResults:tempArray];
        }
}

- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    NSLog(@"Route request failed.");
    if (mapLibPtr->mapLib) {
        mapLibPtr->mapLib->clearRouteID();
        mapLibPtr->mapLib->setRouteVisibility(false);
    }
    [usedRouteId release];
    usedRouteId = nil;
#ifdef PREMIUM_VERSION
    self.routeTarget = nil;
    distanceLabel.text = @"-";
    [self setInfoPanelOpen:NO animate:YES];
    [rerouteButton setTitle:NSLocalizedString(@"Start", nil) forSegmentAtIndex:0];
    self.startedRouting = NO;
#endif
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:@"Route Status" message:@"Can't calculate route."
                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];
}

- (void)service:(WFXMLService *)service didReceiveRoute:(NSString *)routeId
      routeData:(NSDictionary *)routeData transActionId:(NSString *)Id
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
    RouteID mapLibRouteId([routeId UTF8String]);
    if (0 == mapLibRouteId.isValid()) {
        NSLog(@"Route ID invalid!");
    }
    else {
#ifdef PREMIUM_VERSION
        /* Could be that route timer has already fired before we get the route data
           Don't show time if this has happened */
        if (!startedRouting || (showRouteTimer && [showRouteTimer isValid])) {
            int seconds = [[routeData objectForKey:@"total_time_nbr"] intValue];
            // Round minutes always up so add 1
            int minutes = (seconds / 60 + 1);
            int hours = 0;
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes - hours * 60;
            }
            
            if (hours > 0)
                speedLabel.text = [NSString stringWithFormat:@"%dh %dm", hours, minutes];
            else
                speedLabel.text = [NSString stringWithFormat:@"%d min", minutes];
        }
        usedRouteId = [[NSString stringWithString:routeId] retain];
#endif
        // With normal settings the route layer is not draw in MapLib. Set it visible.
        mapLibPtr->mapLib->setRouteVisibility(true);
        mapLibPtr->mapLib->setRouteID( mapLibRouteId );
    }
}

- (void)showMoreResults
{
    fetchNewResults = YES;
}


- (void)zoomToNearestResults
{
    fetchNewResults = YES;
    self.shouldCenterUserLocation = NO;
    [self viewResults:[resultModel getResultsInRange:NSMakeRange(0, 5)]];
}


- (void)showCurrentLocationOnMap
{
#ifdef PREMIUM_VERSION
    if (shouldStopLocUpdate || !shouldCenterUserLocation || selfZoomed) {
        selfZoomed = NO;
#else
    if (shouldStopLocUpdate || !shouldCenterUserLocation) {
#endif
        /* User activates locate button. Follow position constantly. */
        self.shouldCenterUserLocation = YES;
        self.shouldStopLocUpdate = NO;
        [myLocManager startUpdatingLocation];
        // Also set map to show users location now
        self.mapScale = DEFAULT_METERS_PER_PIXEL;
        self.mapCenter = newUserLocation;
    }
    else {
        /* Location following deactivated */
        self.shouldStopLocUpdate = YES;
        //[searchBarController didFinishUpdatingLocation];
        [[WFCommandRouter SharedCommandRouter] didFinishUpdatingLocation];
        if (locationAccuracy < kCLLocationAccuracyHundredMeters) {
            [myLocManager stopUpdatingLocation];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (!mapLibPtr->mapHandler)
        [self createMapLib];
#ifdef PREMIUM_VERSION
    // Rotate map if necessary
    if (shouldCenterUserLocation && mapLibPtr->mapLib && nil != mapLibPtr->mapLib->getRouteID() && startedRouting) {
        // Map following user and we have a route. rotate
        mapLibPtr->mapHandler->setAngle(newLocation.course);
        
        if (!selfZoomed) {
            // Zoom map out if going fast enough
            if (newLocation.speed < 14) // 14 m/s ~ 50 km/h
                self.mapScale = DEFAULT_METERS_PER_PIXEL;
            else if (newLocation.speed < 34) { // 34 m/s ~ 122 km/h
                self.mapScale = DEFAULT_METERS_PER_PIXEL + ((MAX_METERS_PER_PIXEL - DEFAULT_METERS_PER_PIXEL) * ((newLocation.speed - 14) / 20));
            }
            else
                self.mapScale = MAX_METERS_PER_PIXEL;
        }
    }
    
    // We might be showin the route time in the same label
    if (!startedRouting || !(showRouteTimer && [showRouteTimer isValid])) {
        if (newLocation.speed < 0)
            speedLabel.text = [NSString stringWithFormat:@"0 %@", speedAbbr];
        else
            speedLabel.text = [NSString stringWithFormat:@"%d %@", (int)(newLocation.speed * speedMultiplier), speedAbbr];
    }
    
    if (routeTargetCoord.latitude == 0 && routeTargetCoord.longitude == 0)
        distanceLabel.text = @"-";
    else {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:routeTargetCoord.latitude longitude:routeTargetCoord.longitude];
        distanceLabel.text = [[WFCommandRouter SharedCommandRouter]
                              distanceToString:[NSNumber numberWithDouble:[newLocation getDistanceFrom:loc]]];
    }
#endif
    
    newUserLocation = newLocation.coordinate;
    locationAccuracy = newLocation.horizontalAccuracy;
    
    if (shouldCenterUserLocation) {
#ifndef PREMIUM_VERSION
        self.mapScale = DEFAULT_METERS_PER_PIXEL;
#endif
        self.mapCenter = newLocation.coordinate;
    }
    else {
        // Don't center the map on user but refresh it so location is updated
        [self repaint];
    }
    
    if (shouldStopLocUpdate && newLocation.horizontalAccuracy < kCLLocationAccuracyHundredMeters){
        [manager stopUpdatingLocation];
        [[WFCommandRouter SharedCommandRouter] didFinishUpdatingLocation];
    }
}

- (UILabel *)newLabelWithFontSize:(CGFloat)fontSize bold:(BOOL)bold
{
    
    UIFont *font;
    if (bold) {
        font = [UIFont boldSystemFontOfSize:fontSize];
    } else {
        font = [UIFont systemFontOfSize:fontSize];
    }
    
	UILabel *newLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    newLabel.backgroundColor = [UIColor clearColor];
    newLabel.textAlignment = UITextAlignmentCenter;
	newLabel.opaque = YES;
    newLabel.textColor = [UIColor whiteColor];
    newLabel.shadowColor = [UIColor blackColor];
    newLabel.shadowOffset = CGSizeMake(1, 1);
	newLabel.font = font;
	
	return newLabel;
}


#ifdef PREMIUM_VERSION
- (void)setInfoPanelOpen:(BOOL)panelOpen animate:(BOOL)animate
{
	//infoPanel.center = startPos;
    CGPoint startPos = infoPanel.center;
    CGPoint stopPos;
    if (panelOpen)
        stopPos = panelOpenPos;
    else
        stopPos = panelClosePos;
	
	CALayer *theLayer;
	theLayer = infoPanel.layer; 
    
	CABasicAnimation *theAnimation;
	theAnimation=[CABasicAnimation animationWithKeyPath:@"position"];
	theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	theAnimation.fromValue = [NSValue valueWithPointer:&startPos];	
	theAnimation.toValue = [NSValue valueWithPointer:&stopPos];
	theAnimation.duration = 1.0;
	[theLayer addAnimation:theAnimation forKey:@"theAnimation"];
    
    infoPanel.center = stopPos;
    isPanelOpen = panelOpen;
    if (panelOpen)
        infoPanel.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    infoPanel.hidden = !isPanelOpen;
}

- (void)showRouteTimerFired:(NSTimer *) timer
{
    // Just return map to users location
    [self showCurrentLocationOnMap];
    [[WFCommandRouter SharedCommandRouter] didStartFollowingLocation];
    [showRouteTimer invalidate];
    [showRouteTimer release];
    showRouteTimer = nil;
    speedLabel.text = [NSString stringWithFormat:@"0 %@", speedAbbr];
    [self setInfoPanelOpen:NO animate:YES];
}
#endif

@end
