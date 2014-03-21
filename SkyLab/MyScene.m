//
//  MyScene.m
//  TMXMapSample
//
//  Created by Jeremy on 6/11/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import "MyScene.h"
#import "JSTileMap.h"
#import "NSString+PointArray.h"

@interface MyScene ()
@property (nonatomic,weak) SKLabelNode* mapNameLabel;


@end

@implementation MyScene {
    SKSpriteNode *_spaceship;
    NSUInteger _pathPoint;
    
    CGPoint _pathOffset;
}

-(id)initWithSize:(CGSize)size
{
	if (self = [super initWithSize:size])
	{
		// put anchor point in center of scene
		self.anchorPoint = CGPointMake(0.5,0.5);
        
		// create a world Node to allow for easy panning & zooming
		SKNode* worldNode = [[SKNode alloc] init];
		[self addChild:worldNode];
		self.worldNode = worldNode;
        
        self.worldNode.xScale = 1;
        self.worldNode.yScale = 1;
        
		// load initial map
		[self swapToNextMap];
        
        [self createRotor];
	}
	return self;
}

- (void)createRotor
{
    _spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"dot.png"];
    _spaceship.position = CGPointMake(134,256);
    
   // _spaceship.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:1];
    [self.tiledMap addChild:_spaceship];
}

- (void)rotorAt:(CGPoint)point
{
    _spaceship.position = CGPointMake(point.x + _pathOffset.x,  _pathOffset.y - point.y);
    
    self.worldNode.position = CGPointMake(-_spaceship.position.x + 160, -_spaceship.position.y +160);
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    NSArray *array = self.tiledMap.objectGroups;
    
    TMXObjectGroup *group0 = array[0];
    
    NSMutableDictionary *dict = [[group0 objects] lastObject];
    
    NSLog(@"%@", dict);
    
    NSString *polylines = dict[@"polylinePoints"];
    
    
    _pathOffset = CGPointMake(((NSString *)dict[@"x"]).integerValue, ((NSString *)dict[@"y"]).integerValue );
    
    NSArray *pointArray = [polylines pointArray];
    
    NSArray *interpolatedPointArray = [self interpolatePointArray:pointArray withCount:10];
    
    
    NSValue *pointValue = interpolatedPointArray[_pathPoint];
    
    [self rotorAt: pointValue.CGPointValue];
    
    
    _pathPoint++;
    
}

- (double)lerpFrom:(float)from to:(float)to count:(double)count
{
    return from + (to - from) * count;
}

- (NSArray *)interpolatePointArray:(NSArray *)pointArray withCount:(NSUInteger)count
{
    NSMutableArray *interpolatedPointArray = [[NSMutableArray alloc] init];
    
    for (NSUInteger pointIterator = 0 ; pointIterator < pointArray.count-1 ; pointIterator++) {
        
        
        CGPoint point = ((NSValue *)pointArray[pointIterator]).CGPointValue;
        CGPoint nextPoint = ((NSValue *)pointArray[pointIterator+1]).CGPointValue;
        
        
        
        for (double interpolationIterator = 0 ; interpolationIterator < 1 ; interpolationIterator += 0.01) {
            
            CGPoint newPoint = CGPointMake([self lerpFrom:point.x to:nextPoint.x count:interpolationIterator], [self lerpFrom:point.y to:nextPoint.y count:interpolationIterator]);
            
            [interpolatedPointArray addObject:[NSValue valueWithCGPoint:newPoint]];
            
        }
        
    }
    
    return interpolatedPointArray;
}





- (void) loadTileMap:(NSString*)tileMap
{
#ifdef DEBUG
	NSLog(@"loading map named %@", tileMap);
#endif
	
	self.tiledMap = [JSTileMap mapNamed:tileMap];
	if (self.tiledMap)
	{
		// center map on scene's anchor point
		CGRect mapBounds = [self.tiledMap calculateAccumulatedFrame];
		self.tiledMap.position = CGPointMake(-mapBounds.size.width/2.0, -mapBounds.size.height/2.0);
		[self.worldNode addChild:self.tiledMap];
		
		// display name of map for testing
		if(!self.mapNameLabel)
		{
			SKLabelNode* mapLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
			mapLabel.xScale = .5;
			mapLabel.yScale = .5;
			mapLabel.text = tileMap;
			mapLabel.zPosition = -100;
			[self addChild:mapLabel];
			self.mapNameLabel = mapLabel;
		}
		else
			self.mapNameLabel.text = tileMap;
		self.mapNameLabel.position = CGPointMake(0, -self.size.height/2.0 + 30);
		
		// test spade for zOrdering.  Some test maps will make this more useful (as a test) than others.
        //	SKSpriteNode* spade = [SKSpriteNode spriteNodeWithImageNamed:@"black-spade-md.png"];
        //	spade.position = CGPointMake(spade.frame.size.width/2.5, spade.frame.size.height/2.5);
        //	spade.zPosition = self.tiledMap.minZPositioning / 2.0;
#ifdef DEBUG
        //		NSLog(@"SPADE has zPosition %f", spade.zPosition);
#endif
        //		[self.tiledMap addChild:spade];
	}
	else
	{
		NSLog(@"Uh Oh....");
	}
}

- (void) swapToNextMap
{
    [self loadTileMap:@"Simple.tmx"];
}

// update map label to always be near bottom of scene view
-(void)didChangeSize:(CGSize)oldSize
{
	self.mapNameLabel.position = CGPointMake(0, -self.size.height/2.0 + 30);
}

@end
