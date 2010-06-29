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

#import "WFXMLService.h"
#import "WFXMLParser.h"
#import "WFXMLDocument.h"
#import "WFXMLElement.h"
#import "constants.h"

/* Ugly hack to allow ANY certificate for https */
@implementation NSURLRequest(NSHTTPURLRequestHack)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
	return YES;
}
@end

/**********************************************************************
 *
 * An HTTP connector for the XML service class
 *
 *********************************************************************/
@interface WFXMLServiceHTTPConnector : NSObject <WFXMLServiceConnector> {
@private
    NSMutableDictionary *activeConnections;
}
@end

@implementation WFXMLServiceHTTPConnector

#define DEFAULT_RESULT_AMOUNT 100


- (WFXMLServiceHTTPConnector *)init
{
    if (self = [super init]) {
        activeConnections = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [activeConnections release];
    [super dealloc];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [activeConnections removeObjectForKey:[connection description]];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSMutableData *connData = [[activeConnections
                                   objectForKey:[connection description]] objectForKey:@"data"];

    [connData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableData *connData = [[activeConnections
                                   objectForKey:[connection description]] objectForKey:@"data"];
    [connData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *connInfo = [activeConnections
                                 objectForKey:[connection description]];
    NSData *data = [connInfo objectForKey:@"data"];
    id<WFXMLServiceConnectorDelegate> delegate = [connInfo objectForKey:@"delegate"];

    if ([[connInfo objectForKey:@"type"] isEqual:@"xml"]) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [delegate connector:self
                  didReceiveXML:[[WFXMLParser parserWithData:data] parse]];
        [pool release];
    }
    else if ([[connInfo objectForKey:@"type"] isEqual:@"map"])
        [delegate connector:self
                  didReceiveFile:data
                  transActionId:[connInfo objectForKey:@"transActionId"]];

    [activeConnections removeObjectForKey:[connection description]];
}

- (void)requestWithXML:(WFXMLDocument *)document
              delegate:(id<WFXMLServiceConnectorDelegate>)delegate
{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest
                                          requestWithURL:[NSURL
                                                       URLWithString:[STR_BASEURL 
                                                       stringByAppendingPathComponent:@"xmlfile"]]];
    [urlRequest setHTTPBody:[[document XMLString] dataUsingEncoding:NSUTF8StringEncoding]];
    [urlRequest setHTTPMethod:@"POST"];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:urlRequest
                                             delegate:self];

    NSMutableData *connData = [NSMutableData data];
    NSDictionary *connInfo = [NSDictionary
                                 dictionaryWithObjects:[NSArray arrayWithObjects:conn, delegate,
                                                                connData, @"xml", nil]
                                 forKeys:[NSArray arrayWithObjects:[conn description],
                                                  @"delegate", @"data", @"type", nil]];
    [activeConnections setObject:connInfo forKey:[conn description]];
}

- (void)requestFile:(NSString *)fileName
           delegate:(id<WFXMLServiceConnectorDelegate>)delegate
      transActionId:(NSString *)Id
{
    NSURLRequest *urlRequest = [NSURLRequest
                                   requestWithURL:[NSURL
                                                      URLWithString:[STR_BASEURL stringByAppendingPathComponent:fileName]]];

    NSURLConnection *conn = [NSURLConnection connectionWithRequest:urlRequest
                                             delegate:self];

    NSMutableData *connData = [NSMutableData data];
    NSDictionary *connInfo = [NSDictionary
                                 dictionaryWithObjects:[NSArray arrayWithObjects:conn, delegate,
                                                                connData, @"map", Id, nil]
                                 forKeys:[NSArray arrayWithObjects:[conn description],
                                                  @"delegate", @"data", @"type", @"transActionId", nil]];
    [activeConnections setObject:connInfo forKey:[conn description]];
}

- (void)requestFromAddress:(NSString *)httpAddress
                  delegate:(id<WFXMLServiceConnectorDelegate>)delegate
             transActionId:(NSString *)Id
{
    NSURLRequest *urlRequest = [NSURLRequest
                                requestWithURL:[NSURL
                                                URLWithString:httpAddress]];
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:urlRequest
                                                          delegate:self];
    
    NSMutableData *connData = [NSMutableData data];
    NSDictionary *connInfo = [NSDictionary
                              dictionaryWithObjects:[NSArray arrayWithObjects:conn, delegate,
                                                     connData, @"map", Id, nil]
                              forKeys:[NSArray arrayWithObjects:[conn description],
                                       @"delegate", @"data", @"type", @"transActionId", nil]];
    [activeConnections setObject:connInfo forKey:[conn description]];
}

