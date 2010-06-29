/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFImageLoader.h"
#import "constants.h"

// Image that is shown when waiting the correct image from server
static NSString *DEFAULT_IMAGE_FILE_NAME = @"placeholder-icon.png";
// Image ptr string
static NSString *STR_IMAGE_PTR = @"image_ptr";
// Pointer duplicate string
static NSString *STR_DUPLICATE_PTR = @"ptrIsDuplicate";

@interface WFImageLoader()
- (void)setImage:(UIImage *)image toView:(UIImageView *)imageView  maxSize:(CGSize)maxSize;
- (BOOL)loadName:(NSString *)dlName to:(UIImageView *)imagePointer
         maxSize:(CGSize)maxSize WithDefaultServer:(BOOL)useDefaultServer;
@end

@implementation WFImageLoader

@synthesize downloadList;

static WFImageLoader *SharedImageLoader;

+ (WFImageLoader*) SharedImageLoader
{
	if(SharedImageLoader == nil) 
	{
		SharedImageLoader = [[self alloc] init];
    }
	
	return SharedImageLoader;
}

- (id)init
{
    if (self = [super init])
	{
        downloadList = [[NSMutableDictionary dictionary] retain];
        loadedPics = [[NSMutableDictionary dictionary] retain];
        
        // Load the default image so it's always found from list
        if (nil != [UIImage imageNamed:DEFAULT_IMAGE_FILE_NAME])
            [loadedPics setObject:[UIImage imageNamed:DEFAULT_IMAGE_FILE_NAME] forKey:DEFAULT_IMAGE_FILE_NAME];
        else {
            NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:DEFAULT_IMAGE_FILE_NAME];
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            
            if (nil != image)
                [loadedPics setObject:[UIImage imageWithContentsOfFile:filePath] forKey:DEFAULT_IMAGE_FILE_NAME];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [downloadList release];
    [loadedPics release];
    [service release];
    [super dealloc];
}

- (void)service:(WFXMLService *)service didFailWithError:(NSError *)anError
  transActionId:(NSString *)Id
{
    //transactionStatus = Abort;
}

- (void)service:(WFXMLService *)service didReceiveMapImage:(UIImage *)image
  transActionId:(NSString *)Id
{
    NSMutableArray *objects = [downloadList objectForKey:Id];
    UIImageView *oldImage;
    BOOL savedImage = NO;
    
    // Check that image was truly received.
    if (nil != image) {
        // Many views could be waiting for the same image. Check them all
        for (NSMutableDictionary *element in objects) {
            oldImage = [element objectForKey:STR_IMAGE_PTR];
            
            if (nil != oldImage) {
                /* If the pointer has been replaced by a new entry, just save the downloaded
                 * image but don't touch the pointer. Can happen if user scrolls the list
                 * quickly and images are not downloaded fast enough.
                 */
                if ([[element objectForKey:STR_DUPLICATE_PTR] isEqual:@"NO"]) {
                    // Let's change the default image to downloaded one
                    CGSize maxS = CGSizeMake([[element objectForKey:STR_MAX_WIDTH] floatValue],
                                             [[element objectForKey:STR_MAX_HEIGHT] floatValue]);
                    [self setImage:image toView:oldImage maxSize:maxS];
                }
                
                if (!savedImage) {
                    // Save received image to list
                    [loadedPics setObject:image forKey:[element objectForKey:STR_IMAGE_NAME]];
                    savedImage = YES;
                    
                    if ([[element objectForKey:STR_IMAGE_SAVE] boolValue]) {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                                             NSUserDomainMask, YES); 
                        NSString *filePath = [[paths objectAtIndex:0]
                                              stringByAppendingPathComponent:[element objectForKey:STR_IMAGE_NAME]];
                        [UIImagePNGRepresentation(image) writeToFile:filePath atomically:NO];
                    }
                }
            }
        }
    }
    
    // And remove reference from list
    [downloadList removeObjectForKey:Id];
}

