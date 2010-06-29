/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFHRSViewCell.h"

@interface WFHRSViewCell()

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end


#define LEFT_COLUMN_OFFSET 55
#define LEFT_COLUMN_WIDTH 240
#define LARGE_LABEL_HEIGHT 28
#define SMALL_LABEL_HEIGHT 15
#define UPPER_ROW_TOP 0
#define MIDDLE_ROW_TOP 23
#define IMAGE_OFFSET_TO_CENTER 26


@implementation WFHRSViewCell

@synthesize labelName, labelValue;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        UIView *myContentView = self.contentView;
        
        // A label that displays the Name.
        self.labelName = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES]; 
		self.labelName.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelName];
		
		// A label that displays the Location Name.
		self.labelValue = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:10.0 bold:NO]; 
		self.labelValue.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelValue];
        
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
	
	if (!self.editing) {
		
        CGFloat boundsX = contentRect.origin.x;
        CGRect frame;
        
        // Place the Name label.
        frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP, LEFT_COLUMN_WIDTH, LARGE_LABEL_HEIGHT);
		self.labelName.frame = frame;
		
		// Place the LocationName label.
		frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, MIDDLE_ROW_TOP, LEFT_COLUMN_WIDTH, SMALL_LABEL_HEIGHT);
		self.labelValue.frame = frame;
    }
}


- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
    
    UIFont *font;
    if (bold) {
        font = [UIFont boldSystemFontOfSize:fontSize];
    } else {
        font = [UIFont systemFontOfSize:fontSize];
    }
    
	UILabel *newLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}


- (void) setCell:(NSDictionary *)cellDetails forSection:(int)section
{    
	self.labelName.text = [cellDetails objectForKey:@"name"];
    self.labelValue.text = [cellDetails objectForKey:@"value"];
    self.image = [UIImage imageNamed:[cellDetails objectForKey:@"image"]];    
}



- (void)dealloc 
{    
	[super dealloc];
}


@end
