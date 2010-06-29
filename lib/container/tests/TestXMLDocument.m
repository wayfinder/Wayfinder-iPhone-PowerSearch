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
#import "GtmSenTestCase.h"
#import "WFXMLDocument.h"
#import "WFXMLElement.h"

@interface TestXMLDocument : GTMTestCase {
}
@end

@implementation TestXMLDocument

- (void)testInitialization
{
    WFXMLDocument *doc = [[WFXMLDocument alloc] init];
    STAssertNotNULL(doc, @"Could not create document");
    [doc release];
}

- (void)testAttributes
{
    WFXMLDocument *doc = [[WFXMLDocument alloc] init];

    STAssertEqualStrings(doc.version, @"1.0", @"");
    STAssertTrue(doc.encoding == NSUTF8StringEncoding, @"");
    STAssertEqualStrings(doc.docType, @"isab-mc2", @"");
    [doc release];
}

- (void)testEmptyDocument
{
    WFXMLDocument *doc = [[WFXMLDocument alloc] init];
    NSMutableString *testString = [NSMutableString stringWithCapacity:64];
    [testString appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"];
    [testString appendString:@"<!DOCTYPE isab-mc2>\n"];

    STAssertEqualStrings([doc XMLString], testString, @"was '%@'",
                         [doc XMLString]);

    [doc release];
}

- (void)testDocument
{
    WFXMLDocument *doc = [[WFXMLDocument alloc] init];
    WFXMLElement *elem = [WFXMLElement elementWithName:@"element"];
    [elem addChild:[WFXMLElement elementWithName:@"element2"]];

    doc.rootElement = elem;

    NSMutableString *testString = [NSMutableString stringWithCapacity:64];
    [testString appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"];
    [testString appendString:@"<!DOCTYPE isab-mc2>\n"];
    [testString appendString:@"<element><element2/></element>"];

    STAssertEqualStrings([doc XMLString], testString, @"was '%@'",
                         [doc XMLString]);

    [doc release];
}

- (void)testFindingElement
{
}

@end
