/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <CoreLocation/CLLocation.h>

#import "GTMSenTestCase.h"
#import "WFXMLService.h"
#import "WFXMLParser.h"
#import "WFXMLDocument.h"
#import "WFXMLElement.h"

// The static data needed by this test is kept in a separate file 
#import "TestXMLServiceData.m"

/* Test connector for the XML service object */
@interface TestXMLServiceConnector : NSObject <WFXMLServiceConnector> {
}
@end

@implementation TestXMLServiceConnector
- (void)requestWithXML:(WFXMLDocument *)document
              delegate:(id<WFXMLServiceConnectorDelegate>)delegate
{
    NSString *replyString = nil;
    WFXMLElement *reqElement;

    if (reqElement = [document.rootElement elementForName:@"compact_search_request"]) {
        WFXMLElement *query = [reqElement elementForName:@"search_item_query"];

        if ([query.stringValue isEqual:@"connError"]) {
            NSDictionary *userInfo = [NSDictionary
                dictionaryWithObject:@"Expected failure"
                              forKey:NSLocalizedDescriptionKey];
            [delegate connector:self
               didFailWithError:[NSError errorWithDomain:@"Unit Test"
                                                    code:1
                                                userInfo:userInfo]
                  transActionId:[reqElement.attributes
                                    objectForKey:@"transaction_id"]];
            return;
        }

        if ([reqElement elementForName:@"category_id"]) {
            if ([[reqElement.attributes objectForKey:@"round"] isEqual:@"0"])
                replyString = catReplyString;
            else if ([[reqElement.attributes objectForKey:@"round"] isEqual:@"1"])
                replyString = catSearchReplyString;
        }
        else {
            if ([[reqElement.attributes objectForKey:@"round"] isEqual:@"0"])
                replyString = searchReplyString;
            else if ([[reqElement.attributes objectForKey:@"round"] isEqual:@"1"])
                replyString = searchReplyString_1;
        }
    } else if (reqElement = [document.rootElement elementForName:@"map_request"]) {
        replyString = mapReplyString;
    } else if (reqElement = [document.rootElement elementForName:@"category_list_request"]) {
        replyString = catListReplyString;
    } else if (reqElement = [document.rootElement elementForName:@"search_desc_request"]) {
        replyString = searchDescReplyString;
    } else if (reqElement = [document.rootElement elementForName:@"route_request"]) {
        replyString = routeReplyString;
    } else if (reqElement = [document.rootElement elementForName:@"poi_info_request"]) {
        // Check if we should return an error
        WFXMLElement *query = [document.rootElement elementForName:@"itemid"];
        if ([query.stringValue isEqual:@"XXX:ERROR:XXX"])
            replyString = poiDetailErrorReplyString;
        else
            replyString = poiDetailReplyString;
    } else if (reqElement = [document.rootElement elementForName:@"search_position_desc_request"]) {
        replyString = searchPositionDescReplyString;
    }

    if ([reqElement.attributes objectForKey:@"language"])
        STAssertEqualStrings([reqElement.attributes objectForKey:@"language"],
                    [[NSLocale preferredLanguages] objectAtIndex:0],
                    @"");

    NSString *transActionId = [reqElement.attributes
        objectForKey:@"transaction_id"];

    if (![[WFXMLParser parserWithData:[[document XMLString]
                   dataUsingEncoding:NSUTF8StringEncoding]] parse])
    {
        NSDictionary *userInfo = [NSDictionary
            dictionaryWithObject:@"Invalid XML"
                          forKey:NSLocalizedDescriptionKey];

        [delegate connector:self
           didFailWithError:[NSError errorWithDomain:@"Unit Test"
                       code:0
                   userInfo:userInfo]
              transActionId:transActionId];

        return;
    }

    WFXMLDocument *replyDoc = [[WFXMLParser parserWithData:[replyString
                                         dataUsingEncoding:NSUTF8StringEncoding]]
                                         parse];
    // Replace test XML datas transaction ID with the correct one
    NSMutableDictionary *attr = [[[replyDoc.rootElement.children objectAtIndex:0] attributes] mutableCopy];
    [attr setObject:transActionId forKey:@"transaction_id"];
    
    [[replyDoc.rootElement.children objectAtIndex:0] setAttributes:attr];
    [attr release];
    [delegate connector:self didReceiveXML:replyDoc];
}

