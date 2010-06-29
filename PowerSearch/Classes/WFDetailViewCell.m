/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFDetailViewCell.h"
#import "constants.h"
#import <QuartzCore/QuartzCore.h>

@interface WFDetailViewCell()

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end


@implementation WFDetailViewCell

@synthesize textLabel;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
        UIView *myContentView = self.contentView;
        
		// A label that displays the detail cell.
        self.textLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] 
                               selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES]; 
        self.textLabel.textAlignment = UITextAlignmentLeft; // default
        self.textLabel.minimumFontSize = 10;
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        [myContentView addSubview:self.textLabel];
    }
    return self;
}


- (void)layoutSubviews
{
	
#define LABEL_COLUMN_OFFSET 55
#define NO_IMAGE_LABEL_COLUMN_OFFSET 10
#define LABEL_COLUMN_WIDTH 240
#define LABEL_HEIGHT 28
#define IMAGE_OFFSET 3
#define IMAGE_HEIGHT 35
#define IMAGE_WIDTH 35
#define BACKGND_WIDTH 295	
#define ROW_TOP_OFFSET 6    
    
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
	
    if (!self.editing) {
		
        CGFloat boundsX = contentRect.origin.x;
		CGRect frame;
        
        // Place the location label.
        if (nil == self.image)
            frame = CGRectMake(boundsX + NO_IMAGE_LABEL_COLUMN_OFFSET, ROW_TOP_OFFSET, LABEL_COLUMN_WIDTH + (LABEL_COLUMN_OFFSET - NO_IMAGE_LABEL_COLUMN_OFFSET), LABEL_HEIGHT);
        else
            frame = CGRectMake(boundsX + LABEL_COLUMN_OFFSET, ROW_TOP_OFFSET, LABEL_COLUMN_WIDTH , LABEL_HEIGHT);
		self.textLabel.frame = frame;		
    }
}


- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor 
                        selectedColor:(UIColor *)selectedColor 
                             fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
    /*
      Create and configure a label.
    */
	
    UIFont *font;
    if (bold) 
        font = [UIFont boldSystemFontOfSize:fontSize];
    else 
        font = [UIFont systemFontOfSize:fontSize];
    
    /*
	 Views are drawn most efficiently when they are opaque and do not have a clear background, so set these defaults.  To show selection properly, however, the views need to be transparent (so that the selection color shows through).  This is handled in setSelected:animated:.
	 */
	
    UILabel *newLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    newLabel.backgroundColor = [UIColor clearColor];
    newLabel.opaque = YES;
    newLabel.textColor = primaryColor;
    newLabel.highlightedTextColor = selectedColor;
    newLabel.font = font;
	
    return newLabel;
}

- (void) setCell:(NSDictionary *)cellInfo forSection:(int)section
{
    if ([cellInfo objectForKey:@"image"])
        self.image = [UIImage imageNamed:[cellInfo objectForKey:@"image"]];
    else
        self.image = nil;
    
    
    if ( (section != ContactsSection) && (nil != [cellInfo objectForKey:@"name"]) ){
        self.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                           [cellInfo objectForKey:@"name"], [cellInfo objectForKey:@"value"]];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    else {
        self.textLabel.text = [NSString stringWithFormat:@"%@", [cellInfo objectForKey:@"value"]];  
        self.textLabel.adjustsFontSizeToFitWidth = NO;
        self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    } 
}

@end
