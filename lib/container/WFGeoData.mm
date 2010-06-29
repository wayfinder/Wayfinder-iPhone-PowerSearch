/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFGeoData.h"
#import "WFGeoDataWrappers.hpp"

/*
 * WFGeoDataPoint implementation
 */

@implementation WFGeoDataPoint

- (id)init
{
    return [self initWithMaxDataSize:1024];
}

- (id)initWithMaxDataSize:(unsigned int)aDataSize
{
    if (self = [super init]) {
        pointWrap = new WFGeoDataPointWrap;
    }
    return self;
}

- (void)dealloc
{
    delete pointWrap;
    [super dealloc];
}

- (CLLocationCoordinate2D)point
{
    CLLocationCoordinate2D newCoord;
    SSCoordinate oldCoord;
    
    oldCoord = pointWrap->point->point();
    
    newCoord.latitude = oldCoord.x;
    newCoord.longitude = oldCoord.y;
    
    return newCoord;
}

- (void)setPoint:(CLLocationCoordinate2D)aPoint
{
    SSCoordinate newCoord;
    
    newCoord.x = aPoint.latitude;
    newCoord.y = aPoint.longitude;
    
    pointWrap->point->set_point(newCoord);
}

- (void *)data
{
    return pointWrap->point->data_ptr();
}

- (BOOL)setData:(const void *)aData dataSize:(unsigned int)aDataSize
{
    return pointWrap->point->set_data(aData, aDataSize);
}

- (unsigned int)dataSize
{
    return pointWrap->point->get_data_size();
}

- (unsigned int)maxDataSize
{
    return pointWrap->point->get_max_data_size();
}

/* For setting point in C++ implementations: */
- (void)setWrappedPoint:(WFGeoDataPointWrap *)wrappedPoint
{
    delete pointWrap;
    pointWrap = wrappedPoint;
}

@end


/*
 * WFGeoDataPointCursor implementation
 */

@implementation WFGeoDataPointCursor

- (id)init
{
    /* People are not supposet to use this method!*/
    return nil;
}

- (id)initWithCursor:(WFGeoDataPointCursorWrap*)newCursor
{
    if (self = [super init]) {
        cursorWrap = newCursor;
    }
    
    return self;
}

- (int/*???*/)getNextPoint:(WFGeoDataPoint *)aPoint
{
    WFGeoDataPointWrap *ptWrap = new WFGeoDataPointWrap;
    SSGeoDataStatus status;
    status = cursorWrap->cursor->get_next_point(ptWrap->point);
    
    if (GDS_Success == status) {
        [aPoint setWrappedPoint:ptWrap];
    }
    else if (GDS_NoMorePoints == status) {
        /* XXX: Define return codes*/
    }
    else {
        /* Actual error */
    }

    return 1;
}

- (void)destroy
{
    cursorWrap->cursor->destroy();
}

@end


/*
 * WFGeoData implementation
 */

@implementation WFGeoData

- (id)init
{
    // What to use as default bounding rect???
    NSRect defaultRect;
    return [self initWithBoundingRect:defaultRect dbName:"geodata"];
}

- (id)initWithBoundingRect:(NSRect)boundingRect dbName:(char *)dbName
{
    if (self = [super init]) {
        SSGeoDataStatus status;
        SSGeoDataBuilder::BuildSpec sp;
        //NSString *tempPath;

        boundaryRect = boundingRect;
        databaseName = [[NSString alloc] initWithCString:dbName];
        //tempPath = [[NSString alloc] initWithCString:"path"];
        
        dbBuilder = new WFGeoDataBuilderWrap;
        dbSearcher = new WFGeoDataSearcherWrap;
        
        sp.bounding_box_of_data = SSRectangle(boundaryRect.origin.x,
                                              boundaryRect.origin.y,
                                              boundaryRect.origin.x + boundaryRect.size.width,
                                              boundaryRect.origin.y + boundaryRect.size.height);
        
        //status = dbBuilder->builder->initialize( [databaseName UTF8String], [tempPath UTF8String], sp);
        status = dbBuilder->builder->initialize( [databaseName UTF8String], [NSTemporaryDirectory() UTF8String], sp);
        
    }
    return self;
}

- (void)dealloc
{
    delete dbBuilder;
    delete dbSearcher;
    [databaseName release];
    [super dealloc];
}

- (BOOL)addPoint:(WFGeoDataPoint *)point
{
    SSPoint newPoint(1024);
    SSCoordinate newCoord;
    
    CLLocationCoordinate2D oldCoord;
    
    oldCoord = [point point];
    
    newCoord.x = oldCoord.latitude;
    newCoord.y = oldCoord.longitude;
    
    newPoint.set_point(newCoord);
    newPoint.set_data([point data], [point dataSize]);
    
    if (GDS_Success != dbBuilder->builder->add_point(newPoint))
        return NO;
    
    return YES;
}

- (BOOL)addPoints:(NSArray *)points
{
    return NO;
}

- (BOOL)dbDone
{
    if (GDS_Success != dbBuilder->builder->finalize())
        return NO;
    
    return YES;
}

- (WFGeoDataPointCursor *)searchPointsFromRect:(NSRect)targetRect excludeRect:(NSRect)excludeRect
{
    SSRectangle newTarget = SSRectangle(targetRect.origin.x,
                                        targetRect.origin.y,
                                        targetRect.origin.x + targetRect.size.width,
                                        targetRect.origin.y + targetRect.size.height);
    SSRectangle newExlusion = SSRectangle(excludeRect.origin.x,
                                          excludeRect.origin.y,
                                          excludeRect.origin.x + excludeRect.size.width,
                                          excludeRect.origin.y + excludeRect.size.height);
    
    //SSPointCursor * cursor = dbAccessor->startSearch ( newTarget, newExlusion);
    WFGeoDataPointCursorWrap *cursor = new WFGeoDataPointCursorWrap(dbSearcher->searcher->start_search(newTarget, &newExlusion));
    
    //WFGeoDataPointCursor *rcCursor = [[WFGeoDataPointCursor alloc] initWithCursor:cursor];
    return [[WFGeoDataPointCursor alloc] initWithCursor:cursor];
}

@end
