/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFLocationManager.h"
#import "WFResultsModel.h"
#import "WFAppStateStore.h"
#import "constants.h"

// Show 25 results at the time
#define RESULTS_SHOWN_INTERVAL 25

@interface WFResultsModel()
- (void) sortByDistance;
@end

@interface WFResultsModel(StateStore)
@property (nonatomic) BOOL newSearch;
@property (nonatomic) int resultsShown;
@end

@implementation WFResultsModel(StateStore)
@dynamic newSearch, resultsShown;

- (BOOL)newSearch { return newSearch; }
- (void)setNewSearch:(BOOL)value
{
    newSearch = value;
    [store setObject:[NSNumber numberWithBool:newSearch]
              forKey:@"WFResultsModel:newSearch"];
}

- (int)resultsShown { return resultsShown; }
- (void)setResultsShown:(int)value
{
    resultsShown = value;
    [store setObject:[NSNumber numberWithInt:resultsShown]
              forKey:@"WFResultsModel:resultsShown"];
}

@end


@implementation WFResultsModel

@synthesize searchResultsArray, delegate, detailDelegate;
@dynamic searchString, wasCategorySearch;

- (void)dealloc 
{
    [searchResultsArray release];
    [service release];
	[super dealloc];
}

// We need some initWithId: method so data is stored to different places
- (id)init
{	
	if (self = [super init])
	{
        store = [WFAppStateStore sharedStateStore];

        resultsShown = [[store objectForKey:@"WFResultsModel:resultsShown"]
            intValue];
        wasCategorySearch = [[store
            objectForKey:@"WFResultsModel:wasCategorySearch"] boolValue];

        NSNumber *search = [store objectForKey:@"WFResultsModel:newSearch"];
        if (search)
            newSearch = [search boolValue];
        else
            self.newSearch = YES;

        //searchResultsArray = [store
        //    objectForKey:@"WFResultsModel:searchResultsArray"];
        if (!searchResultsArray)
            searchResultsArray = [[NSMutableArray alloc] init];	        

        //searchString = [[store objectForKey:@"WFResultsModel:searchString"] retain];

        service = [[WFXMLService alloc] init];
        service.delegate = self;
    }
    return self;
}


- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    transactionStatus = Abort;
    [delegate operationFailedWithError:anError];
}



- (void)service:(WFXMLService *)service didFinishTransAction:(NSString *)Id
{
    if ([transactionId isEqual:Id])
        transactionId = nil;
    if (newSearch)
        self.resultsShown = RESULTS_SHOWN_INTERVAL;
    transactionStatus = Finish;

    [store setObject:searchResultsArray
              forKey:@"WFResultsModel:searchResultsArray"];
    if ([delegate
         respondsToSelector:@selector(didReceiveResultsForModel:newSearch:)])
        [delegate didReceiveResultsForModel:self newSearch:newSearch];
}


- (void)service:(WFXMLService *)service didReceiveItem:(NSDictionary *)item
     transActionId:(NSString *)Id
{
    // Only accept item if some transaction is ongoing
    if (InProgress != transactionStatus)
        return;
    
    sorted = NO;
    
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

    NSMutableDictionary *dictionaryItem = [item mutableCopy];
    [dictionaryItem setValue:distance forKey:@"distance"];
    
    [searchResultsArray addObject:dictionaryItem];
    [dictionaryItem release];
}


- (void)service:(WFXMLService *)service didReceiveDetail:(NSDictionary *)receivedItem
               transActionId: (NSString *)receivedId
{
    for (NSMutableDictionary *item in searchResultsArray) {
            NSString *itemId = [item objectForKey:@"details_trId"];

            if (itemId && [itemId isEqualToString:receivedId]) {
                [item removeObjectForKey:@"details_trId"];
                [item addEntriesFromDictionary:receivedItem];
                if ([detailDelegate
                     respondsToSelector:@selector(detailsReadyForItem:)])
                    [detailDelegate detailsReadyForItem:item];

                [store setObject:searchResultsArray
                          forKey:@"WFResultsModel:searchResultsArray"];
                return;
            }
    }
}


- (int) getResultsCount
{    
    if ([searchResultsArray count] > resultsShown)
        return resultsShown;

    return [searchResultsArray count];
}

