/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "WFAboutViewController.h"
#import "WFCommandRouter.h"
#import "constants.h"

@interface WFAboutViewController()
- (UILabel *)newLabelWithFontSize:(CGFloat)fontSize bold:(BOOL)bold numberOfLiner:(int)lineNum;
@end

@implementation WFAboutViewController

- (void)loadView {
    // Create empty dark background
    bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    bgView.backgroundColor = [UIColor WFDarkBackgroundGray];
    bgView.userInteractionEnabled = YES;
    
    self.view = bgView;
    
    // Create images

    // Create labels
    // versionTitle = [self newLabelWithFontSize:14 bold:NO numberOfLiner:1];
    // versionTitle.frame = CGRectMake(20, 232, 280, 18);
    // copyrightLabel = [self newLabelWithFontSize:11 bold:NO numberOfLiner:1];
    // copyrightLabel.frame = CGRectMake(20, 252, 280, 21);
    // urlLabel = [self newLabelWithFontSize:10 bold:NO numberOfLiner:1];
    // urlLabel.frame = CGRectMake(20, 266, 280, 21);
    // dataSourceLabel = [self newLabelWithFontSize:10 bold:NO numberOfLiner:1];
    // dataSourceLabel.frame = CGRectMake(20, 294, 280, 21);
    copyrightLabel2 = [self newLabelWithFontSize:11 bold:NO numberOfLiner:1];
    copyrightLabel2.frame = CGRectMake(0, 0, 280, 18); //CGRectMake(20, 311, 280, 21);
    providerLabel = [self newLabelWithFontSize:10 bold:NO numberOfLiner:40];
    providerLabel.frame = CGRectMake(0, 5, 320, 460); //(20, 331, 280, 62);
    // licenseLabel = [self newLabelWithFontSize:10 bold:NO numberOfLiner:5];
    // licenseLabel.frame = CGRectMake(20, 401, 280, 51);
    // licenseLabel.lineBreakMode = UILineBreakModeTailTruncation;
    
    // Set label properties
    providerLabel.adjustsFontSizeToFitWidth = YES;
    providerLabel.minimumFontSize = 8.0;
    licenseLabel.adjustsFontSizeToFitWidth = YES;
    licenseLabel.minimumFontSize = 8.0;

    
     providerLabel.text = @"Copyright (c) 1999 - 2010, Vodafone Group Services Ltd\nAll rights reserved.\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n* Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";

    copyrightLabel2.text = @"COPYRIGHT MAP PROVIDER HERE";
//    licenseLabel.text = NSLocalizedString(@"License",@"License Label text");
    
    UIImageView *upperShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"panel-shaddow-bottom.png"]];
    UIImageView *lowerShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"panel-shaddow-top.png"]];
    upperShadow.center = CGPointMake(160, (int)(upperShadow.bounds.size.height / 2));
    lowerShadow.center = CGPointMake(160, (int)(460 - lowerShadow.bounds.size.height / 2));
    
    // And finally add all views
    [bgView addSubview:logoImage];
    [bgView addSubview:signatureImage];
    [bgView addSubview:versionTitle];
    [bgView addSubview:copyrightLabel];
    [bgView addSubview:urlLabel];
    [bgView addSubview:dataSourceLabel];
    [bgView addSubview:copyrightLabel2];
    [bgView addSubview:providerLabel];
    [bgView addSubview:licenseLabel];
    [bgView addSubview:upperShadow];
    [bgView addSubview:lowerShadow];
    [bgView bringSubviewToFront:upperShadow];
    [bgView bringSubviewToFront:lowerShadow];
    [upperShadow release];
    [lowerShadow release];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    [[WFCommandRouter SharedCommandRouter] closeAboutView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [logoImage release];
    [signatureImage release];
    [versionTitle release];
    [copyrightLabel release];
    [urlLabel release];
    [dataSourceLabel release];
    [copyrightLabel2 release];
    [providerLabel release];
    [licenseLabel release];
    [bgView release];
    
    [super dealloc];
}

- (UILabel *)newLabelWithFontSize:(CGFloat)fontSize bold:(BOOL)bold numberOfLiner:(int)lineNum
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
    newLabel.textColor = [UIColor whiteColor];
	newLabel.font = font;
    newLabel.numberOfLines = lineNum;
	
	return newLabel;
}

@end
