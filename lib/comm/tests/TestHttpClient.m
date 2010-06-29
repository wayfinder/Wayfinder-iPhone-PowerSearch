/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Description: Unit tests for WFHttpClient
//
//

#import "TestHttpClient.h"
#import "WFHttpClient.h"

@implementation TestHttpClient

-(void) setUp
{
  client = [[WFHttpClient alloc] init];
}

-(void) tearDown
{
  [client release];
}

-(void) testBuildHttpPostRequest
{
  NSString *request = @"Hi there";
  NSString *url = @"http://update.wayfinder.com";
  CFHTTPMessageRef mess = [client buildHttpPostRequest: request url: url];

  STAssertNotNULL(mess, @"Message generation failed.");
  STAssertTrue(CFHTTPMessageIsRequest(mess), @"Request is invalid !");
  STAssertTrue((NSString *)CFHTTPMessageCopyRequestMethod(mess) == @"POST", 
	       @"Expected method to be POST, but was %@",
	       (NSString *)CFHTTPMessageCopyRequestMethod(mess));
}

// uses temporary server on Lauri's 'lattemasiina' desktop
// We have to implement callback for results as described in header, real tests reside there.
-(void) testSendValidPostRequest
{
  NSString *req = @"Hi there";
  // A mock server which answers to a post request by printing headers and request
  NSString *url = @"http://lattemasiina/ps/postit";
  [client sendPostRequest:(NSString *) req url: url client: self];
}

-(void) testResponse
{
  STAssertNotNULL(test_reply, @"Reply is null, verify the test server is up and running.");
  STAssertTrue(test_reply == @"foo", @"Reply is wrong, iz %@", test_reply);
  NSLog(@"reply was: %@",test_reply);

}

-(void) httpPostResult: (WFHttpClient *) the_client completedWithResultCode: (int) code
{
  // verify we got a resultcode
  STAssertLessThanOrEqual(code, -1, @"Result code should be in range -5...-1");
  // get results
  test_reply = [the_client replyContent];
}
@end