- (void) sortByDistance
{
    if (!sorted) {
        NSSortDescriptor *sortDescriptor =[[NSSortDescriptor alloc]
                                           initWithKey:@"distance" ascending:YES];
        [searchResultsArray
         sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [sortDescriptor release];

        [store setObject:searchResultsArray
                  forKey:@"WFResultsModel:searchResultsArray"];
        
        sorted = YES;
    }
}

- (NSArray *) getResults
{
    /* resultsShown - 1 so we give the correct amount */
    return [self getResultsInRange:NSMakeRange(0, resultsShown)];
}


- (NSArray *) getResultsInRange:(NSRange)range
{
    if (!sorted)
        [self sortByDistance];
    
    if ([searchResultsArray count] >= range.location) {
        if ([searchResultsArray count] < (range.location + range.length))
            range.length = [searchResultsArray count] - range.location;
        return [searchResultsArray subarrayWithRange:range];
    }
    return nil;
}

- (NSDictionary *)resultAtIndex:(NSInteger)index
{
    if (!sorted)
        [self sortByDistance];
    
    if (index < [searchResultsArray count])
        return [searchResultsArray objectAtIndex:index];
    
    return nil;
}

- (void) clearResults
{
    self.resultsShown = 0;
    [searchResultsArray removeAllObjects];

    [store setObject:searchResultsArray
              forKey:@"WFResultsModel:searchResultsArray"];
    
    if ([delegate
         respondsToSelector:@selector(resultsCleared)])
        [delegate resultsCleared];
}

- (void)addResult:(NSDictionary *)newResult
{
    [searchResultsArray addObject:newResult];
}

- (void) showMoreResults
{
    CLLocationCoordinate2D myLocation = [[WFLocationManager
                                          sharedManager] currentLocation].coordinate;
    /* Add +1 for each search round so we won't fetch same results twice */
    NSRange searchRange = {resultsShown + (int)(resultsShown / 25), RESULTS_SHOWN_INTERVAL};
    
    if (wasCategorySearch) {
        transactionId = [service searchWithCategory:searchString
                                         coordinate:myLocation
                                        searchRange:searchRange];
    }
    else {
        transactionId = [service searchWithString:searchString
                                       coordinate:myLocation
                                      searchRange:searchRange];
    }
    self.newSearch = NO;
    resultsShown += RESULTS_SHOWN_INTERVAL;
}

- (BOOL) hasMoreResults
{
    return ([searchResultsArray count] > resultsShown);
}

/* Do the actual search from xmlService.
 * Note: We fetch 1-2 extra results (range 0 - 25) so the hasMoreResults returns
 * correct value. */
- (void) searchWithString:(NSString *)queryString
{    
    self.searchString = queryString;
    self.newSearch = YES;
    self.wasCategorySearch = NO;
    transactionStatus = InProgress; 
                
    CLLocationCoordinate2D myLocation = [[WFLocationManager
                                             sharedManager] currentLocation].coordinate;
    NSRange searchRange = {0, RESULTS_SHOWN_INTERVAL};
    
    // Cancel old operation if ongoing
    [self cancelDownload];
    
    transactionId = [service searchWithString:queryString
                                   coordinate:myLocation
                                  searchRange:searchRange];

}

- (void) searchWithCategory:(NSString *)categoryId
{
    self.searchString = categoryId;
    self.newSearch = YES;
    self.wasCategorySearch = YES;
    transactionStatus = InProgress;
                
    CLLocationCoordinate2D myLocation = [[WFLocationManager
                                             sharedManager] currentLocation].coordinate;
    NSRange searchRange = {0, RESULTS_SHOWN_INTERVAL};
    
    // Cancel old operation if ongoing
    [self cancelDownload];
    
    transactionId = [service searchWithCategory:categoryId
                                     coordinate:myLocation
                                    searchRange:searchRange];
    
}

- (void) getDetailsFor:(NSDictionary *) item
{
    // first find out if we have search these details before
    NSString *itemId = [item objectForKey:@"itemid"];
    NSMutableDictionary *listItem;
    NSString *tmpId;

    for (NSMutableDictionary *id in searchResultsArray) {
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
        NSString *trId = [service searchPoiDetails:itemId
             name:[item objectForKey:@"name"]];
        [listItem setObject:trId forKey:@"details_trId"];
    }
}

- (void)cancelDownload
{
    if (transactionId && ![transactionId isEqual:@""]) {
        // Some operation is ongoing. Cancel
        [service cancelTransAction:transactionId];
        transactionId = nil;
        transactionStatus = Abort;
    }
}

- (BOOL)wasCategorySearch { return wasCategorySearch; }
- (void)setWasCategorySearch:(BOOL)value
{
    wasCategorySearch = value;
    [store setObject:[NSNumber numberWithBool:wasCategorySearch]
              forKey:@"WFResultsModel:wasCategorySearch"];
}

- (NSString *)searchString
{ 
    return searchString; 
}

- (void)setSearchString:(NSString *)value
{
    if (value != searchString) {
        [searchString release];
        searchString = [value retain];
        
        [store setObject:searchString forKey:@"WFResultsModel:searchString"];
    }
}


@end
