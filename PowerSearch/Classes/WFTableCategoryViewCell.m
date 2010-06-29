/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFTableCategoryViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "WFImageLoader.h"


@interface WFTableCategoryViewCell()
- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation WFTableCategoryViewCell

#define LABEL_COLUMN_OFFSET 55
#define LABEL_COLUMN_WIDTH 270
#define LABEL_COLUMN_HEIGHT 28

#define IMAGE_OFFSET_TO_CENTER 26
#define IMAGE_MAX_WIDTH 50
#define IMAGE_MAX_HEIGHT 50

@synthesize labelCategoryName, imageView;


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
		UIView *myContentView = self.contentView;
        
        // Add an image view to display the Image of the Content provider.
		self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-icon.png"] ];
		[myContentView addSubview:self.imageView];
        [imageView release];
		
        // A label that displays the CategoryName.
        self.labelCategoryName = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:16.0 bold:YES]; 
		self.labelCategoryName.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelCategoryName];
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"list-item-background.png"]];
        self.backgroundView = backgroundImageView;
        [backgroundImageView release];
        
        UIImageView *selectedBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"list-item-background-processing.png"]];
        self.selectedBackgroundView = selectedBackgroundImageView;
        [selectedBackgroundImageView release];
        
        // Position the ImageView above all of the other views so
        // it's not obscured. It's a transparent image, so any views
        // that overlap it will still be visible.
        [myContentView bringSubviewToFront:self.imageView];
    }
    return self;
}

- (void)setCell:(id)category
{    
    WFImageLoader *loader = [WFImageLoader SharedImageLoader];
    NSString *imageName = [category valueForKey:@"image_name"];
    
    if (nil != imageName && [imageName length] > 0) {
        [loader loadImageNamed:imageName to:self.imageView];
    }
    else
        self.imageView.image = [UIImage imageNamed:@"placeholder-icon.png"];
    
    self.labelCategoryName.text = [category valueForKey:@"name"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
	
	if (!self.editing) {
		
        CGFloat boundsX = contentRect.origin.x;
        CGFloat cellHeightCenter = contentRect.size.height / 2;
		CGRect frame;
        
        // Place the location label.
		frame = CGRectMake(boundsX + LABEL_COLUMN_OFFSET, cellHeightCenter - LABEL_COLUMN_HEIGHT / 2,
                           LABEL_COLUMN_WIDTH, LABEL_COLUMN_HEIGHT);
		self.labelCategoryName.frame = frame;
        
        frame = CGRectMake((int)(boundsX + IMAGE_OFFSET_TO_CENTER - self.imageView.image.size.width / 2),
                           (int)(cellHeightCenter - self.imageView.image.size.height / 2),
                           self.imageView.image.size.width, self.imageView.image.size.height);
        self.imageView.frame = frame;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	UIColor *backgroundColor = [UIColor clearColor];
    
	self.labelCategoryName.highlighted = selected;
	self.labelCategoryName.opaque = !selected;
	
	self.imageView.backgroundColor = backgroundColor;
}

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold
{
	UIFont *font;
    if (bold) 
        font = [UIFont boldSystemFontOfSize:fontSize];
    else 
        font = [UIFont systemFontOfSize:fontSize];
   	
	UILabel *newLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	
	return newLabel;
}

@end