@end

/**********************************************************************
 *
 * Implementation of the WFXMLService class starts here
 *
 *********************************************************************/
@interface WFXMLService()
- (NSString *)searchWithString:(NSString *)queryString
                    categoryId:(NSString *)categoryId
                    coordinate:(CLLocationCoordinate2D)coordinate
                   searchRound:(int)round
                       reuseId:(NSString *)trId
                    searchRange:(NSRange)searchRange;
@end

@implementation WFXMLService

@synthesize delegate;
@synthesize connector;

+ (WFXMLService *)service
{
    return [[[WFXMLService alloc] init] autorelease];
}

- (WFXMLService *)init
{
    if (self = [super init]) {
        connector = [[WFXMLServiceHTTPConnector alloc] init];
        requestMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/* 
 * WFXMLServiceConnectorDelegate methods
 */
- (void)connector:(id)connector didFailWithError:(NSError *)error
    transActionId:(NSString *)Id
{
    [delegate service:self didFailWithError:error transActionId:Id];
}

- (void)connector:(id)aConnector didReceiveXML:(WFXMLDocument *)document
{
    WFXMLElement *reply;
    BOOL hasDictionaryData = NO;
    
    // First check that operation succeeded. Only error replies have status_code
    if (reply = [document.rootElement elementForName:@"status_code"]) {
        // Something went sour. Handle error
        WFXMLElement *temp = [document.rootElement.children objectAtIndex:0];
        NSString *trId = [temp.attributes objectForKey:@"transaction_id"];
        NSInteger errorCode = [[reply stringValue] intValue];
        NSString *statusMsg = [[document.rootElement elementForName:@"status_message"] stringValue];
        if (!statusMsg)
            statusMsg = @"Network error";
        
        NSError *err = [NSError errorWithDomain:statusMsg code:errorCode userInfo:nil];
        
        [delegate service:self didFailWithError:err transActionId:trId];
        
        if (trId && ![trId isEqual:@""])
            [requestMap removeObjectForKey:trId];
        return;
    }
    
    /* Map reply is special because it contains only a reference to the actual
     * data (which means we need to fire up another request) */
    if (reply = [document.rootElement elementForName:@"map_reply"]) {
        NSString *mapPath = [reply elementForName:@"href"].stringValue;
        NSString *trId = [reply.attributes objectForKey:@"transaction_id"];

        if (![requestMap objectForKey:trId])
            return;

        if ([delegate
            respondsToSelector:@selector(service:didReceiveMapImage:transActionId:)])
        {
            [aConnector requestFile:mapPath delegate:self transActionId:trId];
        }

        if (trId && ![trId isEqual:@""])
            [requestMap removeObjectForKey:trId];
        return;
    }
    
    if (reply = [document.rootElement elementForName:@"route_reply"]) {
        NSString *routeId = [reply.attributes objectForKey:@"route_id"];
        NSString *trId = [reply.attributes objectForKey:@"transaction_id"];
        
        if (![requestMap objectForKey:trId])
            return;
        
        if ([delegate
             respondsToSelector:@selector(service:didReceiveRoute:routeData:transActionId:)])
        {
            WFXMLElement *header = [document.rootElement elementForName:@"route_reply_header"];
            NSMutableDictionary *items = [NSMutableDictionary dictionaryWithCapacity:[header.children count]];
            
            for (WFXMLElement *item in header.children) {
                if (item.stringValue != nil && item.name != nil)
                    [items setObject:item.stringValue forKey:item.name];
            }
            
            [delegate service:self didReceiveRoute:routeId routeData:items transActionId:trId];
        }
        
        if (trId && ![trId isEqual:@""])
            [requestMap removeObjectForKey:trId];
        return;
    }
    
    if ((reply = [document.rootElement elementForName:@"category_list_reply"]) ||
        (reply = [document.rootElement elementForName:@"search_desc_reply"])) {
        NSArray *resultItems;
        NSString *trId = [reply.attributes objectForKey:@"transaction_id"];
        NSString *listCrc = [reply.attributes objectForKey:@"crc"];

        if (![requestMap objectForKey:trId])
            return;

        if ([document.rootElement elementForName:@"category_list_reply"])
            resultItems = [document.rootElement elementsForName:@"cat"];
        else
            resultItems = [reply elementsForName:@"search_hit_type"];
        
        if ([delegate respondsToSelector:@selector(service:didReceiveCategory:crc:transActionId:)]) {
            for (WFXMLElement *element in resultItems) {
                NSMutableDictionary *items = [NSMutableDictionary dictionaryWithCapacity:[element.children count]];
                
                for (WFXMLElement *item in element.children) {
                    [items setObject:item.stringValue forKey:item.name];
                }
                [items addEntriesFromDictionary:element.attributes];
                [delegate service:self didReceiveCategory:items crc:listCrc transActionId:trId];
            }
        }

        /* If the request is 'nil' here, the transaction was cancelled while
         * processing the results */
        if (![requestMap objectForKey:trId])
            return;

        if ([delegate
             respondsToSelector:@selector(service:didFinishTransAction:)])
        {
            [delegate service:self didFinishTransAction:trId];
        }
        
        if (trId && ![trId isEqual:@""])
            [requestMap removeObjectForKey:trId];
        return;
    }
                
    if (reply = [document.rootElement elementForName:@"poi_info_reply"]) {
        NSString *trId = [reply.attributes objectForKey:@"transaction_id"];
        NSArray *infoFields = [document.rootElement elementsForName:@"info_field"];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];

        if (![requestMap objectForKey:trId])
            return;

        // Add mandatory info
        NSString *itemName = [[reply elementForName:@"itemName"] stringValue];
        NSString *itemType = [[reply elementForName:@"typeName"] stringValue];
        [dict setObject:itemName forKey:@"itemName"];
        [dict setObject:itemType forKey:@"typeName"];

        // extract all info fields
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        for (WFXMLElement *field in infoFields) {
            NSString *t = [field.attributes objectForKey:@"info_type"];
            if ([t isEqual:@"dont_show"])
                continue;

            NSDictionary *info_f = [NSDictionary
                dictionaryWithObjectsAndKeys:
                    [[field elementForName:@"fieldValue"] stringValue],
                    @"value",
                    [[field elementForName:@"fieldName"] stringValue],
                    @"name",
                    nil];
            [info setObject:info_f forKey:t];
        }
        [dict setObject:info forKey:@"info"];

        [delegate service:self didReceiveDetail:dict transActionId:trId];
        if (trId && ![trId isEqual:@""])
            [requestMap removeObjectForKey:trId];
        return;
        // don't call didFinishTransaction, it reloads the main list.
    }
    
    NSMutableArray *resultItems = nil;

    if (reply = [document.rootElement elementForName:@"compact_search_reply"]) {
        resultItems = [NSMutableArray arrayWithArray:[reply elementsForName:@"search_item"]];
        // Only search requests have some sensible data as dictionary in requestMap
        hasDictionaryData = YES;
    }
    
    if (nil == reply && (reply = [document.rootElement elementForName:@"search_position_desc_reply"])) {
        // Add data providers
        resultItems = [NSMutableArray arrayWithArray:[reply elementsForName:@"search_hit_type"]];
        // And top region
        [resultItems addObjectsFromArray:[reply elementsForName:@"top_region"]];
    }

    NSString *trId = [reply.attributes objectForKey:@"transaction_id"];

    if (![requestMap objectForKey:trId])
        return;

    if ([delegate
        respondsToSelector:@selector(service:didReceiveItem:transActionId:)])
    {

        for (WFXMLElement *element in resultItems) {
            NSMutableDictionary *items = [NSMutableDictionary dictionary];
            for (WFXMLElement *item in element.children) {
                if (item.stringValue == nil || [item.stringValue length] == 0) {
                    // Item might have attributes so check those
                    if (item.attributes == nil || [item.attributes count] == 0)
                        break;
                    // There are attributes, add those
                    [items setObject:item.attributes forKey:item.name];
                }
                else
                    [items setObject:item.stringValue forKey:item.name];
            }
            [items addEntriesFromDictionary:element.attributes];
            [delegate service:self didReceiveItem:items transActionId:trId];
        }

    }

    NSDictionary *req = [requestMap objectForKey:trId];
    /* If req is 'nil' here it means that the transaction got cancelled while
     * we were processing the results, so we just bail out */
    if (!req)
        return;
    
    /* If there exists a round 0 entry for this transaction, fire up a
     * round 1 search instead of finishing. */
    if (hasDictionaryData && [req objectForKey:@"round"] && [[req objectForKey:@"round"] intValue] == 0) {
        NSRange searchRange = {[[req objectForKey:@"start_index"] intValue],
                               [[req objectForKey:@"max_hits"] intValue]};
        [self searchWithString:[req objectForKey:@"query"]
                    categoryId:[req objectForKey:@"cat_id"]
                    coordinate:[[req objectForKey:@"location"] coordinate]
                   searchRound:1
                       reuseId:trId
                   searchRange:searchRange];
        /* Don't remove the request from request map since the same
         * transaction id is reused for the new transaction */
        return;
    } else {
        if ([delegate
            respondsToSelector:@selector(service:didFinishTransAction:)])
            [delegate service:self didFinishTransAction:trId];
    }
    if (trId && ![trId isEqual:@""])
        [requestMap removeObjectForKey:trId];
}




- (void)connector:(id)connector didReceiveFile:(NSData *)fileData
    transActionId:(NSString *)Id
{

    if ([delegate respondsToSelector:@selector(service:didReceiveMapImage:transActionId:)]) {
        [delegate service:self didReceiveMapImage:[UIImage imageWithData:fileData]
            transActionId:Id];
    }

}

/* Cancel transaction with the id transActionId. If there is no such
 * transaction, do nothing. */
- (void)cancelTransAction:(NSString *)transActionId
{
    /* For now, just remove the transaction so that it will be ignored */
    [requestMap removeObjectForKey:transActionId];
}

/*
 * Build an XML query skeleton that looks like this:
 *
 * <?xml version='1.0' encoding='UTF-8' ?>
 * <!DOCTYPE isab-mc2 SYSTEM 'isab-mc2.dtd'>
 * <isab-mc2>
 *     <auth client_type="ps1-iphone">
 *         <auth_user>wfiphoneps</auth_user>
 *         <auth_passwd>G5x0nuW8</auth_passwd>
 *     </auth>
 * </isab-mc2>
 */
- (WFXMLDocument *)XMLQuerySkeleton
{
    WFXMLDocument *query = [[WFXMLDocument alloc] init];
    query.rootElement = [WFXMLElement elementWithName:@"isab-mc2"];

    /* Add auth block */
    [query.rootElement
     addChild:[WFXMLElement elementWithName:@"auth"
                                   children:[NSArray
                                             arrayWithObjects:[WFXMLElement elementWithName:@"auth_user"
                                                                                stringValue:STR_XMLUSER],
                                             [WFXMLElement elementWithName:@"auth_passwd"
                                                               stringValue:STR_XMLPASSWD],
                                             nil]
                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                             STR_CLIENTTYPE, @"client_type", nil]]];

    return [query autorelease];
}

