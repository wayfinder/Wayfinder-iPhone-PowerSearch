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
#import "PowerSearchAppDelegate.h"
#import "WFResultsModel.h"
//#import "WFSearchController.h"
#import "WFAddrParser.h"

@class WFPropellerView;

@interface WFDetailsViewController : UITableViewController <WFResultModelDelegate, UIActionSheetDelegate>
{
    // Stuff for header
    UILabel *labelName;
    UILabel *labelPlace;
    UILabel *labelAddress;
    UIImageView *displayImage;
    UIImageView *frameImage; // For displaying custom photo frame
    UIView *tableHeader;
    
    // Stuff for footer
    UILabel *descriptionText;
    UIView *tableFooter;
    
    // Other stuff
    WFPropellerView *propellerView;
    NSMutableDictionary *itemDetails; // Detail items arranged in sections
    NSMutableArray *visibleSections; // List of sections that are in list
    NSMutableDictionary *addressInfo; // Collection of address and other "special" info
    NSDictionary *itemInfo; // Original item received in initialiseWithItem
    NSDictionary *itemToSection; // List for mapping item key to section
    WFAddrParser *addrParser;
    BOOL hasCustomImage;
    NSInteger addFavoriteButtonNbr;
    
    // Code that created the details controller must set the used result model.
    id detailSource;
}

@property (nonatomic, retain) NSDictionary *itemInfo;
@property (nonatomic, retain) UILabel *descriptionText;

- (void) setDetailSource:(id)model;
- (void) showDetailsForItem:(NSDictionary *)item;

@end
