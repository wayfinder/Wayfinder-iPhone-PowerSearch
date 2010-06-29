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
// References: "International Mailing Address Formats" 
// http://bitboost.com/ref/international-address-formats.html
//

#import "WFAddrParser.h"

@interface WFAddrParser (Private)

- (NSMutableDictionary *)extractHouseStreet:(NSDictionary *)dict;
@end


@implementation WFAddrParser


- (NSString *)parseStreetAddressForDict:(NSDictionary *)details
{
    
    NSMutableDictionary *houseStreet = [self extractHouseStreet:details];
    NSString *formattedAddress;
   
    
    NSDictionary *info = [details objectForKey:@"info"];
    if (!info || ([houseStreet count] == 0)) {
        formattedAddress = @"";
    }
    else
    {
    
        if ([info objectForKey:@"state"]) {
            formattedAddress = [NSString stringWithFormat:@"%@ %@",
                                [houseStreet objectForKey:@"vis_house_nbr"],
                                [houseStreet objectForKey:@"vis_address"]];
        }
        else {
            formattedAddress = [NSString stringWithFormat:@"%@ %@",
                                [houseStreet objectForKey:@"vis_address"],
                                [houseStreet objectForKey:@"vis_house_nbr"]];
        }
    }

    return formattedAddress;
}


- (NSString *)parseMunicipality:(NSDictionary *)dict
{
    NSMutableString *municipality = [NSMutableString stringWithString:@""];
    if( [dict objectForKey:@"info"]) {
        // use US format
        NSMutableDictionary *info = [dict objectForKey:@"info"];
        if ([info objectForKey:@"state"]) {
            if ([info objectForKey:@"vis_zip_area"])
                [municipality appendString: [[info objectForKey:@"vis_zip_area"] objectForKey:@"value"]];
            if ([info objectForKey:@"state"])
                [municipality appendFormat:@" %@", [[info objectForKey:@"state"] objectForKey:@"value"]];
            if ([info objectForKey:@"vis_zip_code"])
                [municipality appendFormat:@" %@", [[info objectForKey:@"vis_zip_code"] objectForKey:@"value"]];
        }
        else {
            // use european style
            if ([info objectForKey:@"vis_zip_code"])
                [municipality appendString:
                                  [[info objectForKey:@"vis_zip_code"] objectForKey:@"value"]];
            if ([info objectForKey:@"vis_zip_area"])
                [municipality appendFormat:@" %@", [[info objectForKey:@"vis_zip_area"]  objectForKey:@"value"]];            
        }        
    }
    
    return municipality;
}

- (NSMutableDictionary *)extractHouseStreet:(NSDictionary *)dict
{
    NSMutableDictionary *houseStreet = [[NSMutableDictionary alloc] init];
    
    NSDictionary *info = [dict objectForKey:@"info"];
    if (!info) {
        NSLog(@"No address info portion found in dictionary!");
        [houseStreet release];
        return nil;
    }
    
    if ([info objectForKey:@"vis_full_address"]) {
        
        NSString *searchString = [[info objectForKey:@"vis_full_address"] objectForKey:@"value"];
        // this regex matches housenumber, apartment form
        // 1 tallberginkatu
        // 1 A tallberginkatu
        // 1-4 tallberginkatu
        // 1-4 A 22 tallberginkatu
        // 1A tallberginkatu
        // 1/2 tallberginkatu
        // from both sides of the streetname.
        NSString *regexString = @"([0-9]{1,}(-[0-9]*)?(\\/[0-9]*)?\\s?([a-zA-Z]{1}\\s[0-9]*)?)";

        NSString *houseNumber = [searchString stringByMatching:regexString capture:1];
        NSString *street = [searchString stringByReplacingOccurrencesOfRegex:regexString withString:@""]; 
        NSString *wstreet = [street stringByReplacingOccurrencesOfRegex:@"^\\s?" withString:@""];

        [houseStreet setValue:[houseNumber stringByReplacingOccurrencesOfRegex:@"\\s\\z" withString:@""] forKey:@"vis_house_nbr"];
        [houseStreet setValue:[wstreet stringByReplacingOccurrencesOfRegex:@"\\s\\z" withString:@""] forKey:@"vis_address"];
    }
    else {
        
        if ([info objectForKey:@"vis_house_nbr"]){
            NSString *house = [[info objectForKey:@"vis_house_nbr"] objectForKey:@"value"];
            [houseStreet setValue:house forKey:@"vis_house_nbr"];
        }
        else 
            [houseStreet setValue:@"" forKey:@"vis_house_nbr"];
        
        
        if ([info objectForKey:@"vis_address"]) {
            NSString *address = [[info objectForKey:@"vis_address"] objectForKey:@"value"];
            [houseStreet setValue:address forKey:@"vis_address"];
        }
        else 
            [houseStreet setValue:@"" forKey:@"vis_address"];
        
    }
    
    return [houseStreet autorelease];
    
}
        

@end