- (NSString *)uuid
{
    return [NSString stringWithFormat:@"id%d", rand()];
}

/*
 * Method formats the image name as it should appear on server and downloads it.
 */
- (NSString *)fetchImageWithName:(NSString *)imageName
{
    NSString *trId = [self uuid];
    
    NSString *imagePath = [NSString stringWithFormat:@"/TMap/B%@.png",imageName];
    
    [requestMap setObject:imagePath forKey:trId];
    [connector requestFile:imagePath delegate:self transActionId:trId];
    
    return trId;
}

- (NSString *)fetchImageFromAddress:(NSString *)httpAddress
{
    NSString *trId = [self uuid];
    
    [requestMap setObject:httpAddress forKey:trId];
    [connector requestFromAddress:httpAddress delegate:self transActionId:trId];
    
    return trId;
}

/*
 * Build a category list request with the following structure and return the
 * transaction ID.
 *
 * <category_list_request transaction_id=\"id\"
 *                        crc=\"CRC\"
 *                        language=\"language\">
 * </category_list_request>
 *
 */
- (NSString *)categoryRequestWithCrc:(NSString *)crc
{
    WFXMLDocument *XMLQuery = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];
    
    /* Create a search request block add it to the document */

    WFXMLElement *searchRequest = [WFXMLElement
        elementWithName:@"category_list_request"
               children:nil
             attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                [[NSLocale preferredLanguages] objectAtIndex:0], @"language",
                crc, @"crc",
                trId, @"transaction_id", nil]];


    [XMLQuery.rootElement addChild:searchRequest];

    [requestMap setObject:XMLQuery forKey:trId];
    [connector requestWithXML:XMLQuery delegate:self];
    return trId;
}

