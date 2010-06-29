/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFTableListViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "WFImageLoader.h"
#import "WFCommandRouter.h"

@interface WFTableListViewCell()

- (UILabel *)newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold;
@end

@implementation WFTableListViewCell

#define LEFT_COLUMN_OFFSET 55
#define LEFT_COLUMN_WIDTH 200
#define LEFT_COLUMN_WIDTH_EDITING 170

#define MIDDLE_COLUMN_OFFSET 250
#define MIDDLE_COLUMN_WIDTH 100

#define DISTANCE_LABEL_OFFSET 110

#define LARGE_LABEL_HEIGHT 28
#define SMALL_LABEL_HEIGHT 15
#define LABEL_DISTANCE_WIDTH 125
#define MIDDLE_COLUMN_WIDTH 100

#define UPPER_ROW_TOP 0
#define MIDDLE_ROW_TOP 23
#define LOWER_ROW_TOP 38
#define CENTER_ROW_TOP 13

#define IMAGE_OFFSET_TO_CENTER 26
#define RESULT_NUMBER_OFFSET 272
#define RESULT_NUMBER_OFFSET_EDITING 240
#define RESULT_NUMBER_IMAGE_HEIGHT 23
#define RESULT_NUMBER_IMAGE_WIDTH 23

@synthesize labelName, labelLocationName, labelDistance, labelDistanceInMeters, labelIndex, imageView, activityView;


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
		UIView *myContentView = self.contentView;
        
        // Add an image view to display the Image of the Content provider.
		self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_panel_heart_icon.png"] ];
		[myContentView addSubview:self.imageView];
        [imageView release];
		
		// A label that displays the Name.
        self.labelName = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES]; 
		self.labelName.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelName];
		
		// A label that displays the Location Name.
		self.labelLocationName = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:10.0 bold:YES]; 
		self.labelLocationName.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelLocationName];
        
		
        // A label that displays the distance.
        self.labelDistanceInMeters = [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor blackColor] fontSize:10.0 bold:YES];
		self.labelDistanceInMeters.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelDistanceInMeters];
		
        
        // A label that displays the distance.
        self.labelDistance = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:10.0 bold:NO];
		self.labelDistance.textAlignment = UITextAlignmentLeft; // default
		[myContentView addSubview:self.labelDistance];
        
        
        // A label that displays the Index Number.
        self.labelIndex = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		self.labelIndex.textAlignment = UITextAlignmentCenter;
        self.labelIndex.adjustsFontSizeToFitWidth = YES;
		[myContentView addSubview:self.labelIndex];
        
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [myContentView addSubview:self.activityView];
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search-list-item-background.png"]];
        self.backgroundView = backgroundImageView;
        [backgroundImageView release];
        
        UIImageView *selectedBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search-list-item-background-processing.png"]];
        self.selectedBackgroundView = selectedBackgroundImageView;
        [selectedBackgroundImageView release];
        
        // Position the ImageView above all of the other views so
        // it's not obscured. It's a transparent image, so any views
        // that overlap it will still be visible.
        [myContentView bringSubviewToFront:self.imageView];
		
        isShowMoreCell = NO;
        cmdRouter = [WFCommandRouter SharedCommandRouter];
    }
    return self;
}

- (void)showMoreCell
{
    self.accessoryType = UITableViewCellAccessoryNone;
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:
                                        [UIImage imageNamed:@"search-list-item-background-clean.png"]];
    self.backgroundView = backgroundImageView;
    [backgroundImageView release];
    
    UIImageView *selectedBackgroundImageView = [[UIImageView alloc] initWithImage:
                                                [UIImage imageNamed:@"search-list-item-background-processing-clean.png"]];
    self.selectedBackgroundView = selectedBackgroundImageView;
    [selectedBackgroundImageView release];
    
    self.labelName.textAlignment = UITextAlignmentCenter;
    self.labelName.text = NSLocalizedString(@"Show more results", @"Show more results in list");
    
    // This is done just to tell the image loader that this cell is reused
    [[WFImageLoader SharedImageLoader] loadImageNamed:@"placeholder-icon.png" to:self.imageView];
    self.imageView.image = nil;
    self.labelLocationName.text = @"";
    self.labelDistanceInMeters.text = @"";
    self.labelIndex.text = @"";
    self.labelDistance.text = @"";
    isShowMoreCell = YES;
}

