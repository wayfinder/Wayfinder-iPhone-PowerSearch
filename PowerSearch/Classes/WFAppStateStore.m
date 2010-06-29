/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFAppStateStore.h"
#import "WFResultsModel.h"
//#import "WFSearchBarViewController.h"
//#import "WFMapViewController.h"
#import "constants.h"

// Name of application state file
NSString *APP_STATE_FILE_NAME = @"appstate.archive";
// How old search results are still used (in seconds)
double MAX_RESULT_USE_INTERVAL = 3600; /* 1 hour */

@interface WFAppStateStore (Category)
- (NSString *)getPath;
- (void)saveState:(id)sender;
- (void)loadState;
@end
    

@implementation WFAppStateStore

static WFAppStateStore *SharedStateStore;

+ (WFAppStateStore*)sharedStateStore 
{
	if(SharedStateStore == nil) 
	{
		SharedStateStore = [[self alloc] init];
    }
	
	return SharedStateStore;
}

- (id)init
{
    if (self = [super init])
    {
        NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
        [nCenter addObserver:self selector:@selector(saveState:)
                        name:UIApplicationWillTerminateNotification
                      object:nil];
    }
    return self;
}


- (void)dealloc
{
    [appState release];
    [super dealloc];
}


- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    [appState setObject:object forKey:key];
}


- (id)objectForKey:(NSString *)key
{
    if (!appState)
        [self loadState];

    return [appState objectForKey:key];
}


- (NSString *)getPath
{
    NSArray *appDirs =
        NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                            NSUserDomainMask,
                                            YES);
    return [[[appDirs objectAtIndex:0]
        stringByAppendingPathComponent:@"PowerSearch"]
        stringByAppendingPathComponent:APP_STATE_FILE_NAME];
}


- (void)saveState:(id)sender
{
    NSString *filePath = [self getPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        NSString *path = [filePath stringByDeletingLastPathComponent];
        
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES
                                attributes:nil error:nil];
    }

    [NSKeyedArchiver archiveRootObject:appState toFile:[self getPath]];
}


- (void)loadState
{
    NSString *filePath = [self getPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Load search result data if it's not too old
    if ([fileManager fileExistsAtPath:filePath]) {
        NSDictionary *fileAttributes = [fileManager
            fileAttributesAtPath:filePath traverseLink:YES];

        if (fabs([[fileAttributes objectForKey:NSFileModificationDate]
                timeIntervalSinceNow]) < MAX_RESULT_USE_INTERVAL) {
            appState = [[NSKeyedUnarchiver unarchiveObjectWithFile:filePath]
                retain];
            return;
        }
    }

    appState = [[NSMutableDictionary alloc] init];
}


@end