/*
 * Build a search description request with the following structure and return
 * the transaction ID.
 *
 * <search_desc_request language="...OS language..." transaction_id="id"
 *     crc="crc" desc_version="1"/>
 *
 */
- (NSString *)searchDescriptionRequestWithCrc:(NSString *)crc
{
    WFXMLDocument *XMLQuery = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];

    WFXMLElement *searchDescRequest = [WFXMLElement
        elementWithName:@"search_desc_request"
               children:nil
             attributes:[NSDictionary
                dictionaryWithObjectsAndKeys:
                    [[NSLocale preferredLanguages] objectAtIndex:0], @"language",
                    trId, @"transaction_id",
                    crc, @"crc",
                    @"1", @"desc_version", nil]];

    [XMLQuery.rootElement addChild:searchDescRequest];

    [requestMap setObject:XMLQuery forKey:trId];
    [connector requestWithXML:XMLQuery delegate:self];
    return trId;
}

/*
 * Build a search position description request with the following structure
 * and return the transaction ID.
 *
 * <search_position_desc_request language="...OS language..." transaction_id="id">
 *    <position_item position_system="WGS84Deg">
 *        <lat>...coordinate.latitude...</lat>
 *        <lon>...coordinate.longitude...</lon>
 *    </position_item>
 * </search_position_desc_request>
 *
 */
