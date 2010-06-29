/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "GTMSenTestCase.h"
#import "WFXMLParser.h"
#import "WFXMLDocument.h"
#import "WFXMLElement.h"

@interface TestXMLParser : GTMTestCase {
}
@end

@implementation TestXMLParser

static NSString *testXMLString = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?><!DOCTYPE isab-mc2><isab-mc2> \
   <search_reply transaction_id=\"search_id\"><search_item_list ending_index=\"9\" numberitems=\"10\" starting_index=\"0\" total_numberitems=\"35\"> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Helsingin kauppakorkeakoulu, Runeberginkatu 14</name> \
            <itemid>c:70003198:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Helsingin kauppakorkeakoulun kirjasto, Leppäsuonkatu 9</name> \
            <itemid>c:70002FF4:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Hyrylän koulukeskus</name> \
            <itemid>c:7000243F:37:0:E</itemid> \
            <location_name>Tuusula</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Kirkonkylän koulukeskus, Haagantie</name> \
            <itemid>c:700026C2:37:0:E</itemid> \
            <location_name>Kirkkonummi</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Koulumuseo (Helsingin kaupunginmuseo), Kalevankatu 39</name> \
            <itemid>c:7000317B:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Taideteollinen korkeakoulu, Hämeentie 135</name> \
            <itemid>c:70003193:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Taideteollisen korkeakoulun kirjasto, Hämeentie 135</name> \
            <itemid>c:70002FEF:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Teatterikorkeakoulu, Haapaniemenkatu 6</name> \
            <itemid>c:70003194:37:0:E</itemid> \
            <location_name>Helsinki</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Teknillinen korkeakoulu, Otakaari 1</name> \
            <itemid>c:70002A8C:37:0:E</itemid> \
            <location_name>Tapiola, Espoo</location_name> \
         </search_item> \
         <search_item search_item_type=\"pointofinterest\"> \
            <name>Teknillisen korkeakoulun kirjasto, Otaniementie 9</name> \
            <itemid>c:700029C1:37:0:E</itemid> \
            <location_name>Tapiola, Espoo</location_name> \
         </search_item> \
      </search_item_list> \
   </search_reply> \
</isab-mc2>";

static NSData *testXMLData;

- (void)setUp
{
    testXMLData = [[testXMLString dataUsingEncoding:NSUTF8StringEncoding] retain];
}

- (void)tearDown
{
    [testXMLData release];
}

- (void)testIntialization
{
    NSURL *url = [NSURL URLWithString:@"http://www.w3schools.com/XML/cd_catalog.xml"];
    WFXMLParser *parser = [WFXMLParser parserWithURL:url];
    STAssertNotNULL(parser, @"Error initializing parser with URL");

    parser = [WFXMLParser parserWithData:testXMLData];
    STAssertNotNULL(parser, @"Error initializing parser with data");
}

- (void)testParsing
{
    WFXMLParser *parser = [WFXMLParser parserWithData:testXMLData];

    WFXMLDocument *result = [parser parse];

    STAssertNotNULL(result, @"Parsing failed");
    STAssertNotNULL(result.rootElement, @"Parsing failed, no root element");
    STAssertEqualStrings([result.rootElement name], @"isab-mc2", @"");

    NSArray *resultArray = [result.rootElement elementsForName:@"search_item"];
    STAssertTrue([resultArray count] == 10,
                   @"Wrong number of results, was %d", [resultArray count]);
}

- (void)testParsingCDATA
{
    NSString *CDATAString = @"Map.png?lla=717873657&llo=297556052&ula=717835782&ulo=297503083&w=320&h=460&s=22496&r=&mt=std&is=%FF%FC%02&map=1&topomap=1&poi=1&route=1&scale=0&traffic=0";
    NSString *XMLCDATAString = [NSString
        stringWithFormat:@"<?xml version=\"1.0\" encoding=\"iso-8859-1\""
        " standalone=\"no\" ?>"
        "<!DOCTYPE isab-mc2>"
        "<isab-mc2>"
        "<map_reply transaction_id=\"xox\">"
        "<href><![CDATA[%@]]></href>"
        "</map_reply>"
        "</isab-mc2>", CDATAString];
    NSData *XMLWithCDATA = [XMLCDATAString dataUsingEncoding:NSUTF8StringEncoding];

    WFXMLParser *parser = [WFXMLParser parserWithData:XMLWithCDATA];
    WFXMLDocument *result = [parser parse];

    WFXMLElement *element = [result.rootElement elementForName:@"href"];
    STAssertEqualStrings([element stringValue], CDATAString, @"");
}

- (void)testInvalidDocument
{
    NSString *invalidXML = @"<What<>me worry?";
    WFXMLParser *parser = [WFXMLParser
        parserWithData:[invalidXML dataUsingEncoding:NSUTF8StringEncoding]];

    WFXMLDocument *result = [parser parse];
    STAssertNULL(result, @"Must not parse invalid documents");
}

@end
