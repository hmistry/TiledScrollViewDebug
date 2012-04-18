/*
 Modified by Hiren Mistry (Chai Monsters, LLC)
 Removed all references and code to use of rows, zoom and TapDetectingView.
 This is a single row, horizontal tiled scroll view.
 Renamed to HorizontalTiledScrollView
 */

/*
     File: TiledScrollView.m
 Abstract: UIScrollView subclass to manage tiled content.
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import <QuartzCore/QuartzCore.h>
#import "HorizontalTiledScrollView.h"

#define DEFAULT_TILE_SIZE 100
#define ANNOTATE_TILES YES

@interface HorizontalTiledScrollView ()
- (void)annotateTile:(UIView *)tile;
@end

@implementation HorizontalTiledScrollView
@synthesize tileSize;
@synthesize tileContainerView;
@synthesize dataSource;
@synthesize userTouchDetected;
@synthesize name;
@synthesize fix;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        // we will recycle tiles by removing them from the view and storing them here
        reusableTiles = [[NSMutableSet alloc] init];
        
        // we need a tile container view to hold all the tiles. This is the view that is returned
        // in the -viewForZoomingInScrollView: delegate method, and it also detects taps.
        tileContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.tileContainerView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:self.tileContainerView];
        [self setTileSize:CGSizeMake(DEFAULT_TILE_SIZE, DEFAULT_TILE_SIZE)];

        // no rows or columns are visible at first; note this by making the firsts very high and the lasts very low
        firstVisibleColumn = NSIntegerMax;
        lastVisibleColumn  = NSIntegerMin;
        
        self.userTouchDetected = NO;
                
        // HorizontalTiledScrollView doesn't need to be its own UIScrollViewDelegate, hence it's commented out
        // the TiledScrollView is its own UIScrollViewDelegate, so we can handle our own zooming.
        // We need to return our tileContainerView as the view for zooming, and we also need to receive
        // the scrollViewDidEndZooming: delegate callback so we can update our resolution.
//        [super setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [name release];
    [reusableTiles release];
    [tileContainerView release];
    [super dealloc];
}

- (UIView *)dequeueReusableTile {
    NSLog(@"%@ - %s", self.name, __PRETTY_FUNCTION__);
    UIView *tile = [reusableTiles anyObject];
    if (tile) {
        // the only object retaining the tile is our reusableTiles set, so we have to retain/autorelease it
        // before returning it so that it's not immediately deallocated when we remove it from the set
        [[tile retain] autorelease];
        [reusableTiles removeObject:tile];
    }
    return tile;
}

- (void)reloadData {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    // recycle all tiles so that every tile will be replaced in the next layoutSubviews
    for (UIView *view in [self.tileContainerView subviews]) {
        [reusableTiles addObject:view];
        [view removeFromSuperview];
    }
    
    // no rows or columns are now visible; note this by making the firsts very high and the lasts very low
    firstVisibleColumn = NSIntegerMax;
    lastVisibleColumn  = NSIntegerMin;
    
    [self setNeedsLayout];
}

- (void)reloadDataWithNewContentSize:(CGSize)size {        
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    // now that we've reset our zoom scale and resolution, we can safely set our contentSize. 
    [self setContentSize:size];
    
    // we also need to change the frame of the tileContainerView so its size matches the contentSize
    [self.tileContainerView setFrame:CGRectMake(0, 0, size.width, size.height)];
    
    [self reloadData];
}

/***********************************************************************************/
/* Most of the work of tiling is done in layoutSubviews, which we override here.   */
/* We recycle the tiles that are no longer in the visible bounds of the scrollView */
/* and we add any tiles that should now be present but are missing.                */
/***********************************************************************************/
- (void)layoutSubviews {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [super layoutSubviews];
    
//    CGRect visibleBounds = CGRectMake(self.bounds.origin.x - 0.5*self.tileSize.width, self.bounds.origin.y, self.bounds.size.width + 0.5*self.tileSize.width, self.bounds.size.height) ;
    
    CGRect visibleBounds = self.bounds;
    
    // calculate which rows and columns are visible by doing a bunch of math.
    float scaledTileWidth  = self.tileSize.width;
    int maxCol = floorf(self.tileContainerView.frame.size.width  / scaledTileWidth);  // and the maximum possible column
    int firstNeededCol = MAX(0, floorf(visibleBounds.origin.x / scaledTileWidth));
    
    // ------------ FIX ---------------
    // This fix demonstrates the error in the formula that resulted in a extra tile being generated offscreen that gets dropped sometimes when the animation delays the scrollview movement just long enough so the scrollview calls the layoutSubviews which removes the extra tile because its not currently displayed on screen.
    float adjustment = 0;
    if (self.fix == YES) {
        adjustment = 0.1;
    } else {
        adjustment = 0.0;
    }
    
    // ------------ PROBLEM ---------------
    int lastNeededCol  = MIN(maxCol, floorf((CGRectGetMaxX(visibleBounds)-adjustment) / scaledTileWidth));
    // ------------ END FIX & PROBLEM ---------------

    // first recycle all tiles that are no longer visible
    for (UIView *tile in [self.tileContainerView subviews]) {
        
        // We want to see if the tiles intersect our (i.e. the scrollView's) bounds, so we need to convert their
        // frames to our own coordinate system
        CGRect scaledTileFrame = [self.tileContainerView convertRect:tile.frame toView:self];

        // If the tile doesn't intersect, it's not visible, so we can recycle it
        if (! CGRectIntersectsRect(scaledTileFrame, visibleBounds)) {
            [reusableTiles addObject:tile];
            [tile removeFromSuperview];
            NSLog(@"%@ - Tile removed", self.name);
            NSLog(@"visible bounds - %@", NSStringFromCGRect(visibleBounds));
            NSLog(@"tile frame - %@", NSStringFromCGRect(tile.frame));
            NSLog(@"scaled tile frame - %@", NSStringFromCGRect(scaledTileFrame));
        }
    }
    
        
    NSLog(@"%@ scaledTileWidth: %f maxCol: %d firstNeededCol: %d lastNeededCol: %d maxBounds: %.1f", self.name, scaledTileWidth,maxCol,firstNeededCol,lastNeededCol,CGRectGetMaxX(visibleBounds));
    // iterate through needed rows and columns, adding any tiles that are missing
    for (int col = firstNeededCol; col <= lastNeededCol; col++) {

        BOOL tileIsMissing = (firstVisibleColumn > col || lastVisibleColumn  < col);
//        NSLog(@"Column: %d, TileMissing: %d",col,tileIsMissing?1:0);
        if (tileIsMissing) {
//            NSLog(@"So sad the tile is missing in col: %d", col);
            UIView *tile = [self.dataSource tiledScrollView:self column:col];
                            
            // set the tile's frame so we insert it at the correct position     
            CGRect frame = CGRectMake(self.tileSize.width * col, 0, self.tileSize.width, self.tileSize.height);
            [tile setFrame:frame];
            [self.tileContainerView addSubview:tile];
            
            // annotateTile draws green lines and tile numbers on the tiles for illustration purposes. 

            if (ANNOTATE_TILES) {
                [self annotateTile:tile];
//                NSLog(@"Annotate what?");
            }
        }
    }
    
    // update our record of which rows/cols are visible
    firstVisibleColumn = firstNeededCol;
    lastVisibleColumn  = lastNeededCol;            
//    NSLog(@"================And so it ends");
}


        
#pragma mark UIScrollViewDelegate


