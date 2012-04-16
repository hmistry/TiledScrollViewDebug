//
//  MainViewController.h
//  TiledScrollDebug
//
//  Created by Hiren on 3/3/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HorizontalTiledScrollView.h"


@interface MainViewController : UIViewController <UIScrollViewDelegate, HorizontalTiledScrollViewDataSource> {
    
}

@property (nonatomic, retain) HorizontalTiledScrollView *photoNumView;
@property (nonatomic, retain) HorizontalTiledScrollView *photoNumView2;
@property (nonatomic, retain) IBOutlet UISwitch *fixSwitch;

-(HorizontalTiledScrollView *)createHScrollViewWithFrameSize:(CGRect)frameRect tileSize:(CGSize)tileSize contentSize:(CGSize)contentSize contentOffset:(CGPoint)contentOffset;
-(UIImageView *)createImageViewWithFrame:(CGRect)rect withImage:(UIImage *)image withTag:(int)tag;

@end
