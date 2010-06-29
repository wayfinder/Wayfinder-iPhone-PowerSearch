/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFNetworkDetector.h"
#import "constants.h"


@implementation WFNetworkDetector

- (void)dealloc
{
    if (netReach) 
        CFRelease(netReach);
    [super dealloc];
}

void networkReachabilityCallBack(SCNetworkReachabilityRef target,
                                 SCNetworkReachabilityFlags flags,
                                 void *info)
{
    WFNetworkDetector *vc = (WFNetworkDetector*)info;
    
    SCNetworkReachabilityUnscheduleFromRunLoop(vc->netReach,
                                               CFRunLoopGetCurrent(), 
                                               kCFRunLoopDefaultMode);
    if (vc->netReach) {
        Boolean result = SCNetworkReachabilityGetFlags(vc->netReach, &flags);
        if (result && (flags & kSCNetworkReachabilityFlagsReachable) ) {
            if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
                NSLog(@"3G connection ok.");
            }
            else {             
                NSLog(@"WiFi connection ok.");
            }
        }
        else {
            if ([vc->limitTime compare:[NSDate dateWithTimeIntervalSinceNow:0]] == NSOrderedDescending) {
                //no WiFi, neither 3G
                NSLog(@"Turn WiFi or 3G on.");
                UIAlertView *alert = [[UIAlertView alloc] 
                                      initWithTitle:@"Network Status" message:@"No network connections found.\nTurn WiFi or 3G on."
                                      delegate:vc cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                [alert release];
            }
            else {
                //we probably have WiFi, but it's not usable
                NSLog(@"Your WiFi is not working. Turn it off and use 3G.");
                UIAlertView *alert = [[UIAlertView alloc] 
                                      initWithTitle:@"Network Status" message:@"Your WiFi is not working.\nTurn it off and use 3G."
                                      delegate:vc cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                [alert release];
            }
            [vc->limitTime release];  
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application isNetworkActivityIndicatorVisible] == YES) {  
        [application setNetworkActivityIndicatorVisible:NO]; 
    }
}


- (void)checkNetworkAvailable
{
    if (netReach) {
        CFRelease(netReach);
        netReach = nil;
    }
    
    if (!netReach) {
        limitTime = [[NSDate dateWithTimeIntervalSinceNow:55] retain];  
        netReach = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [STR_HOSTNAME UTF8String]);
        
        SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
        Boolean result = SCNetworkReachabilitySetCallback(netReach, 
                                                          networkReachabilityCallBack, 
                                                          &context);
        if (result) {
            result = SCNetworkReachabilityScheduleWithRunLoop(netReach,
                                                              CFRunLoopGetCurrent(), 
                                                              kCFRunLoopDefaultMode);   
            if (!result) {
                NSLog(@"Network Reachability couldn't be scheduled on run loop.");
            }
            else {
                UIApplication *application = [UIApplication sharedApplication];
                if([application isNetworkActivityIndicatorVisible] == NO) {  
                    [application setNetworkActivityIndicatorVisible:YES]; 
                }
            }
        }
        else {
            NSLog(@"Callback function could not be set.");
        }
    }
}

@end