- (void)requestFile:(NSString *)fileName
           delegate:(id<WFXMLServiceConnectorDelegate>)delegate
      transActionId:(NSString *)Id
{
    NSData *data = [NSData dataWithBytes:imageData length:sizeof(imageData)];
    [delegate connector:self didReceiveFile:data transActionId:Id];
}
@end

/* Begin test class */
@interface TestXMLService : GTMTestCase <WFXMLServiceDelegate> {
    TestXMLServiceConnector *connector;
    WFXMLService *service;
    NSString *transActionId;
    NSString *routeId;
    NSMutableArray *results;
    UIImage *image;
    NSError *error;
    BOOL finished;
    BOOL shouldCancel;
}

@property (nonatomic,retain) NSString *transActionId;
@property (nonatomic,retain) NSString *routeId;
@property (nonatomic,retain) NSError *error;
@property (nonatomic,retain) UIImage *image;
@end

@implementation TestXMLService

@synthesize transActionId;
@synthesize routeId;
@synthesize error;
@synthesize image;

- (void)setUp
{
    connector = [[TestXMLServiceConnector alloc] init];
    error = nil;
    transActionId = nil;
    image = nil;
    shouldCancel = NO;

    service = [[WFXMLService alloc] init];
    service.delegate = self;
    service.connector = connector;
    results = [[NSMutableArray alloc] init];
}

- (void)tearDown
{
    [service release];
    [results release];
    [transActionId release];
    [error release];
}

- (void)testSimpleSearch
{
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };
    NSRange searchRange = {0, 50};

    [results removeAllObjects];

    finished = false;
    NSString *Id = [service searchWithString:@"otaniemi"
                                  coordinate:coord
                                 searchRange:searchRange];
    
    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertTrue([results count] == 12, @"got %d results", [results count]);
    
    NSDictionary *resultDict = [results objectAtIndex:0];
    STAssertEqualStrings([resultDict objectForKey:@"itemid"],
                         @"c:70002902:37:0:E", @"");
    STAssertEqualStrings([resultDict objectForKey:@"search_item_type"],
                         @"pointofinterest", @"");

    resultDict = [results objectAtIndex:11];
    STAssertEqualStrings([resultDict objectForKey:@"itemid"],
                         @"Xc:2ACC8230:11A8706E:0:E:144139:7", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Yliopistokirjakauppa Otaniemi", @"");
}

- (void)testIllFormattedSearch
{
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };

    NSArray *invalidStrings = [NSArray
        arrayWithObjects:@"<otaniemi", @"otaniemi>", @"otaniemi&", @"otaniemi\"", @"otaniemi'", nil];
    NSRange searchRange = {0, 50};

    for (NSString *searchString in invalidStrings) {
        [results removeAllObjects];
        finished = false;
        self.error = nil;

        NSString *Id = [service searchWithString:searchString
                                      coordinate:coord
                                     searchRange:searchRange];

        STAssertTrue(finished, @"");
        STAssertNULL(self.error, @"");
        STAssertEqualStrings(self.transActionId, Id, @"");
    }
}

- (void)testPoiDetailErrorReply
{
    [results removeAllObjects];
    self.error = nil;
    finished = false;
    
    [service searchPoiDetails:@"XXX:ERROR:XXX"
                         name:@"Yliopistokirjakauppa Otaniemi"];
    
    STAssertNotNULL(self.error, @"");
    NSString *errorStr = [self.error domain];
    NSInteger errorCode = [self.error code];
    STAssertEqualStrings(errorStr, @"Connection failed to database.", @"");
    STAssertTrue(errorCode == -1, @"Error code should be -1 but was %d instead", errorCode);
}

- (void) testPoiDetailsRequest
{
    [results removeAllObjects];
    finished = false;

    [service searchPoiDetails:@"Xc:2ACC8230:11A8706E:0:E:144139:7"
                         name:@"Yliopistokirjakauppa Otaniemi"];

    NSDictionary *resultDict = [[results objectAtIndex:0] objectForKey:@"info"];

    STAssertFalse(finished, @"");
    STAssertEqualStrings([[resultDict objectForKey:@"vis_zip_area"] objectForKey:@"value"], @"TAMPERE", @"");
    STAssertEqualStrings([[resultDict objectForKey:@"vis_zip_code"] objectForKey:@"value"], @"33900", @"");
}

