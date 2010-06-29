/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFXMLDocument.h"
#import "WFXMLElement.h"
#import "WFXMLParser.h"

@interface WFXMLParser ()

@property (nonatomic,retain) NSXMLParser *nsParser;
@property (nonatomic,retain) WFXMLElement *currentElement;
@property (nonatomic,assign) WFXMLParser *parent;


+ (WFXMLParser *)parserWithParser:(NSXMLParser *)aParser
              parent:(WFXMLParser *)parent
      currentElement:(WFXMLElement *)currentElement;

- (id)initWithParser:(NSXMLParser *)aParser
              parent:(WFXMLParser *)parent
      currentElement:(WFXMLElement *)currentElement;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
@end

/* WFXMLParser class implementation starts here */
@implementation WFXMLParser

@synthesize nsParser;
@synthesize parent;
@synthesize currentElement;

+ (WFXMLParser *)parserWithParser:(NSXMLParser *)aParser
              parent:(WFXMLParser *)parent
      currentElement:(WFXMLElement *)currentElement
{
    WFXMLParser *newParser = [[WFXMLParser alloc]
        initWithParser:aParser
                parent:parent
        currentElement:currentElement];
    return [newParser autorelease];
}

+ (WFXMLParser *)parserWithURL:(NSURL *)url
{
    WFXMLParser *newParser = [[WFXMLParser alloc] initWithURL:url];
    return [newParser autorelease];
}

+ (WFXMLParser *)parserWithData:(NSData *)data
{
    WFXMLParser *newParser = [[WFXMLParser alloc] initWithData:data];
    return [newParser autorelease];
}

- (id)initWithParser:(NSXMLParser *)aParser
              parent:(WFXMLParser *)aParent
      currentElement:(WFXMLElement *)theCurrentElement;
{
    if (self = [super init]) {
        self.nsParser = aParser;
        [nsParser setDelegate:self];
        parent = aParent;
        self.currentElement = theCurrentElement;
        currentData = nil;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    NSXMLParser *aParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    return [self initWithParser:[aParser autorelease]
                         parent:nil
                 currentElement:nil];
}

- (id)initWithData:(NSData *)data
{
    NSXMLParser *aParser = [[NSXMLParser alloc] initWithData:data];
    return [self initWithParser:[aParser autorelease]
                         parent:nil
                 currentElement:nil];
}

- (WFXMLDocument *)parse
{
    self.currentElement = [WFXMLElement elementWithName:@"dummy"];

    if (![nsParser parse])
        return nil;

    WFXMLDocument *doc = [[WFXMLDocument alloc] init];
    doc.rootElement = [currentElement.children objectAtIndex:0];
    return [doc autorelease];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) 
        elementName = qName;

    if (currentData)
        [currentElement addChild:currentData];

    WFXMLElement *newElement = [WFXMLElement elementWithName:elementName
                                                 children:nil
                                               attributes:attributeDict];
    [currentElement addChild:newElement];

    [WFXMLParser parserWithParser:parser parent:self
                    currentElement:newElement];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (currentData)
        [currentElement addChild:currentData];
    [parser setDelegate:parent];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if ([[string stringByTrimmingCharactersInSet:set] length] != 0) {
        if (currentData)
            [currentData appendString:string];
        else
            currentData = [[NSMutableString alloc] initWithString:string];
    }
}

- (void)dealloc
{
    [currentData release];
    [currentElement release];
    [nsParser release];
    [super dealloc];
}

@end