- (NSString *)regionRequestWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    WFXMLDocument *XMLQuery = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];
    
    WFXMLElement *positionRequest = [WFXMLElement
                                     elementWithName:@"search_position_desc_request"
                                     children:nil
                                     attributes:[NSDictionary
                                                 dictionaryWithObjectsAndKeys:
                                                 [[NSLocale preferredLanguages] objectAtIndex:0], @"language",
                                                 trId, @"transaction_id", nil]];
    
    [XMLQuery.rootElement addChild:positionRequest];
    
    /* Add position_item */
    WFXMLElement *lat = [WFXMLElement
                         elementWithName:@"lat"
                         stringValue:[NSString stringWithFormat:@"%f",
                                      coordinate.latitude]];
    WFXMLElement *lon = [WFXMLElement
                         elementWithName:@"lon"
                         stringValue:[NSString stringWithFormat:@"%f",
                                      coordinate.longitude]];
    
    [positionRequest addChild:[WFXMLElement
                               elementWithName:@"position_item"
                               children:[NSArray arrayWithObjects:lat, lon, nil]
                               attributes:[NSDictionary dictionaryWithObject:@"WGS84Deg"
                                                                      forKey:@"position_system"]]];
    
    [requestMap setObject:XMLQuery forKey:trId];
    [connector requestWithXML:XMLQuery delegate:self];
    return trId;
}


/*
 * Build a route request with the following structure and return the transaction ID.
 * Tags previous_route_id and reroute_reason are included only if oldRouteId is set.
 *
 * <route_request transaction_id="id">
 *    <route_request_header previous_route_id="...oldRouteId..." reroute_reason="user_request">
 *        <route_preferences route_description_type="compact" route_items="false">
 *            <route_settings route_vehicle="passengercar">
 *                <language>...OS language...</language>
 *            </route_settings>
 *        </route_preferences>
 *    </route_request_header>
 *    <routeable_item_list>
 *        <position_item position_system="WGS84Deg">
 *            <lat>...startCoordinate.latitude...</lat>
 *            <lon>...startCoordinate.longitude...</lon>
 *        </position_item>
 *    </routeable_item_list>
 *    <routeable_item_list>
 *        <position_item position_system="WGS84Deg">
 *            <lat>...endCoordinate.latitude...</lat>
 *            <lon>...endCoordinate.longitude...</lon>
 *        </position_item>
 *    </routeable_item_list>
 * </route_request>
 *
 */