- (void)testMapRequest
{
    WFBoundingBox bBox = { {60.185105, 24.813223}, {60.285105, 24.913223} };

    NSString *Id = [service mapImageWithBoundingBox:bBox size:CGSizeMake(5, 5)];

    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertNotNULL(image, @"");
}

- (void)testCategoryRequest
{
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };
    NSRange searchRange = {0, 50};

    [results removeAllObjects];
    finished = false;

    /* Category "18" means "Airport" */
    NSString *Id = [service searchWithCategory:@"18"
                                    coordinate:coord
                                   searchRange:searchRange];

    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertTrue([results count] == 4, @"got %d results", [results count]);

    NSDictionary *resultDict = [results objectAtIndex:0];
    STAssertEqualStrings([resultDict objectForKey:@"itemid"],
                         @"c:700031DE:37:0:E", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Helsinki-Malmin lentoasema, Malmin Lentoasema", @"");

    resultDict = [results objectAtIndex:2];
    STAssertEqualStrings([resultDict objectForKey:@"itemid"],
                         @"c:70001ECF:38:0:E", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Lappeenrannan lentoasema, Lentokentäntie 21", @"");
    
    // Also check that we got result from round 1 search
    resultDict = [results objectAtIndex:3];
    STAssertEqualStrings([resultDict objectForKey:@"itemid"],
                         @"c:6666:66:0:E", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Ye Olde Airport", @"");
}

- (void)testCategoryListRequest
{
    [results removeAllObjects];
    finished = false;

    NSString *Id = [service categoryRequestWithCrc:@"0"];

    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertTrue([results count] == 4, @"got %d results", [results count]);

    NSDictionary *resultDict = [results objectAtIndex:0];
    STAssertEqualStrings([resultDict objectForKey:@"cat_id"],
                         @"152", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"ATM", @"");

    resultDict = [results objectAtIndex:3];
    STAssertEqualStrings([resultDict objectForKey:@"cat_id"],
                         @"76", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Car dealer", @"");
}

- (void)testSearchDescRequest
{
    [results removeAllObjects];
    finished = false;

    NSString *Id = [service searchDescriptionRequestWithCrc:@"0"];

    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertTrue([results count] == 4, @"got %d results", [results count]);

    NSDictionary *resultDict = [results objectAtIndex:0];
    STAssertEqualStrings([resultDict objectForKey:@"image_name"],
                         @"search_heading_places", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Places", @"");

    resultDict = [results objectAtIndex:3];
    STAssertEqualStrings([resultDict objectForKey:@"image_name"],
                         @"search_heading_eniro_wo_text", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Eniro Företag", @"");
}

- (void)testRegionRequest
{
    [results removeAllObjects];
    finished = false;
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };
    
    NSString *Id = [service regionRequestWithCoordinate:coord];
    
    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertTrue([results count] == 2, @"got %d results", [results count]);
    
    NSDictionary *resultDict = [results objectAtIndex:0];
    STAssertEqualStrings([resultDict objectForKey:@"image_name"],
                         @"search_heading_eniro_wo_text", @"");
    STAssertEqualStrings([resultDict objectForKey:@"name"],
                         @"Eniro Keltaiset Sivut", @"");
    
    resultDict = [results objectAtIndex:1];
    STAssertEqualStrings([resultDict objectForKey:@"name_node"],
                         @"Suomi", @"");
    STAssertEqualStrings([resultDict objectForKey:@"top_region_type"],
                         @"country", @"");
    NSDictionary *bbox = [resultDict objectForKey:@"boundingbox"];
    STAssertEqualStrings([bbox objectForKey:@"east_lon"],
                         @"31.58671193", @"");
    STAssertEqualStrings([bbox objectForKey:@"south_lat"],
                         @"59.67527395", @"");
}

- (void) testRouteRequest
{
    [results removeAllObjects];
    finished = false;
    CLLocationCoordinate2D startCoord = { 60.185253, 24.814596 };
    CLLocationCoordinate2D endCoord = { 60.176989, 24.804215 };
    
    NSString *Id = [service routeRequestFrom:startCoord to:endCoord];
    
    STAssertTrue(finished, @"");
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertEqualStrings(self.routeId, @"D0CA_49670ABA", @"");
}

- (void)testTransactionCancel
{
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };
    WFBoundingBox bBox = { {60.185105, 24.813223}, {60.285105, 24.913223} };
    NSRange searchRange = {0, 50};

    shouldCancel = YES;

    /* Normal search */
    finished = NO;
    [results removeAllObjects];
    NSString *Id = [service searchWithString:@"otaniemi"
                                  coordinate:coord
                                 searchRange:searchRange];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertFalse(finished, @"");
    STAssertTrue([results count] == 0, @"Shouldn't have received any results");

    /* POI detail request */
    finished = NO;
    [results removeAllObjects];
    Id = [service searchPoiDetails:@"Xc:2ACC8230:11A8706E:0:E:144139:7"
                                        name:@"Yliopistokirjakauppa Otaniemi"];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertFalse(finished, @"");
    STAssertTrue([results count] == 0, @"Shouldn't have received any results");

    /* Map image request */
    self.image = nil;
    Id = [service mapImageWithBoundingBox:bBox size:CGSizeMake(5, 5)];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertNULL(self.image, @"");

    /* Category request */
    finished = NO;
    [results removeAllObjects];
    Id = [service searchWithCategory:@"18"
                          coordinate:coord
                         searchRange:searchRange];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertFalse(finished, @"");
    STAssertTrue([results count] == 0, @"Shouldn't have received any results");

    /* Category list request */
    finished = NO;
    [results removeAllObjects];
    Id = [service categoryRequestWithCrc:@"0"];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertFalse(finished, @"");
    STAssertTrue([results count] == 0, @"Shouldn't have received any results");

    /* Search description request */
    finished = NO;
    [results removeAllObjects];
    Id = [service searchDescriptionRequestWithCrc:@"0"];
    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertFalse(finished, @"");
    STAssertTrue([results count] == 0, @"Shouldn't have received any results");

    shouldCancel = NO;
}

- (void)testConnectionError
{
    self.error = nil;
    CLLocationCoordinate2D coord = { 60.185105, 24.813223 };
    NSRange searchRange = {0, 50};

    NSString *Id = [service searchWithString:@"connError"
                                  coordinate:coord
                                 searchRange:searchRange];

    STAssertEqualStrings(self.transActionId, Id, @"");
    STAssertNotNULL(error, @"");
}

- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    self.error = anError;
    self.transActionId = Id;
}

- (void)service:(WFXMLService *)aService didReceiveCategory:(NSDictionary *)items
            crc:(NSString *)crc transActionId:(NSString *)trId
{
    self.transActionId = trId;
    if (shouldCancel) {
        [aService cancelTransAction:trId];
        return;
    }
    [results addObject:items];
}

- (void)service:(WFXMLService *)aService didReceiveItem:(NSDictionary *)item
    transActionId:(NSString *)Id
{
    self.transActionId = Id;
    if (shouldCancel) {
        [aService cancelTransAction:Id];
        return;
    }
    [results addObject:item];
}

- (void)service:(WFXMLService *)aService didReceiveDetail:(NSDictionary *)item
    transActionId:(NSString *)Id
{
    self.transActionId = Id;
    if (shouldCancel) {
        [aService cancelTransAction:Id];
        return;
    }
    [results addObject:item];
}

- (void)service:(WFXMLService *)service didFinishTransAction:(NSString *)Id
{
    STAssertEqualStrings(self.transActionId, Id, @"");
    finished = true;
}

- (void)service:(WFXMLService *)aService didReceiveMapImage:(UIImage *)anImage
    transActionId:(NSString *)Id
{
    self.transActionId = Id;
    if (shouldCancel) {
        [aService cancelTransAction:Id];
        return;
    }
    self.image = anImage;
}

- (void) service:(WFXMLService *)aService didReceiveRoute:(NSString *)routeId
   transActionId:(NSString *)Id
{
    self.transActionId = Id;
    self.routeId = routeId;
    finished = true;
}

@end
