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
// Description: HTTP client to handle post-data using the Core Foundation's HttpMessage
//

#import "WFHttpClient.h"

#define  READ_SIZE 1024
static CFTimeInterval   sPostTimeout = 15.0;

// Private method declarations
@interface WFHttpClient (Private)
  - (CFHTTPMessageRef) buildHttpPostRequest: (NSString *) request_data url: (NSString *) url;
  - (void) setResponseClient:(id) client;
  - (void) informDelegateOfCompletion;
  - (void) closeOutMessaging; 
  void * WFClientRetain(void * selfPtr);
  void WFClientRelease(void* selfPtr);
  CFStringRef WFClientDescribeCopy(void * selfPtr);
@end

// Context to pass to readStream
static CFStreamClientContext postContext = {
   0, nil,
   WFClientRetain, 
   WFClientRelease, 
   WFClientDescribeCopy
};


@implementation WFHttpClient


/******************* initialization ***********************/
-(id) init
{
	// create the container for results.
	if ( self = [super init] ) { 
			m_cfReplyContent = CFStringCreateMutable(
					       kCFAllocatorDefault, 0);
	}
	return self;
}


/******************* MEMORY handling *********************/

void *
WFClientRetain(void * selfPtr)
{
	WFHttpClient*  object = (WFHttpClient *) selfPtr;
	
	return [object retain];
}

void
WFClientRelease(void* selfPtr)
{
	WFHttpClient* object =  (WFHttpClient *) selfPtr;            
	[object release];
}

CFStringRef
WFClientDescribeCopy(void * selfPtr)
{
	WFHttpClient* object = (WFHttpClient *) selfPtr;            
	return (CFStringRef) [[object description] retain];
}


/*********************  methods for timeouts *******************/

+ (CFTimeInterval) timeoutInterval
{ return sPostTimeout; }

+ (void) setTimeoutInterval: (CFTimeInterval) newInterval
{
   sPostTimeout = newInterval;
}

- (void) getResultCode
{
   if (m_replyStream) {
      //   Get the reply headers
      CFHTTPMessageRef   reply =
         (CFHTTPMessageRef) CFReadStreamCopyProperty(
            m_replyStream,
            kCFStreamPropertyHTTPResponseHeader);
                  
      //   Pull the status code from the headers
      if (reply) {
         statusCode = 
            CFHTTPMessageGetResponseStatusCode(reply);
         CFRelease(reply);
      }
   }
}

- (void) messageTimedOut: (NSTimer *) theTimer
{
   statusCode = PostTimedOut;
   [self closeOutMessaging];
   [self informDelegateOfCompletion];
}



/******************* Delegate communication ***********************/

// Tell the client delegate of the status of Reply.
- (void) informDelegateOfCompletion
{
   if (m_ClientDelegate) {
    NSAssert(
         [m_ClientDelegate respondsToSelector:
			     @selector(httpPostResult:completedWithResultCode:)],
         @"A web-POST query delegate must implement "
         @"httpPostResult:completedWithResultCode:");
      [m_ClientDelegate httpPostResult:self	
         completedWithResultCode: statusCode];
   }
}


// Append the contents of stream into final reply content.
- (void) addToResult: (char *)cString
{
	
	CFStringAppendCString(m_cfReplyContent,
						  cString,
						  kCFStringEncodingASCII);
	NSLog(@"reply contents %@", m_cfReplyContent);
	statusCode = PostReplyInProgress;
	//   Refresh the timeout timer.
	[timeoutTimer setFireDate:
	 [NSDate dateWithTimeIntervalSinceNow:
	  sPostTimeout]];
}

// close the stream
- (void) closeOutMessaging
{
	if (m_replyStream) {
		CFReadStreamClose(m_replyStream);
		CFReadStreamSetClient(m_replyStream, 0, NULL, NULL);
		// remove readstream from event loop
		CFReadStreamUnscheduleFromRunLoop(m_replyStream, 
						  CFRunLoopGetCurrent(),
						  kCFRunLoopCommonModes);
		CFRelease(m_replyStream);
		m_replyStream = NULL;
	}
	
	// release timer
	if (timeoutTimer) {
		[timeoutTimer invalidate];
		[timeoutTimer release];
		timeoutTimer = nil;
	}
}



