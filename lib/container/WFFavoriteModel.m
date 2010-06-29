/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFFavoriteModel.h"
#import "WFLocationManager.h"

// File name of favorites
NSString *FAVORITE_FILE_NAME = @"favorite.archive";

@interface WFFavoriteModel()
- (void) loadFavorites;
@end

@implementation WFFavoriteModel

@synthesize delegate, detailDelegate;

static WFFavoriteModel *SharedFavoriteModel;

+ (WFFavoriteModel*) SharedFavoriteArray
{
	if(SharedFavoriteModel == nil) 
	{
		SharedFavoriteModel = [[self alloc] init];
    }
	
	return SharedFavoriteModel;
}

- (id)init
{
    if (self = [super init])
	{
        [self loadFavorites];
    }
    
    return self;
}

- (void) dealloc
{
    [service release];
    [favoriteArray release];
    [super dealloc];
}

- (int) getResultsCount
{
    return [favoriteArray count];
}

- (NSArray *) getResults
{
    return favoriteArray;
}

- (NSDictionary *) resultAtIndex:(NSInteger)index
{
    return [favoriteArray objectAtIndex:index];
}

- (NSArray *) getResultsInRange:(NSRange)range
{
    if ([favoriteArray count] >= range.location) {
        if ([favoriteArray count] < (range.location + range.length))
            range.length = [favoriteArray count] - range.location;
        return [favoriteArray subarrayWithRange:range];
    }
    return nil;
}

- (void) addFavorite:(NSDictionary *)favorite
{
    /* Check that duplicates are not added to list
       NOTE: Item ID of POI changes often so it can't be used. Maybe
       the best way to do is to check the name and coordinates. */
    NSString *favName = [favorite objectForKey:@"name"];
    for (NSMutableDictionary *item in favoriteArray) {
        if ([[item objectForKey:@"name"] isEqual:favName]) {
            // Name matches but also check the coordinates
            if ([[item objectForKey:@"lat"] isEqual:[favorite objectForKey:@"lat"]] &&
                [[item objectForKey:@"lon"] isEqual:[favorite objectForKey:@"lon"]])
                return; // OK, we're pretty sure this is the same item
        }
    }
    
    [favoriteArray addObject:favorite];
    if ([delegate
         respondsToSelector:@selector(favoriteListUpdated:)])
        [delegate favoriteListUpdated:self];
}

- (void) removeFavoriteAtIndex:(int)index
{
    if (index < [favoriteArray count]) {
        [favoriteArray removeObjectAtIndex:index];
        if ([delegate
             respondsToSelector:@selector(favoriteListUpdated:)])
            [delegate favoriteListUpdated:self];
    }
}

- (void) moveFavoriteAtIndex:(int)from toIndex:(int)to
{
    [favoriteArray exchangeObjectAtIndex:from withObjectAtIndex:to];
    if ([delegate
         respondsToSelector:@selector(favoriteListUpdated:)])
        [delegate favoriteListUpdated:self];
}

- (void) getDetailsFor:(NSDictionary *) item
{
    // first find out if we have search these details before
    NSString *itemId = [item objectForKey:@"itemid"];
    NSMutableDictionary *listItem;
    NSString *tmpId;
    
    for (NSMutableDictionary *id in favoriteArray) {
        tmpId = [id objectForKey:@"itemid"];
        if (tmpId == itemId) {
            listItem = id;
            break; // found it
        }
    }
    
    if([listItem objectForKey:@"info"]) {
        if ([detailDelegate
             respondsToSelector:@selector(detailsReadyForItem:)])
            [detailDelegate detailsReadyForItem:listItem];        
    }
    else {
        if (!service) {
            service = [[WFXMLService alloc] init];
            service.delegate = self;
        }
        NSString *trId = [service searchPoiDetails:itemId
                                              name:[item objectForKey:@"name"]];
        [listItem setObject:trId forKey:@"details_trId"];
    }
}

// WFXMLServiceDelegate methods
- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    [delegate operationFailedWithError:anError];
}

- (void)service:(WFXMLService *)service didReceiveDetail:(NSDictionary *)receivedItem
  transActionId: (NSString *)receivedId
{
    for (NSMutableDictionary *item in favoriteArray) {
        NSString *itemId = [item objectForKey:@"details_trId"];
        
        if (itemId && [itemId isEqualToString:receivedId]) {
            [item removeObjectForKey:@"details_trId"];
            [item addEntriesFromDictionary:receivedItem];
            if ([detailDelegate
                 respondsToSelector:@selector(detailsReadyForItem:)])
                [detailDelegate detailsReadyForItem:item];
            
            return;
        }
    }
}

- (void) loadFavorites
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FAVORITE_FILE_NAME];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        favoriteArray = [[NSKeyedUnarchiver unarchiveObjectWithFile:filePath] retain];
    }
    else
        favoriteArray = [[NSMutableArray alloc] init];
}

- (void) saveFavorites
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FAVORITE_FILE_NAME];
    
    /* Save everything from POI. This also saves the details. As POI ID may change on server,
       we have no way to know if the saved ID points to the same POI. Ie. we can't download
       details again. */
    
    [NSKeyedArchiver archiveRootObject:favoriteArray toFile:filePath];
}

- (void) didReceiveInitialLocation
{
    // Recalculate distance
    for (NSMutableDictionary *item in favoriteArray) {
        NSString *latitude, *longitude;
        latitude = [item objectForKey:@"lat"];
        longitude = [item objectForKey:@"lon"];
        
        NSNumber *distance;
        
        /* If there is no location information in the item, make sure that it
         * always gets to the end of the list when sorted. */
        if (latitude == nil && longitude == nil) {
            distance = [NSNumber numberWithFloat:FLT_MAX];
        }
        else {
            CLLocation *newLocation = [[CLLocation alloc]
                                       initWithLatitude:(CLLocationDegrees)([latitude doubleValue] / MC2_SCALE)
                                       longitude:(CLLocationDegrees)([longitude doubleValue] / MC2_SCALE)];
            CLLocation *myCurrentLocation = [WFLocationManager sharedManager].currentLocation;
            
            distance = [NSNumber numberWithFloat:[myCurrentLocation getDistanceFrom:newLocation]];
            [newLocation release];
        }
        
        [item setValue:distance forKey:@"distance"];
    }
    
    if ([delegate
         respondsToSelector:@selector(favoriteListUpdated:)])
        [delegate favoriteListUpdated:self];
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
