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
// Description: A class to test the Address formatter
//
//



#import "GTMSenTestCase.h"
#import "WFAddrParser.h"

@interface TestAddrParser: GTMTestCase
{
    NSMutableDictionary *testDetails;
    WFAddrParser *parser;
}
@end

@implementation TestAddrParser

- (void)setUp
{
    // generate test data
    testDetails = [[NSMutableDictionary alloc] init];
    parser = [[WFAddrParser alloc] init];
    
    // europe
 

    NSDictionary *info = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSDictionary dictionaryWithObjectsAndKeys:@"Tapionaukio",@"value",nil],@"vis_address",
         [NSDictionary dictionaryWithObjectsAndKeys:@"3",@"value",nil],@"vis_house_nbr",
         [NSDictionary dictionaryWithObjectsAndKeys:@"00210",@"value",nil],@"vis_zip_code",
         [NSDictionary dictionaryWithObjectsAndKeys:@"Espoo",@"value",nil],@"vis_zip_area",                   
         nil];

    NSMutableDictionary *details = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                            info, @"info",nil];
    [testDetails setObject:details forKey:@"europe"];
    
   // Wcities, Europe
    info = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSDictionary dictionaryWithObjectsAndKeys:@"3 Tapionaukio",@"value",nil],@"vis_full_address",
              [NSDictionary dictionaryWithObjectsAndKeys:@"00210",@"value",nil],@"vis_zip_code",
              [NSDictionary dictionaryWithObjectsAndKeys:@"Espoo",@"value",nil],@"vis_zip_area",                   
              nil];
    
    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"info",nil];
    [testDetails setObject:details forKey:@"wc_europe"];

   // WCities, US
    info = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSDictionary dictionaryWithObjectsAndKeys:@"51 Mountain Road",@"value",nil],@"vis_full_address",
              [NSDictionary dictionaryWithObjectsAndKeys:@"32414",@"value",nil],@"vis_zip_code",
              [NSDictionary dictionaryWithObjectsAndKeys:@"Mountain View",@"value",nil],@"vis_zip_area",                   
              [NSDictionary dictionaryWithObjectsAndKeys:@"CA",@"value",nil],@"state",                                 
              nil];
    
    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"info",nil];
    [testDetails setObject:details forKey:@"wc_us"];

    // US
    info = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSDictionary dictionaryWithObjectsAndKeys:@"Mountain Road",@"value",nil],@"vis_address",
         [NSDictionary dictionaryWithObjectsAndKeys:@"51",@"value",nil],@"vis_house_nbr",
         [NSDictionary dictionaryWithObjectsAndKeys:@"32414",@"value",nil],@"vis_zip_code",
         [NSDictionary dictionaryWithObjectsAndKeys:@"Mountain View",@"value",nil],@"vis_zip_area",
         [NSDictionary dictionaryWithObjectsAndKeys:@"CA",@"value",nil],@"state",                    
         nil];

    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                            info, @"info",nil];
    [testDetails setObject:details forKey:@"us"];

    
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithObjectsAndKeys:@"1-4 A 3 Tapionaukio",@"value",nil],@"vis_full_address",
            [NSDictionary dictionaryWithObjectsAndKeys:@"00210",@"value",nil],@"vis_zip_code",
            [NSDictionary dictionaryWithObjectsAndKeys:@"Espoo",@"value",nil],@"vis_zip_area",                   
            nil];
    
    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"info",nil];
    [testDetails setObject:details forKey:@"wc_insane_europe"];

    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithObjectsAndKeys:@"6 Keskuskatu",@"value",nil],@"vis_full_address",
            [NSDictionary dictionaryWithObjectsAndKeys:@"00210",@"value",nil],@"vis_zip_code",
            [NSDictionary dictionaryWithObjectsAndKeys:@"Espoo",@"value",nil],@"vis_zip_area",                   
            nil];
    
    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"info",nil];
    [testDetails setObject:details forKey:@"wc_semi_insane_europe"];


    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithObjectsAndKeys:@"1346 N Albany Street",@"value",nil],@"vis_full_address",
            [NSDictionary dictionaryWithObjectsAndKeys:@"42213",@"value",nil],@"vis_zip_code",
            [NSDictionary dictionaryWithObjectsAndKeys:@"Los Angeles",@"value",nil],@"vis_zip_area",
            [NSDictionary dictionaryWithObjectsAndKeys:@"CA",@"value",nil],@"state", 
            nil];
    
    details = [NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"info",nil];
    [testDetails setObject:details forKey:@"wc_hardest_us"];
    
}

- (void)tearDown
{
   [parser release];
   [testDetails release];
}

- (void)testAddressParserEurope
{
    NSString *eu = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"europe"]];
    STAssertEqualStrings(eu,@"Tapionaukio 3", @"Parsed addresses do not match");
}

- (void)testAddressParserWCitiesEurope
{
    NSString *parsed = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"wc_europe"]];
    STAssertEqualStrings(parsed, @"Tapionaukio 3", @"Parsed address doesn't match");
}

- (void)testAddressParserWCitiesUS
{
    NSString *parsed = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"wc_us"]];
    STAssertEqualStrings(parsed, @"51 Mountain Road", @"Parsed addresses do not match");
}


- (void)testAddressParserUS
{
    NSString *parsed = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"us"]];
    STAssertEqualStrings(parsed, @"51 Mountain Road", @"Parsed address doesn't match");
}

- (void)testAddressParserWithInsaneDataEurope
{
    NSString *parsed = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"wc_insane_europe"]];
    STAssertEqualStrings(parsed, @"Tapionaukio 1-4 A 3", @"Parsed address doesn't match");
    
    parsed = [parser parseStreetAddressForDict:(NSDictionary *)[testDetails objectForKey:@"wc_semi_insane_europe"]];
    STAssertEqualStrings(parsed, @"Keskuskatu 6", @"Parsed address doesn't match");
    
}

- (void)testAddressParserNil
{
    NSString *parsed = [parser parseStreetAddressForDict:nil];
    STAssertEqualStrings(parsed, @"", @"Parsed address doesn't match");
}

- (void)testZipParserUs
{
    NSString *should_be = @"Mountain View CA 32414";
    NSString *parsed = [parser parseMunicipality:(NSDictionary *)[testDetails objectForKey:@"us"]];
    STAssertEqualStrings(parsed, should_be,@"Failed to parse zip");

    parsed = [parser parseMunicipality:(NSDictionary *)[testDetails objectForKey:@"wc_us"]];
    STAssertEqualStrings(parsed, should_be,@"Failed to parse zip");
}


- (void)testZipParserEurope
{
    NSString *should_be = @"00210 Espoo";
    NSString *parsed = [parser parseMunicipality:(NSDictionary *)[testDetails objectForKey:@"europe"]];
    STAssertEqualStrings(parsed, should_be,@"Failed to parse, should be %@ was %@",should_be,parsed);

    parsed = [parser parseMunicipality:(NSDictionary *)[testDetails objectForKey:@"wc_europe"]];
    STAssertEqualStrings(parsed, should_be,@"Failed to parse, should be %@ was %@",should_be,parsed);
    
}

- (void)testZipParserNil
{
    NSString *parsed = [parser parseMunicipality:nil];
    STAssertEqualStrings(parsed, @"", @"Parsing nil should return empty string.");
}

@end