- (NSString *)routeRequestFrom:(CLLocationCoordinate2D)startCoordinate
                            to:(CLLocationCoordinate2D)endCoordinate
                     routeType:(routingType)routeType
                    oldRouteId:(NSString *)oldRouteId
{
    WFXMLDocument *XMLQuery = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];
    NSString *routeTypeStr;
    
    WFXMLElement *routeRequest = [WFXMLElement
                                  elementWithName:@"route_request"
                                  children:nil
                                  attributes:[NSDictionary dictionaryWithObject:trId
                                                                         forKey:@"transaction_id"]];
    
    [XMLQuery.rootElement addChild:routeRequest];
    
    // Add route request header
    WFXMLElement *routeHeader;
    if (oldRouteId && ![oldRouteId isEqual:@""])
        routeHeader = [WFXMLElement
                       elementWithName:@"route_request_header"
                       children:nil
                       attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                   oldRouteId, @"previous_route_id",
                                   @"user_request", @"reroute_reason", nil]];
    else
        routeHeader = [WFXMLElement
                       elementWithName:@"route_request_header"
                       children:nil
                       attributes:nil];
    
    [routeRequest addChild:routeHeader];
    
    WFXMLElement *routePreferences = [WFXMLElement
                                      elementWithName:@"route_preferences"
                                      children:nil
                                      attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"compact", @"route_description_type",
                                                  @"false", @"route_items", nil]];
    
    [routeHeader addChild:routePreferences];
    
    if (carRoute == routeType)
        routeTypeStr = @"passengercar";
    else
        routeTypeStr = @"pedestrian";
    
    WFXMLElement *routeSettings = [WFXMLElement
                                   elementWithName:@"route_settings"
                                   children:nil
                                   attributes:[NSDictionary dictionaryWithObject:routeTypeStr
                                                                          forKey:@"route_vehicle"]];
    
    [routePreferences addChild:routeSettings];
    [routeSettings addChild:[WFXMLElement
                             elementWithName:@"language"
                             stringValue:[[NSLocale preferredLanguages] objectAtIndex:0]]];
    
    // Add route start position
    WFXMLElement *routeStart = [WFXMLElement
                                elementWithName:@"routeable_item_list"
                                children:nil
                                attributes:nil];
    
    [routeRequest addChild:routeStart];
    
    // Add start position_item
    WFXMLElement *startLat = [WFXMLElement
                              elementWithName:@"lat"
                              stringValue:[NSString stringWithFormat:@"%f",
                                           startCoordinate.latitude]];
    WFXMLElement *startLon = [WFXMLElement
                              elementWithName:@"lon"
                              stringValue:[NSString stringWithFormat:@"%f",
                                           startCoordinate.longitude]];
    
    [routeStart addChild:[WFXMLElement
                          elementWithName:@"position_item"
                          children:[NSArray arrayWithObjects:startLat, startLon, nil]
                          attributes:[NSDictionary dictionaryWithObject:@"WGS84Deg"
                                                                 forKey:@"position_system"]]];
    
    // Add route end position
    WFXMLElement *routeEnd = [WFXMLElement
                              elementWithName:@"routeable_item_list"
                              children:nil
                              attributes:nil];
    
    [routeRequest addChild:routeEnd];
    
    // Add end position_item
    WFXMLElement *endLat = [WFXMLElement
                            elementWithName:@"lat"
                            stringValue:[NSString stringWithFormat:@"%f",
                                         endCoordinate.latitude]];
    WFXMLElement *endLon = [WFXMLElement
                            elementWithName:@"lon"
                            stringValue:[NSString stringWithFormat:@"%f",
                                         endCoordinate.longitude]];
    
    [routeEnd addChild:[WFXMLElement
                        elementWithName:@"position_item"
                        children:[NSArray arrayWithObjects:endLat, endLon, nil]
                        attributes:[NSDictionary dictionaryWithObject:@"WGS84Deg"
                                                               forKey:@"position_system"]]];
    
    [requestMap setObject:XMLQuery forKey:trId];
    [connector requestWithXML:XMLQuery delegate:self];
    return trId;
}


/* 
 * A search wrapper that initiates a freetext search with search round 0.
 */
- (NSString *)searchWithString:(NSString *)queryString
                    coordinate:(CLLocationCoordinate2D)coordinate
                    searchRange:(NSRange)searchRange
{
    return [self searchWithString:queryString
                       categoryId:nil
                       coordinate:coordinate
                      searchRound:0
                          reuseId:nil
                       searchRange:searchRange];
}

/*
 * A search wrapper that initiates a category search with round 0.
 */
- (NSString *)searchWithCategory:(NSString *)categoryId
                      coordinate:(CLLocationCoordinate2D)coordinate
                      searchRange:(NSRange)searchRange
{
    return [self searchWithString:nil
                       categoryId:categoryId
                       coordinate:coordinate
                      searchRound:0
                          reuseId:nil
                       searchRange:searchRange];
}

/*
 * Build a compact search request with the following structure and return
 * the transaction ID.
 *
 * - If searching with a free text word, categoryId should be nil or empty
 *   string.
 * - If searching for category items, queryString should include the category
 *   name. Round 1 search is done with this name after round 0.
 *
 * searchRound and reuseId are used internally when performing the two-phase
 * freetext search.
 *
 * <compact_search_request transaction_id="...ID..."
 *                         start_index="...searchRange.location..."
 *                         end_index="...searchRange.location+searchRange.length..."
 *                         max_hits="...searchRange.length..."
 *                         language="...OS language..."
 *                         round="...round..."
 *                         heading="-1"
 *                         uin="0"
 *                         version="1">
 *
 *    <search_item_query>...queryString...</search_item_query>
 *    <category_id>...categoryId...</category_id>
 *    <position_item position_system="WGS84Deg">
 *        <lat>...coordinate.latitude...</lat>
 *        <lon>...coordinate.longitude...</lon>
 *    </position_item>
 * </compact_search_request>
 * 
 */
