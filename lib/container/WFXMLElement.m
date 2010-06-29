/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFXMLElement.h"

/*
 * Make NSString behave like an XML element so that we don't need a separate
 * class just for string elements in an XML document.
 */
@interface NSString(XMLExtensions)
- (NSString *)XMLString;
- (NSArray *)elementsForName:(NSString *)elementName;
- (WFXMLElement *)elementForName:(NSString *)elementName;
@end

@implementation NSString(XMLExtensions)
- (NSString *)XMLString
{
    return self;
}


- (WFXMLElement *)elementForName:(NSString *)elementName
{
    return nil;
}

- (NSArray *)elementsForName:(NSString *)elementName
{
    return [NSArray array];
}
@end

/*
 * WFXMLElement class implementation starts here.
 */
@implementation WFXMLElement

@synthesize name;
@synthesize children;
@synthesize attributes;

/* Class methods */
+ (id)elementWithName:(NSString *)name
{
    return [self elementWithName:name children:nil attributes:nil];
}

+ (id)elementWithName:(NSString *)name stringValue:(NSString *)value
{
    return [self elementWithName:name children:[NSArray arrayWithObject:value]
                      attributes:nil];
}

+ (id)elementWithName:(NSString *)name
             children:(NSArray *)children
           attributes:(NSDictionary *)theAttributes
{
    return [[[self alloc] initWithName:name children:children
                            attributes:theAttributes]
        autorelease];
}

/* Property implementation */
- (void)setStringValue:(NSString *)value
{
    self.children = [NSArray arrayWithObject:value];
}

- (NSString *)stringValue
{
    if ([self.children count] == 0)
        return @"";

    id value = [self.children objectAtIndex:0];
    if ([value isKindOfClass:[NSString class]])
        return value;
    return nil;
}

/* Instance methods */
- (id)init
{
    return [self initWithName:nil children:nil attributes:nil];
}

- (id)initWithName:(NSString *)aname
{
    return [self initWithName:aname children:nil attributes:nil];
}

- (id)initWithName:(NSString *)aname stringValue:(NSString *)value
{
    return [self initWithName:aname children:[NSArray arrayWithObject:value]
           attributes:nil];
}

- (id)initWithName:(NSString *)aname
          children:(NSArray *)theChildren
        attributes:(NSDictionary *)theAttributes
{
    if (self = [super init]) {
        self.name = aname;
        children = [theChildren mutableCopy];
        attributes = [theAttributes mutableCopy];
    }
    return self;
}

- (void)addAttributes:(NSDictionary *)theAttributes
{
    if (theAttributes)
        [attributes addEntriesFromDictionary:theAttributes];
    else
        self.attributes = [NSMutableDictionary
            dictionaryWithDictionary:theAttributes];
}

- (void)addChild:(id)child
{
    if (children)
        [children addObject:child];
    else
        self.children = [NSMutableArray arrayWithObject:child];
}

- (WFXMLElement *)elementForName:(NSString *)elementName
{
    if ([self.name isEqual:elementName])
        return self;

    for (id child in children) {
        WFXMLElement *res = [child elementForName:elementName];
        if (res)
            return res;
    }

    return nil;
}

- (NSArray *)elementsForName:(NSString *)elementName
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    if ([self.name isEqual:elementName])
        [resultArray addObject:self];

    for (id child in children) {
        [resultArray addObjectsFromArray:[child elementsForName:elementName]];
    }

    return [resultArray autorelease];
}

- (NSString *)XMLString
{
    NSMutableString *str = [NSMutableString stringWithCapacity:64];

    [str appendFormat:@"<%@", self.name];
    for (id key in self.attributes) {
        [str appendFormat:@" %@=\"%@\"", key, [self.attributes objectForKey:key]];
    }

    /* If the element has no children, we use the shortened XML tag format
     * (i.e. <foo [attrs]/> instead of <foo [attrs]><foo/>).  */
    if ([children count]) {
        [str appendString:@">"];

        for (id child in self.children) {
            [str appendString:[child XMLString]];
        }

        [str appendFormat:@"</%@>", self.name];
    } else {
        [str appendString:@"/>"];
    }

    return str;
}

- (void)dealloc
{
    [name release];
    [children release];
    [attributes release];
    [super dealloc];
}

@end
