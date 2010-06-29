/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>
#import "WFXMLService.h"

@interface WFImageLoader : NSObject <WFXMLServiceDelegate>
{
@private
    // Save image pointer and change image after download. Then remove reference.
    NSMutableDictionary *downloadList;
    // Save loaded and downloaded UIImages to this list so they can be accessed quickly
    NSMutableDictionary *loadedPics;
    
    WFXMLService *service;
}

@property (nonatomic,retain) NSMutableDictionary *downloadList;

+ (WFImageLoader *)SharedImageLoader;

/*
 * Method for loading an image from file or server. Default image is
 * loaded if the given image name is not found and download is started
 * from server. Image is updated automatically when file arrives.
 *
 * NOTE: This method should only be used for files that are fetched from
 * server. If image is local, just load it with UIImage methods.
 */
- (BOOL)loadImageNamed:(NSString *)imageName to:(UIImageView *)imagePointer;
/*
 * Method for fetching an image from specific HTTP address. Also includes
 * maximum size for image bounds (use (0,0) for no restriction).
 */
- (BOOL)loadImageFromAddress:(NSString *)httpAddress
                          to:(UIImageView *)imagePointer
                     maxSize:(CGSize)maxSize;

@end
