/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFRegionModel.h"

// Name of top region in user settings
NSString *TOP_REGION_SETTING = @"WFTopRegion";

@implementation WFRegionModel

@synthesize delegate, service;

static WFRegionModel *SharedRegionModel;

+ (WFRegionModel*)sharedRegionModel 
{
	if(SharedRegionModel == nil) 
	{
		[[self alloc] init];		
	}
	return SharedRegionModel;
}

+ (id) allocWithZone:(NSZone *)zone 
{
	if(SharedRegionModel == nil) 
	{
		SharedRegionModel = [super allocWithZone:zone];
		return SharedRegionModel;
	}
	return nil;
}

- (id)init
{
    if (self = [super init])
	{
        // Load previous top region from settings
        topRegion = [[[NSUserDefaults standardUserDefaults] objectForKey:TOP_REGION_SETTING] copy];
        providerArray = [[NSMutableArray alloc] init];
        transactionStatus = InProgress;
        [[WFLocationManager sharedManager] addDelegate:self];
    }
    return self;
}

- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    transactionStatus = Abort;
}

- (void)service:(WFXMLService *)service didFinishTransAction:(NSString *)Id
{
    transactionStatus = Finish;
    [delegate didReceiveRegionForModel:self];
}

- (void)service:(WFXMLService *)service didReceiveItem:(NSDictionary *)item
  transActionId:(NSString *)Id
{
    if (nil != [item objectForKey:STR_HEADING]) {
        // This is a data provider
        [providerArray addObject:item];
    }
    else if (nil != [item objectForKey:STR_TOP_REGION_ID]) {
        // This is the top region
        [topRegion release];
        topRegion = [[NSDictionary dictionaryWithDictionary:item] retain];
        [[NSUserDefaults standardUserDefaults] setObject:topRegion forKey:TOP_REGION_SETTING];
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // We only need the location once
    [[WFLocationManager sharedManager] removeDelegate:self];
    if (!service) {
        service = [WFXMLService service];
    }
    service.delegate = self;
    [service regionRequestWithCoordinate:newLocation.coordinate];
}

- (NSUInteger)getProviderCount
{
    return [providerArray count];
}

- (NSArray *)getUsedProviders
{
    return providerArray;
}

- (WFBoundingBox)getTopRegion
{
    WFBoundingBox region;
    NSDictionary *dict = [topRegion objectForKey:STR_BOUNDING_BOX];
    region.upperLeft.latitude = [[dict objectForKey:STR_NORTH_LAT] doubleValue];
    region.upperLeft.longitude = [[dict objectForKey:STR_WEST_LON] doubleValue];
    region.lowerRight.latitude = [[dict objectForKey:STR_SOUTH_LAT] doubleValue];
    region.lowerRight.longitude = [[dict objectForKey:STR_EAST_LON] doubleValue];
    
    return region;
}

- (NSString *)getRegionName
{
    return [topRegion objectForKey:STR_TOP_REGION_NAME];
}

- (TransactionStatus)getTransactionStatus
{
    return transactionStatus;
}

- (void)dealloc 
{
    [providerArray release];
    [topRegion release];
	[super dealloc];
}

// Singleton stuff
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