- (NSString *)searchWithString:(NSString *)queryString
                    categoryId:(NSString *)categoryId
                    coordinate:(CLLocationCoordinate2D)coordinate
                   searchRound:(int)round
                       reuseId:(NSString *)trId
                    searchRange:(NSRange)searchRange
{
    NSString *startStr;
    NSString *endStr;
    NSString *maxStr;
    WFXMLDocument *XMLQuery = [self XMLQuerySkeleton];

    if (trId == nil)
        trId = [self uuid];
    
    if (searchRange.location < 0)
        searchRange.location = 0;
    
    startStr = [NSString stringWithFormat:@"%d", searchRange.location];
    
    if (searchRange.length < 0)
        searchRange.length = DEFAULT_RESULT_AMOUNT;
    
    endStr = [NSString stringWithFormat:@"%d", searchRange.location + searchRange.length];
    maxStr = [NSString stringWithFormat:@"%d", searchRange.length];
    
    // Create a expand request block add it to the document
    WFXMLElement *searchRequest =
    [WFXMLElement elementWithName:@"compact_search_request"
                         children:nil
                       attributes:[NSDictionary 
                                   dictionaryWithObjects: [NSArray arrayWithObjects:trId,
                                                           startStr,
                                                           endStr,
                                                           maxStr,
                                                           [[NSLocale preferredLanguages] objectAtIndex:0],
                                                           [[NSNumber numberWithInt:round] stringValue],
                                                           @"-1",
                                                           STR_XMLUIN,
                                                           @"1", nil]
                                   forKeys:               [NSArray arrayWithObjects:@"transaction_id",
                                                           @"start_index",
                                                           @"end_index",
                                                           @"max_hits",
                                                           @"language",
                                                           @"round",
                                                           @"heading",
                                                           @"uin",
                                                           @"version", nil]]];
    
    [XMLQuery.rootElement addChild:searchRequest];

    if (nil != categoryId && ![categoryId isEqual:@""]) {
        // Do category search. Don't fill search_item_query with the category name
        [searchRequest addChild:[WFXMLElement
                                 elementWithName:@"search_item_query"]];
        [searchRequest addChild:[WFXMLElement
                                 elementWithName:@"category_id" stringValue:categoryId]];
    }
    else {
        // Remove all XML special characters from the query
        queryString = [self urlencodeString:queryString];
        
        [searchRequest addChild:[WFXMLElement
                                 elementWithName:@"search_item_query" stringValue:queryString]];
    }
    

    /* Add position_item to the proximity_query block */
    WFXMLElement *lat = [WFXMLElement
                         elementWithName:@"lat"
                         stringValue:[NSString stringWithFormat:@"%f",
                                      coordinate.latitude]];
    WFXMLElement *lon = [WFXMLElement
                         elementWithName:@"lon"
                         stringValue:[NSString stringWithFormat:@"%f",
                                      coordinate.longitude]];
    
    [searchRequest addChild:[WFXMLElement
                             elementWithName:@"position_item"
                             children:[NSArray arrayWithObjects:lat, lon, nil]
                             attributes:[NSDictionary dictionaryWithObject:@"WGS84Deg"
                                                                    forKey:@"position_system"]]];
    
    /* Only save the search parameters if they are needed for the two-stage
     * search (i.e. when performing a freetext search) */
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                 longitude:coordinate.longitude];
    NSMutableDictionary *reqDict = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:round], @"round",
            loc, @"location",
            startStr, @"start_index",
            maxStr, @"max_hits", nil];

    [loc release];

    if (queryString)
        [reqDict setObject:queryString forKey:@"query"];
    if (categoryId)
        [reqDict setObject:categoryId forKey:@"cat_id"];
    
    [requestMap setObject:reqDict forKey:trId];
    [connector requestWithXML:XMLQuery delegate:self];

    return trId;
}

/*
 * Build a map request with the following structure and return the result of
 * the request.
 *
 * <map_request transaction_id="1">
 *     <map_request_header image_width="320" image_height="460">
 *         <boundingbox position_sytem="WGS84Deg"
 *             north_lat="60.185105" west_lon="24.813223"
 *             south_lat="60.285105" east_lon="24.913223"/>
 *     </map_request_header>
 * </map_request>
 */
