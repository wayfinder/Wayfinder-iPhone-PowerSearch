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
// An interface to the wayfinder XML service API.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocation.h>
#import "constants.h"

@class WFXMLService;
@class WFXMLDocument;

typedef struct {
    CLLocationCoordinate2D upperLeft;
    CLLocationCoordinate2D lowerRight;
} WFBoundingBox;

@protocol WFXMLServiceDelegate
- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id;
@optional
- (void)service:(WFXMLService *)service didReceiveItem:(NSDictionary *)item
  transActionId:(NSString *)Id;
- (void)service:(WFXMLService *)service didReceiveDetail:(NSDictionary *) item 
  transActionId:(NSString *)Id;
- (void)service:(WFXMLService *)service didReceiveCategory:(NSDictionary *)items
            crc:(NSString *)crc transActionId:(NSString *)trId;
- (void)service:(WFXMLService *)service didFinishTransAction:(NSString *)Id;
- (void)service:(WFXMLService *)service didReceiveMapImage:(UIImage *)image
  transActionId:(NSString *)Id;
- (void)service:(WFXMLService *)service didReceiveRoute:(NSString *)routeId
      routeData:(NSDictionary *)routeData transActionId:(NSString *)Id;
@end

@protocol WFXMLServiceConnectorDelegate
- (void)connector:(id)connector didReceiveXML:(WFXMLDocument *)document;
- (void)connector:(id)connector didReceiveFile:(NSData *)fileData
    transActionId:(NSString *)Id;
- (void)connector:(id)connector didFailWithError:(NSError *)error
    transActionId:(NSString *)Id;
@end

@protocol WFXMLServiceConnector
- (void)requestWithXML:(WFXMLDocument *)document
              delegate:(id<WFXMLServiceConnectorDelegate>)delegate;
- (void)requestFile:(NSString *)fileName
           delegate:(id<WFXMLServiceConnectorDelegate>)delegate
      transActionId:(NSString *)Id;
- (void)requestFromAddress:(NSString *)httpAddress
                  delegate:(id<WFXMLServiceConnectorDelegate>)delegate
             transActionId:(NSString *)Id;
@end

@interface WFXMLService : NSObject <WFXMLServiceConnectorDelegate> {
@private
    NSObject<WFXMLServiceDelegate> *delegate;
    NSObject<WFXMLServiceConnector> *connector;
    NSMutableDictionary *requestMap;
}

@property (nonatomic,assign) NSObject<WFXMLServiceDelegate> *delegate;
@property (nonatomic,retain) id<WFXMLServiceConnector> connector;

+ (WFXMLService *)service;
- (NSString *)mapImageWithBoundingBox:(WFBoundingBox)boundingBox
                                 size:(CGSize)size;


- (NSString *)searchPoiDetails:(NSString *)itemid name:(NSString *)itemName;

- (NSString *)categoryRequestWithCrc:(NSString *)crc;

- (NSString *)searchWithString:(NSString *)queryString
                    coordinate:(CLLocationCoordinate2D)coordinate
                    searchRange:(NSRange)searchRange;

- (NSString *)searchWithCategory:(NSString *)categoryId
                      coordinate:(CLLocationCoordinate2D)coordinate
                     searchRange:(NSRange)searchRange;

// Method for fething an image from the default server path
- (NSString *)fetchImageWithName:(NSString *)imageName;
// Method for fething an image from any server/path
- (NSString *)fetchImageFromAddress:(NSString *)httpAddress;

- (NSString *)urlencodeString:(NSString *) str;

// Method for fething all data providers and their top region
- (NSString *)searchDescriptionRequestWithCrc:(NSString *)crc;

// Method for fething users top region and its data providers
- (NSString *)regionRequestWithCoordinate:(CLLocationCoordinate2D)coordinate;

// Method for requesting a route from server. Set oldRouteId only if this is a reroute
- (NSString *)routeRequestFrom:(CLLocationCoordinate2D)startCoordinate
                            to:(CLLocationCoordinate2D)endCoordinate
                     routeType:(routingType)routeType
                    oldRouteId:(NSString *)oldRouteId;

/* Cancel transaction with id 'transActionId'.
 *
 * If this function is called when processing results in one of the didReceive*
 * functions, all data that has already arrived will be processed and the
 * client must be prepared to handle such items.
 *
 * didFinishTransAction is never called after executing this method.
 */ 
- (void)cancelTransAction:(NSString *)transActionId;

@end
