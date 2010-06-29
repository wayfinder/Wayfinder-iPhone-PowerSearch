/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFFileLogger.h"

@interface WFFileLogger()
- (void)resetFile;
- (void)writeToFile:(NSString *)msg;
@end

@implementation WFFileLogger

static WFFileLogger *sharedLogger = nil;

+ (WFFileLogger *)sharedLogger

{
    @synchronized(self) {
        if (sharedLogger == nil) {
            [[self alloc] init]; 
        }
    }
    return sharedLogger;
}



- (id)init

{
    @synchronized(self) {
        if (sharedLogger == nil) {
            sharedLogger = [super init];
            // dump previous file to NSLog
            [sharedLogger resetFile];
            return sharedLogger;  
        }
    }
    return nil;  
}

- (void)resetFile
{
    NSArray *cacheDirs =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *logPath = [[cacheDirs objectAtIndex:0]
                              stringByAppendingPathComponent:LOGFILE];
    NSString *log = [NSString stringWithContentsOfFile:logPath];
    NSLog(@"previous log: %@",log);
    // purge it.
    NSLog(@"END PREVIOUS LOG");
    [@"" writeToFile:logPath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
}

-(void) writeToFile:(NSString *)msg
{
    NSArray *cacheDirs =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *logPath = [[cacheDirs objectAtIndex:0]
                         stringByAppendingPathComponent:LOGFILE];
    [msg writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)log:(NSString *)msg sender:(id)anObject line:(int)lineno{
    // Save search result data
    NSArray *cacheDirs =
    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *logPath = [[cacheDirs objectAtIndex:0]
                         stringByAppendingPathComponent:LOGFILE];
    NSMutableString *log = [NSMutableString stringWithContentsOfFile:logPath];
    
    NSMutableString *new_msg = [[NSMutableString alloc] initWithFormat:@"%@ line:%d %@ \n", anObject, lineno, msg];
    if (log)
        [log appendString:new_msg];
    else
        log = new_msg;
     
    [self writeToFile:log];

    NSLog(@"%@", log);    
}

- (id)copyWithZone:(NSZone *)zone

{
    return self;    
}

- (id)retain
{
    return self;    
}

- (unsigned)retainCount

{
    return UINT_MAX; 
}

- (void)release
{
}


- (id)autorelease
{    
    return self;    
}

@end