- (void)setImage:(UIImage *)image toView:(UIImageView *)imageView  maxSize:(CGSize)maxSize
{
    CGFloat useWidth, useHeight;
    CGPoint center;
    center.x = (int)imageView.center.x;
    center.y = (int)imageView.center.y;
    imageView.image = image;
    
    if (maxSize.height >  0 && maxSize.width > 0) {
        if (image.size.height > maxSize.height)
            useHeight = maxSize.height;
        else
            useHeight = image.size.height;
        if (image.size.width > maxSize.width)
            useWidth = maxSize.width;
        else
            useWidth = image.size.width;
    }
    else {
        useHeight = image.size.height;
        useWidth = image.size.width;
    }
    
    imageView.bounds = CGRectMake(0, 0, useWidth, useHeight);
    imageView.center = center;
}

/*
 * Notes about downloadList structure. This dictionary contains NSMutableArrays
 * which in turn include request details. Transaction ID received from XML
 * service is used for key in downloadList. Multiple requests for the same
 * image name are placed in the array so that when the image arrives, all can
 * be replaced at the same time. Naturally this list is only needed for images
 * that are not yet downloaded.
 */
- (BOOL)loadName:(NSString *)dlName to:(UIImageView *)imagePointer
         maxSize:(CGSize)maxSize WithDefaultServer:(BOOL)useDefaultServer
{
    BOOL alreadyLoading = NO;
    NSString *trId;
    
    // First check that this pointer is not duplicate
    for (NSString *key in downloadList) {
        for (NSMutableDictionary *element in [downloadList objectForKey:key]) {
            if (imagePointer == [element objectForKey:STR_IMAGE_PTR]) {
                // This view pointer is already in the list. Mark the old one as duplicate
                [element setObject:@"YES" forKey:STR_DUPLICATE_PTR];
            }
            // Also check that this image is not already on downloaded list.
            if ([dlName isEqual:[element objectForKey:STR_IMAGE_NAME]]) {
                alreadyLoading = YES;
                trId = key;
            }
        }
    }
    
    // See if this image has already been downloaded
    if (nil != [loadedPics objectForKey:dlName]) {
        // We can just return the image straight away
        [self setImage:[loadedPics objectForKey:dlName] toView:imagePointer maxSize:maxSize];
        return YES;
    }
    
    // Image may also be saved to file (only for images from default server)
    if (useDefaultServer) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES); 
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:dlName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            // Image saved to file
            [loadedPics setObject:[UIImage imageWithContentsOfFile:filePath] forKey:dlName];
            
            [self setImage:[loadedPics objectForKey:dlName] toView:imagePointer maxSize:maxSize];
            return YES;
        }
    }
    
    // Return default image and load image from server
    [self setImage:[loadedPics objectForKey:DEFAULT_IMAGE_FILE_NAME] toView:imagePointer maxSize:maxSize];
    
    if (nil == service) {
        service = [[WFXMLService service] retain];
        service.delegate = self;
    }
    
    if (!alreadyLoading) {
        if (useDefaultServer)
            trId = [service fetchImageWithName:dlName];
        else
            trId = [service fetchImageFromAddress:dlName];
    }
    
    NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithObjectsAndKeys:imagePointer, STR_IMAGE_PTR,
                                    dlName, STR_IMAGE_NAME,
                                    @"NO", STR_DUPLICATE_PTR,
                                    [NSNumber numberWithBool:useDefaultServer] ,STR_IMAGE_SAVE,
                                    [NSNumber numberWithFloat:maxSize.width], STR_MAX_WIDTH,
                                    [NSNumber numberWithFloat:maxSize.height], STR_MAX_HEIGHT, nil];
    
    if (alreadyLoading)
        [[downloadList objectForKey:trId] addObject:objects];
    else {
        NSMutableArray *newArray = [NSMutableArray arrayWithObject:objects];
        [downloadList setObject:newArray forKey:trId];
    }
    
    return YES;
}

- (BOOL)loadImageNamed:(NSString *)imageName to:(UIImageView *)imagePointer
{
    return [self loadName:imageName to:imagePointer maxSize:CGSizeMake(0,0) WithDefaultServer:YES];
}

- (BOOL)loadImageFromAddress:(NSString *)httpAddress to:(UIImageView *)imagePointer maxSize:(CGSize)maxSize
{
    return [self loadName:httpAddress to:imagePointer maxSize:maxSize WithDefaultServer:NO];
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
