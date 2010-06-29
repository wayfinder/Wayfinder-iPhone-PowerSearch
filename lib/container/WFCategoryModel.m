/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFCategoryModel.h"

// Name of application state file
NSString *CATEGORY_FILE_NAME = @"categories.archive";
// Name of category CRC in user settings
NSString *CATEGORY_CRC_SETTING = @"WFCategoryCrc";

@interface WFCategoryModel()
- (void)downloadTimerFired:(NSTimer*)theTimer;
@end

@implementation WFCategoryModel

@synthesize delegate;

static WFCategoryModel *SharedCategoryArray;

+ (WFCategoryModel*) SharedCategoryArray 
{
	if(SharedCategoryArray == nil) 
	{
		[[self alloc] init];		
	}
	return SharedCategoryArray;
}

+ (id) allocWithZone:(NSZone *)zone 
{
	if(SharedCategoryArray == nil) 
	{
		SharedCategoryArray = [super allocWithZone:zone];
		return SharedCategoryArray;
	}
	return nil;
}

-(id) init
{
	if (self = [super init])
	{
        wroteCrc = NO;
        
        // Load old category list
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES); 
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:CATEGORY_FILE_NAME];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            categoriesArray = [[NSKeyedUnarchiver unarchiveObjectWithFile:filePath] retain];
        }
        
        // Fetch old CRC value from user settings
        if (categoriesArray)
            oldCrc = [[[NSUserDefaults standardUserDefaults] objectForKey:CATEGORY_CRC_SETTING] mutableCopy];
        
        if (!oldCrc || !categoriesArray)
            oldCrc = [NSString stringWithString:@"0"];
        
        // If list loading failed, create new.
        if (!categoriesArray) {
            transactionStatus = InProgress;
        }
        else {
            /* We managed to load the old category list. Let's just use it for this run and
             * start using a new one if it's downloaded in the next startup.
             */
            transactionStatus = Finish;
        }
        
        xmlService = [[WFXMLService alloc] init];
        
        xmlService.delegate = self;
        
        downloadTrId = [[xmlService categoryRequestWithCrc:oldCrc] retain];
        
        if (listDownloadTimeout) {
            [listDownloadTimeout invalidate]; // must do this, otherwise runLoop will retain this
            [listDownloadTimeout release];
        }
        
        listDownloadTimeout = [[NSTimer scheduledTimerWithTimeInterval:10
                                                                target:self
                                                              selector:@selector(downloadTimerFired:)
                                                              userInfo:[[NSNumber alloc] initWithInt:10]
                                                               repeats:NO] retain];
        
        [delegate categoryTransactionStatus:transactionStatus];
	}
    return self;		
}

- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError transActionId:(NSString *)Id
{
    NSLog(@"Category fetch failed (error ID: %@, transaction ID: %@", anError, Id);
    transactionStatus = Abort;
    [delegate categoryTransactionStatus:transactionStatus];
}

- (void)service:(WFXMLService *)service didFinishTransAction:(NSString *)Id
{
    if (listDownloadTimeout) {
        [listDownloadTimeout invalidate];
        listDownloadTimeout = nil;
    }
    [downloadTrId release];
    
    if (Finish != transactionStatus) {
        // We have no old list. Copy the new list.
        categoriesArray = [[NSArray alloc] initWithArray:newCategoryList];
        
        transactionStatus = Finish;
        [delegate categoryTransactionStatus:transactionStatus];
    }
    
    // Write category list to file if necessary
    if (wroteCrc) {
        // We have received a new CRC so also write list to file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES); 
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:CATEGORY_FILE_NAME];
        
        if (![NSKeyedArchiver archiveRootObject:newCategoryList toFile:filePath])
            NSLog(@"Category list file writing failed.");
    }
    [newCategoryList release];
}

- (TransactionStatus)getTransactionStatus
{
    return transactionStatus;
}

- (void)service:(WFXMLService *)service didReceiveCategory:(NSDictionary *)items crc:(NSString *)crc
    transActionId:(NSString *)trId
{
    if (!wroteCrc) {
        // We have not wrote the new CRC to settings, do it now
        [[NSUserDefaults standardUserDefaults] setObject:crc forKey:CATEGORY_CRC_SETTING];
        
        wroteCrc = YES;
        
        // Also, old category list is loaded, release it
        //[categoriesArray removeAllObjects];
        
    }
    
    if (!newCategoryList)
        newCategoryList = [[NSMutableArray alloc] init];
    
    NSString *categoryName = [items valueForKey:@"cat_id"];
    NSString *name = [items valueForKey:@"name"];
    NSString *imageName = [items valueForKey:@"image_name"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 name, @"name", categoryName, @"cat_id", imageName, @"image_name", nil];
    
    [newCategoryList addObject:dict];
}


/*
 Returns the count of the CategoriesArray
 */
-(NSUInteger)getCategoriesCount
{
	return [categoriesArray count];
}


/*
 Returns the CategoriesArray
 */	
-(NSArray *)getCategoriesArray
{
	return [[categoriesArray copy]autorelease];
}


/*
 Returns the object at the specified index in the CategoriesArray
 */	
-(id)getCategoryAtIndex:(NSUInteger)theIndex
{
	return [categoriesArray objectAtIndex:theIndex];
}


/*
 Returns the object at the specified index and with the specified key in the CategoriesArray
 */	
-(id)getCategoryAtIndex:(NSUInteger)theIndex forKey:(NSString *)objectForKey
{
	return [[categoriesArray objectAtIndex:theIndex] objectForKey:objectForKey];
}

- (void)dealloc 
{
    if (listDownloadTimeout) 
        [listDownloadTimeout invalidate];
    [listDownloadTimeout release];
    [categoriesArray release];
    [xmlService release];
	[super dealloc];
}

- (void)downloadTimerFired:(NSTimer*)theTimer
{
    // Cancel old request and ask again
    if (downloadTrId) 
        [xmlService cancelTransAction:downloadTrId];
    [downloadTrId release];
    
    downloadTrId = [[xmlService categoryRequestWithCrc:oldCrc] retain];
    int timeout = [[theTimer userInfo] intValue];
    
    [[theTimer userInfo] release];
    [listDownloadTimeout invalidate];
    [listDownloadTimeout release];
    
    listDownloadTimeout = [[NSTimer scheduledTimerWithTimeInterval:timeout * 2
                                                            target:self
                                                          selector:@selector(downloadTimerFired:)
                                                          userInfo:[[NSNumber alloc] initWithInt:timeout * 2]
                                                           repeats:NO] retain];
}


- (id) mutableCopyWithZone:(NSZone *)zone
{
	return self;
}

- (id) copyWithZone:(NSZone *)zone 
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