- (void)setCell:(id)results
{
    // Return correct background image if necessary
    if (isShowMoreCell){
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:
                                            [UIImage imageNamed:@"search-list-item-background.png"]];
        self.backgroundView = backgroundImageView;
        [backgroundImageView release];
        
        UIImageView *selectedBackgroundImageView = [[UIImageView alloc] initWithImage:
                                                    [UIImage imageNamed:@"search-list-item-background-processing.png"]];
        self.selectedBackgroundView = selectedBackgroundImageView;
        [selectedBackgroundImageView release];
        self.labelName.textAlignment = UITextAlignmentLeft;
        
        [self.activityView stopAnimating];
        isShowMoreCell = NO;
    }
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    WFImageLoader *loader = [WFImageLoader SharedImageLoader];
    NSString *imageName = [results valueForKey:@"image"];
    
    if (nil != imageName && [imageName length] > 0) {
        [loader loadImageNamed:imageName to:self.imageView];
    }
    else
        self.imageView.image = [UIImage imageNamed:@"placeholder-icon.png"];
    
    self.labelName.text = [results valueForKey:@"name"];
    self.labelLocationName.text = [results valueForKey:@"location_name"];
    self.labelDistanceInMeters.text = [cmdRouter distanceToString:[results valueForKey:@"distance"]];
    self.labelDistance.text = NSLocalizedString(@"Distance:", @"Distance to list item");
    self.labelIndex.text = @"1";
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGFloat cellHeightCenter = contentRect.size.height / 2;
    CGRect frame;
	
	if (!self.editing) {
        
        // Place the Name label.
        if (isShowMoreCell)
            frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, CENTER_ROW_TOP, LEFT_COLUMN_WIDTH, LARGE_LABEL_HEIGHT);
        else
            frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP, LEFT_COLUMN_WIDTH, LARGE_LABEL_HEIGHT);
		self.labelName.frame = frame;
		
		// Place the LocationName label.
		frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, MIDDLE_ROW_TOP, LEFT_COLUMN_WIDTH, SMALL_LABEL_HEIGHT);
		self.labelLocationName.frame = frame;
        
        // Place the DistanceInMeters label.
		frame = CGRectMake(boundsX + DISTANCE_LABEL_OFFSET , LOWER_ROW_TOP, LABEL_DISTANCE_WIDTH , SMALL_LABEL_HEIGHT);
		self.labelDistanceInMeters.frame = frame;
        
        // Place the Distance label.
		frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET , LOWER_ROW_TOP, MIDDLE_COLUMN_WIDTH , SMALL_LABEL_HEIGHT);
		self.labelDistance.frame = frame;
        
        // Content provider image is set in setCell.
        frame = CGRectMake((int)(boundsX + IMAGE_OFFSET_TO_CENTER - self.imageView.image.size.width / 2),
                           (int)(cellHeightCenter - self.imageView.image.size.height / 2),
                           self.imageView.image.size.width, self.imageView.image.size.height);
        self.imageView.frame = frame;
		
		// Place the Index label.
        frame = CGRectMake((boundsX + RESULT_NUMBER_OFFSET - RESULT_NUMBER_IMAGE_WIDTH / 2),
                           (int)(cellHeightCenter - RESULT_NUMBER_IMAGE_HEIGHT / 2 - 1),
                           RESULT_NUMBER_IMAGE_WIDTH, RESULT_NUMBER_IMAGE_HEIGHT);
        self.labelIndex.frame = frame;
        
        self.activityView.center = CGPointMake(boundsX + RESULT_NUMBER_OFFSET, cellHeightCenter);
    }
    else {
        // Editing cell
        frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP, LEFT_COLUMN_WIDTH_EDITING, LARGE_LABEL_HEIGHT);
		self.labelName.frame = frame;
        
		frame = CGRectMake(boundsX + DISTANCE_LABEL_OFFSET , LOWER_ROW_TOP, LABEL_DISTANCE_WIDTH , SMALL_LABEL_HEIGHT);
		self.labelDistanceInMeters.frame = frame;
        
		frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET , LOWER_ROW_TOP, MIDDLE_COLUMN_WIDTH , SMALL_LABEL_HEIGHT);
		self.labelDistance.frame = frame;
        
        frame = CGRectMake((int)(boundsX + IMAGE_OFFSET_TO_CENTER - self.imageView.image.size.width / 2),
                           (int)(cellHeightCenter - self.imageView.image.size.height / 2),
                           self.imageView.image.size.width, self.imageView.image.size.height);
        self.imageView.frame = frame;
        
        frame = CGRectMake((boundsX + RESULT_NUMBER_OFFSET_EDITING - RESULT_NUMBER_IMAGE_WIDTH / 2),
                           (int)(cellHeightCenter - RESULT_NUMBER_IMAGE_HEIGHT / 2 - 1),
                           RESULT_NUMBER_IMAGE_WIDTH, RESULT_NUMBER_IMAGE_HEIGHT);
        self.labelIndex.frame = frame;
        
        frame = CGRectMake(boundsX + LEFT_COLUMN_OFFSET, MIDDLE_ROW_TOP, LEFT_COLUMN_WIDTH_EDITING, SMALL_LABEL_HEIGHT);
		self.labelLocationName.frame = frame;
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


- (void)dealloc 
{    
	[super dealloc];
}

@end