#pragma mark UIScrollView overrides

// HorizontalTiledScrollView doesn't need to be its own UIScrollViewDelegate, hence it's commented out
// We override the setDelegate: method because we can't manage resolution changes unless we are our own delegate.
//- (void)setDelegate:(id)delegate {
//    NSLog(@"You can't set the delegate of a TiledZoomableScrollView. It is its own delegate.");
//}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    self.userTouchDetected = YES;
	[super touchesBegan: touches withEvent: event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {	
//    NSLog(@"Touch Moved");
    self.userTouchDetected = YES;
	[super touchesMoved: touches withEvent: event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {	
    self.userTouchDetected = NO;
	[super touchesEnded: touches withEvent: event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    NSLog(@"hit test");
    self.userTouchDetected = YES;
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if (hitView == self)
        return [[self subviews] lastObject];
    else
        return hitView;
}

#pragma mark
#define LABEL_TAG 3

- (void)annotateTile:(UIView *)tile {
    static int totalTiles = 0;
    
    UILabel *label = (UILabel *)[tile viewWithTag:LABEL_TAG];
    if (!label) {  
        totalTiles++;  // if we haven't already added a label to this tile, it's a new tile
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 80, 50)];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTag:LABEL_TAG];
        [label setTextColor:[UIColor orangeColor]];
        [label setShadowColor:[UIColor colorWithRed:60.0/255 green:60.0/255 blue:60.0/255 alpha:0.7]];
        [label setShadowOffset:CGSizeMake(1.0, 1.0)];
        [label setFont:[UIFont systemFontOfSize:14]];
        [label setText:[NSString stringWithFormat:@"%d", totalTiles]];
        [tile addSubview:label];
        [label release];
        [[tile layer] setBorderWidth:1.0];
        [[tile layer] setBorderColor:[[UIColor orangeColor] CGColor]];
    }
    
    [tile bringSubviewToFront:label];
}


@end
