//
//  MainViewController.m
//  TiledScrollDebug
//
//  Created by Hiren on 3/3/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

#define PHOTOLIMIT 50
#define PHOTONUMTILE_WIDTH 80
#define PHOTONUMTILE_HEIGHT 80


@implementation MainViewController

@synthesize photoNumView, photoNumView2, fixSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [fixSwitch release];
    [photoNumView release];
    [photoNumView2 release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.photoNumView = [self createHScrollViewWithFrameSize:CGRectMake(40, 170, PHOTONUMTILE_WIDTH*3, PHOTONUMTILE_HEIGHT) tileSize:CGSizeMake(PHOTONUMTILE_WIDTH, PHOTONUMTILE_HEIGHT) contentSize:CGSizeMake(PHOTONUMTILE_WIDTH*(PHOTOLIMIT + 1), PHOTONUMTILE_HEIGHT) contentOffset:CGPointZero];
    self.photoNumView.userInteractionEnabled = YES;
    [self.view addSubview:self.photoNumView];
    self.photoNumView.name = @"PhotoNumView 1";
    self.photoNumView.fix = self.fixSwitch.on;
    
    self.photoNumView2 = [self createHScrollViewWithFrameSize:CGRectMake(40, 280, PHOTONUMTILE_WIDTH*3, PHOTONUMTILE_HEIGHT) tileSize:CGSizeMake(PHOTONUMTILE_WIDTH, PHOTONUMTILE_HEIGHT) contentSize:CGSizeMake(PHOTONUMTILE_WIDTH*(PHOTOLIMIT + 1), PHOTONUMTILE_HEIGHT) contentOffset:CGPointZero];
    self.photoNumView2.userInteractionEnabled = NO;
    [self.view addSubview:self.photoNumView2];
    self.photoNumView2.name = @"PhotoNumView 2";
    self.photoNumView2.fix = self.fixSwitch.on;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Scrollview methods

-(HorizontalTiledScrollView *)createHScrollViewWithFrameSize:(CGRect)frameRect tileSize:(CGSize)tileSize contentSize:(CGSize)contentSize contentOffset:(CGPoint)contentOffset {
    HorizontalTiledScrollView *scrollView = [[HorizontalTiledScrollView alloc] initWithFrame:frameRect];
    [scrollView setTileSize:tileSize];
    [scrollView setDataSource:self];
    [scrollView setDelegate:self];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setBounces:YES];
    [scrollView setPagingEnabled:YES];
    scrollView.userInteractionEnabled = YES;
    scrollView.hidden = NO;
    [scrollView reloadDataWithNewContentSize:contentSize];
    [scrollView setContentOffset:contentOffset animated:YES];            
    return scrollView;
}

-(UIImageView *)createImageViewWithFrame:(CGRect)rect withImage:(UIImage *)image withTag:(int)tag {
    UIImageView *imgView = [[[UIImageView alloc] init] autorelease];
    imgView.frame = rect;
    [imgView setContentMode:UIViewContentModeScaleToFill]; 
    imgView.tag = tag;
    imgView.image = image;
    return imgView;
}


#pragma mark - TiledScrollViewDataSource method

- (UIView *)tiledScrollView:(HorizontalTiledScrollView *)tiledScrollView column:(int)column {
    //    NSLog(@"+++ %s +++", __PRETTY_FUNCTION__);
    
    // re-use a tile rather than creating a new one, if possible
    UIView *tile = [tiledScrollView dequeueReusableTile];
    
    if (!tile) {
        // the scroll view will handle setting the tile's frame, so we don't have to worry about it
        tile = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, PHOTONUMTILE_WIDTH, PHOTONUMTILE_HEIGHT)] autorelease];
        [tile addSubview:[self createImageViewWithFrame:CGRectMake(20, 20, 32, 30) withImage:nil withTag:2]];
        
        // Some of the tiles won't be completely filled, because they're on the right or bottom edge.
        // By default, the image would be stretched to fill the frame of the image view, but we don't
        // want this. Setting the content mode to "top left" ensures that the images around the edge are
        // positioned properly in their tiles. 
        [tile setContentMode:UIViewContentModeTopLeft]; 
    }
    
    if (column % 2 == 0) {
        tile.backgroundColor = [UIColor colorWithRed:100.0/255 green:100.0/255 blue:100.0/255 alpha:1.0];
    } else {
        tile.backgroundColor = [UIColor colorWithRed:80.0/255 green:80.0/255 blue:80.0/255 alpha:1.0];
    }
    UIImageView *imageView = (UIImageView *)[tile viewWithTag:2];
    
    // Add blank UIImageView as filler or UIImageView with PNG or UILabel if no PNG sized correctly and offsetted from tile's origin
    
    int num = column % 10;
    imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"TimeMinute_%02d", num]];
    
    return tile;
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.photoNumView) {
        self.photoNumView.fix = self.fixSwitch.on;
        self.photoNumView2.fix = self.fixSwitch.on;
        NSLog(@"%@ - X: %.1f", self.photoNumView.name, self.photoNumView.contentOffset.x/PHOTONUMTILE_WIDTH);
        [self.photoNumView2 setContentOffset:CGPointMake(self.photoNumView.contentOffset.x, self.photoNumView2.contentOffset.y) animated:YES];
    }
}

@end
