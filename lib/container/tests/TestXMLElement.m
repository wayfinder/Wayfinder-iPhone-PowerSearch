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
#import "WFXMLElement.h"

@interface TestXMLElement : GTMTestCase {
}
@end

@implementation TestXMLElement

- (void)testInitialization
{
    WFXMLElement *element = [[WFXMLElement alloc] init];
    STAssertNotNULL(element, @"");
    [element release];
}

- (void)testEmptyElement
{
    WFXMLElement *element = [WFXMLElement elementWithName:@"test"];
    STAssertEqualStrings([element XMLString], @"<test/>", @"");
    STAssertEqualStrings([element stringValue], @"", @"");
}

- (void)testSimpleElements
{
    WFXMLElement *e = [WFXMLElement elementWithName:@"test"
                                        stringValue:@"Test String"];

    STAssertEqualStrings([e XMLString], @"<test>Test String</test>", @"");

    e.stringValue = @"Second Test";
    STAssertEqualStrings([e XMLString], @"<test>Second Test</test>", @"");

    e = [WFXMLElement elementWithName:@"test"];
    [e addChild:[WFXMLElement elementWithName:@"test_child"]];
    STAssertNULL(e.stringValue, @"");
}

- (void)testAttributes
{
    NSArray *objs = [NSArray arrayWithObjects:@"obj1", @"obj2", nil];
    NSArray *keys = [NSArray arrayWithObjects:@"key1", @"key2", nil];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objs
                                                      forKeys:keys];

    WFXMLElement *element = [WFXMLElement elementWithName:@"test"
                                                 children:nil
                                               attributes:attrs];
    STAssertEqualStrings([element XMLString],
                         @"<test key1=\"obj1\" key2=\"obj2\"/>", @"");

    [element addAttributes:[NSDictionary dictionaryWithObject:@"obj3"
                   forKey:@"key3"]];
    STAssertEqualStrings([element XMLString],
        @"<test key1=\"obj1\" key2=\"obj2\" key3=\"obj3\"/>", @"");
}

- (void)testNestedElements
{
    WFXMLElement *element = [WFXMLElement elementWithName:@"e"];
    WFXMLElement *element3 = [WFXMLElement elementWithName:@"e3"];

    element.children = [NSArray arrayWithObjects:[WFXMLElement
                                 elementWithName:@"e2"], element3, nil];
    STAssertEqualStrings([element XMLString], @"<e><e2/><e3/></e>", @"");

    [element3 addChild:[WFXMLElement elementWithName:@"e4"]];
    [element3 addChild:@"Testing"];
    STAssertEqualStrings([element XMLString],
                         @"<e><e2/><e3><e4/>Testing</e3></e>", @"");
}

- (void)testFindingElement
{
    NSArray *objs = [NSArray arrayWithObjects:@"obj1", nil];
    NSArray *keys = [NSArray arrayWithObjects:@"key1", nil];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objs
                                                      forKeys:keys];

    NSArray *objs2 = [NSArray arrayWithObjects:@"OBJ1", nil];
    NSArray *keys2 = [NSArray arrayWithObjects:@"KEY1", nil];
    NSDictionary *attrs2 = [NSDictionary dictionaryWithObjects:objs2
                                                      forKeys:keys2];

    WFXMLElement *e = [WFXMLElement elementWithName:@"e"];
    [e addChild:[WFXMLElement elementWithName:@"sub_e1" children:nil
     attributes:attrs]];
    [e addChild:[WFXMLElement elementWithName:@"sub_e2" children:nil
     attributes:attrs]];
    WFXMLElement *e3 = [WFXMLElement elementWithName:@"sub_e3"];
    [e3 addChild:[WFXMLElement elementWithName:@"sub_e1" children:nil
      attributes:attrs2]];
    [e addChild:e3];
    [e addChild:[WFXMLElement elementWithName:@"sub_e4" children:nil
     attributes:attrs]];

    WFXMLElement *resultElement = [e elementForName:@"sub_e1"];
    STAssertNotNULL(resultElement, @"");

    id attrDict = [resultElement attributes];
    STAssertEqualStrings([attrDict objectForKey:@"key1"], @"obj1", @"");

    resultElement = [e elementForName:@"non_existent"];
    STAssertNULL(resultElement, @"");
}

- (void)testFindingElements
{
    NSArray *objs = [NSArray arrayWithObjects:@"obj1", nil];
    NSArray *keys = [NSArray arrayWithObjects:@"key1", nil];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objs
                                                      forKeys:keys];

    NSArray *objs2 = [NSArray arrayWithObjects:@"OBJ1", nil];
    NSArray *keys2 = [NSArray arrayWithObjects:@"KEY1", nil];
    NSDictionary *attrs2 = [NSDictionary dictionaryWithObjects:objs2
                                                      forKeys:keys2];

    WFXMLElement *e = [WFXMLElement elementWithName:@"e"];
    [e addChild:[WFXMLElement elementWithName:@"sub_e1" children:nil
     attributes:attrs]];
    [e addChild:[WFXMLElement elementWithName:@"sub_e2" children:nil
     attributes:attrs]];
    WFXMLElement *e3 = [WFXMLElement elementWithName:@"sub_e3"];
    [e3 addChild:[WFXMLElement elementWithName:@"sub_e1" children:nil
      attributes:attrs2]];
    [e addChild:e3];
    [e addChild:[WFXMLElement elementWithName:@"sub_e4" children:nil
     attributes:attrs]];

    NSArray *resultArray = [e elementsForName:@"sub_e1"];

    STAssertTrue([resultArray count] == 2, @"Wrong number of results");
    STAssertEqualStrings([[resultArray objectAtIndex:0] name], @"sub_e1", @"");
    STAssertEqualStrings([[resultArray objectAtIndex:1] name], @"sub_e1", @"");

    id attrDict = [[resultArray objectAtIndex:0] attributes];
    STAssertEqualStrings([attrDict objectForKey:@"key1"], @"obj1", @"");

    attrDict = [[resultArray objectAtIndex:1] attributes];
    STAssertEqualStrings([attrDict objectForKey:@"KEY1"], @"OBJ1", @"");

    resultArray = [e elementsForName:@"non_existent"];
    STAssertNotNULL(resultArray, @"");
    STAssertTrue([resultArray count] == 0, @"");
}

@end
