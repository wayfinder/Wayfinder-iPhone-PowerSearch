/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "TestImageLoader.h"


@implementation TestImageLoader

- (void)setUp
{
    loader = [[WFImageLoader alloc] init];
}

- (void)tearDown
{
    [loader release];
}

// Test loading of image that is on file
- (void)testExistingImageLoad
{
    UIImageView *imageView = [[UIImageView alloc] init];

    if ([loader loadImageNamed:@"search-item-number-icon" to:imageView]) {
        // XXX: How to test that this is the correct image???
        
        STAssertTrue(imageView.image != nil,@"testExistingImageLoad failed!");
    }
    
    [imageView release];
}

// Test loading of image that is not on file (should receive default image)
- (void)testDefaultImageLoad
{
    UIImageView *imageView = [[UIImageView alloc] init];
    
    // Loading should succeed even if image name already has the .png
    if ([loader loadImageNamed:@"non-existing-image.png" to:imageView]) {
        
        STAssertTrue(imageView.image != nil,@"testDefaultImageLoad failed!");
    }
    
    [imageView release];
}

// Test loading of image from server
- (void)testServerImageLoad
{
    UIImageView *imageView = [[UIImageView alloc] init];

    // Loading should succeed even if image name already has the .png
    if ([loader loadImageNamed:@"tat_airport" to:imageView]) {
        
        STAssertTrue(imageView.image != nil,@"testServerImageLoad failed!");
    }
    
    [imageView release];
}

@end
