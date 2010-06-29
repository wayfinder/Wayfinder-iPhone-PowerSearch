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
#import <Foundation/NSGeometry.h>
//#import "WFGeoDataWrappers.hpp"

class WFGeoDataBuilderWrap;
class WFGeoDataSearcherWrap;
class WFGeoDataPointWrap;
class WFGeoDataPointCursorWrap;

@interface WFGeoDataPoint : NSObject
{
    WFGeoDataPointWrap *pointWrap;
}

- (id)init;
- (id)initWithMaxDataSize:(unsigned int)aDataSize;
- (void)dealloc;
- (CLLocationCoordinate2D)point;
- (void)setPoint:(CLLocationCoordinate2D)aPoint;
- (void *)data;
- (BOOL)setData:(const void *)aData dataSize:(unsigned int)aDataSize;
- (unsigned int)dataSize;
- (unsigned int)maxDataSize;
/* For setting point in C++ implementations: */
- (void)setWrappedPoint:(WFGeoDataPointWrap *)wrappedPoint;

@end

@interface WFGeoDataPointCursor : NSObject
{
    WFGeoDataPointCursorWrap *cursorWrap;
}

- (id)initWithCursor:(WFGeoDataPointCursorWrap*)newCursor;
- (int/*???*/)getNextPoint:(WFGeoDataPoint *)aPoint;
- (void)destroy;

@end

@interface WFGeoData : NSObject
{
    WFGeoDataBuilderWrap *dbBuilder;
    WFGeoDataSearcherWrap *dbSearcher;
    NSRect boundaryRect;
    NSString* databaseName;
}

- (id)init;
- (id)initWithBoundingRect:(NSRect)boundingRect dbName:(char *)dbName;
- (void)dealloc;
- (BOOL)addPoint:(WFGeoDataPoint *)point;
- (BOOL)addPoints:(NSArray *)points;
- (BOOL)dbDone;
- (WFGeoDataPointCursor *)searchPointsFromRect:(NSRect)targetRect excludeRect:(NSRect)excludeRect;

@end