- (NSString *)mapImageWithBoundingBox:(WFBoundingBox)bBox size:(CGSize)size
{
    WFXMLDocument *query = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];

    /* Create the map bounding box, SYTEM IS NOT A TYPO */
    NSArray *keys = [NSArray arrayWithObjects:@"position_sytem", @"north_lat",
                             @"west_lon", @"south_lat", @"east_lon", nil];
    NSArray *values = [NSArray arrayWithObjects:@"WGS84Deg",
                               [NSString stringWithFormat:@"%lf",
                                         bBox.upperLeft.latitude],
                               [NSString stringWithFormat:@"%lf",
                                         bBox.upperLeft.longitude],
                               [NSString stringWithFormat:@"%lf",
                                         bBox.lowerRight.latitude],
                               [NSString stringWithFormat:@"%lf",
                                         bBox.lowerRight.longitude],
                               nil];
    WFXMLElement *boundingbox = [WFXMLElement
                                    elementWithName:@"boundingbox"
                                    children:nil
                                    attributes:[NSDictionary dictionaryWithObjects:values
                                                             forKeys:keys]];

    /* Create map_request_header block and add boundingbox to it */
    keys = [NSArray arrayWithObjects:@"image_width", @"image_height", @"showPOI", nil];
    values = [NSArray
                 arrayWithObjects:[NSString stringWithFormat:@"%d", (int)size.width],
                 [NSString stringWithFormat:@"%d", (int)size.height], @"false",
                 nil];
    WFXMLElement *map_request_header = [WFXMLElement
                                           elementWithName:@"map_request_header"
                                           children:[NSArray arrayWithObject:boundingbox]
                                           attributes:[NSDictionary dictionaryWithObjects:values
                                                                    forKeys:keys]];

    /* Create map_request block and add map_request_header to it */
    WFXMLElement *map_request = [WFXMLElement
                                    elementWithName:@"map_request"
                                    children:[NSArray arrayWithObject:map_request_header]
                                    attributes:[NSDictionary dictionaryWithObject:trId
                                                             forKey:@"transaction_id"]];

    [query.rootElement addChild:map_request];

    [requestMap setObject:query forKey:trId];
    [connector requestWithXML:query delegate:self];

    return trId;
}


/*
 * Build a Poi details request with the following structure and return the result of
 * the request.
 *
 * <poi_info_request transaction_id=/"tr_id/">
 *         <search_item>
 *             <item_id>/"item_id/"</item_id>
 *         </search_item>
 *         <language>/"language/"</language>
 * </poi_info_request>
 * 
 *
 */
- (NSString *)searchPoiDetails:(NSString *)itemId name:(NSString *)name 
{
    WFXMLDocument *query = [self XMLQuerySkeleton];
    NSString *trId = [self uuid];


    WFXMLElement *item_id = [WFXMLElement
                                elementWithName:@"itemid"
                                stringValue:itemId];
	
    WFXMLElement *item_name = [WFXMLElement
                                  elementWithName:@"name"
                                  stringValue:[self urlencodeString:name]];

    WFXMLElement *request_details_item = 
        [WFXMLElement elementWithName:@"search_item"
                      children:[NSArray arrayWithObjects: item_name, 
                                        item_id, nil]
                      attributes:[NSDictionary dictionaryWithObject: @"pointofinterest"
                                               forKey:@"search_item_type"]];
    
    WFXMLElement *request_details_lang = [WFXMLElement
        elementWithName:@"language"
        stringValue:[[NSLocale preferredLanguages] objectAtIndex:0]];

    WFXMLElement *request_body = 
        [WFXMLElement
            elementWithName:@"poi_info_request"
            children:[NSArray arrayWithObjects:request_details_item,
                              request_details_lang, nil]
            attributes:[NSDictionary dictionaryWithObject: trId
                                     forKey: @"transaction_id"]
            ];

    [query.rootElement addChild:request_body];

    [requestMap setObject:query forKey:trId];
    [connector requestWithXML:query delegate:self];	

    return trId;
}

- (NSString *) urlencodeString:(NSString *)aString
{
    NSCharacterSet *XMLspecial = [NSCharacterSet
                                     characterSetWithCharactersInString:@"<>&'\""];
    
    if ([aString rangeOfCharacterFromSet:XMLspecial].location !=
            NSNotFound)
        {
            aString = [aString stringByReplacingOccurrencesOfString:@"&"
                                                                 withString:@"&amp;"];
            aString = [aString stringByReplacingOccurrencesOfString:@"<"
                                                                 withString:@"&lt;"];
            aString = [aString stringByReplacingOccurrencesOfString:@">"
                                                                 withString:@"&gt;"];
            aString = [aString stringByReplacingOccurrencesOfString:@"\""
                                                                 withString:@"&quot;"];
            aString = [aString stringByReplacingOccurrencesOfString:@"'"
                                                                 withString:@"&#39;"];
        }
    return aString;
}
- (void)dealloc
{
    [connector release];
    [requestMap release];
    [super dealloc];
}

@end