/*********************** Response Handling **************************************/
// readCallback reads reveived bytes from the http stream. Appends results to 
// final contents, and informs client delegate.
void
readCallback(CFReadStreamRef   stream,
                               CFStreamEventType   type,
                               void *            userData)
{
   WFHttpClient * object = 
                     (WFHttpClient *) userData;
   
   switch (type) {
   case kCFStreamEventHasBytesAvailable: {
      UInt8 buffer[READ_SIZE];
      CFIndex   bytesRead = CFReadStreamRead(stream,
                                             buffer, READ_SIZE-1);
  
      
      if (bytesRead > 0) {
         //   Convert what was read to a C-string
         buffer[bytesRead] = 0;
	 //   leave 1 byte for a trailingnull.
	 //   Append it to the reply string
         [object addToResult: (char *)buffer];
      }      
   }
      break;
   case kCFStreamEventErrorOccurred:
   case kCFStreamEventEndEncountered:
      [object getResultCode];
      [object closeOutMessaging];
      [object informDelegateOfCompletion];
      break;
   default:
      break;
   }
}


/******************* POST ************************************************/
/**
 * Sends a HTTP POST request using Core Foundations CFReadStream. Caller
 * must implement <i>httpPostResult</i> to get results statuscode.
 * Reply's data can be read with <i>replyContent</i>.
 * @param request_body contents of the POST data
 * @param url The URL to send the request to
 * @param client The client which implements the callback for the results. 
 * @see \ref post_protocol "httpPostResult"
 * @see replyContent
 */
-(void) sendPostRequest:(NSString *) request_body url: (NSString *) url client:(id) a_client 
{
  
  [self setResponseClient:a_client];
  CFHTTPMessageRef mess = [self buildHttpPostRequest: request_body url: url];

  m_replyStream = CFReadStreamCreateForHTTPRequest(
                                 kCFAllocatorDefault, mess);

  // we can release the message
  CFRelease(mess);

  statusCode = PostNotReplied;
  m_postContext = postContext;
  m_postContext.info = self;
  timeoutTimer = nil;

  CFReadStreamSetClient(m_replyStream,
					kCFStreamEventHasBytesAvailable |
					kCFStreamEventErrorOccurred |
					kCFStreamEventEndEncountered,
					readCallback,
					&m_postContext);
  
     //      Schedule the CFReadStream for service by the current run loop
  CFReadStreamScheduleWithRunLoop(m_replyStream,
				  CFRunLoopGetCurrent(),
				  kCFRunLoopCommonModes);

  CFReadStreamOpen(m_replyStream);
   //   Watch for timeout
   timeoutTimer = [NSTimer
		    scheduledTimerWithTimeInterval: sPostTimeout
		    target: self
		    selector: @selector(messageTimedOut:)
		    userInfo: nil
		    repeats: NO];
   [timeoutTimer retain];

}


- (CFHTTPMessageRef) buildHttpPostRequest: (NSString *) request_data url: (NSString *) url
{

   CFHTTPMessageRef message;
   NSURL* request_url = [NSURL URLWithString:url];


   // Allocate and initialize a CFHTTPMessage
   message = CFHTTPMessageCreateRequest(
                     kCFAllocatorDefault,
                     CFSTR("POST"),
                     (CFURLRef) request_url,
                     kCFHTTPVersion1_1);
   
   // Set the message headers
   CFHTTPMessageSetHeaderFieldValue(message,
				    CFSTR("User-Agent"),
				    CFSTR("Generic/1.0 (WF-PowerSearch)"));
   CFHTTPMessageSetHeaderFieldValue(message,
				    CFSTR("Content-Type"),
				    CFSTR("application/x-www-form-urlencoded"));
   CFHTTPMessageSetHeaderFieldValue(message,
				    CFSTR("Host"),
				    (CFStringRef) [request_url host]);
   CFHTTPMessageSetHeaderFieldValue(message,
				    CFSTR("Accept"),
				    CFSTR("text/html"));


   NSData*  postStringData = [request_data
               dataUsingEncoding: kCFStringEncodingASCII
               allowLossyConversion: YES];

   CFHTTPMessageSetBody(message,(CFDataRef) postStringData);


   CFHTTPMessageSetHeaderFieldValue(message,
            CFSTR("Content-Length"),
            (CFStringRef) [NSString stringWithFormat: @"%d",
               [postStringData length]]);

   return message;
}

/**
 * Returns the contents <i>(NSTring *)</i> of the possible Reply. 
 * Will return nil if no reply was received.
 * @see \ref post_protocol "httpPostResult"
 */
- (NSString *) replyContent {
	return (NSString *) m_cfReplyContent;
}


// set client delegate object.
-(void) setResponseClient: (id) a_client
{
  m_ClientDelegate = a_client;
}



@end
