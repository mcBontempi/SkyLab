//
//  MyScene.m
//  TMXMapSample
//
//  Created by Jeremy on 6/11/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import "MyScene.h"
#import "JSTileMap.h"

@interface MyScene ()
@property (nonatomic,weak) SKLabelNode* mapNameLabel;


@end

@implementation MyScene {
  SKSpriteNode *_spaceship;
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
    
		// load initial map
		[self swapToNextMap];
    
		// instructions
		SKLabelNode* label = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
		label.text = @"Double-tap to change maps.";
		label.fontSize = 18;
		label.fontColor = [UIColor yellowColor];
		label.alpha = 0;
		[self addChild:label];
		id seq = [SKAction sequence:@[[SKAction waitForDuration:1.0],
                                  [SKAction fadeInWithDuration:1.0],
                                  [SKAction waitForDuration:3.0],
                                  [SKAction fadeOutWithDuration:1.0],
                                  [SKAction runBlock:^{
      [label removeFromParent];
    } queue:dispatch_get_main_queue()]
                                  ]];
		[label runAction:seq];
    
    
    [self createRotor];
	}
	return self;
}

- (void)createRotor
{
  _spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"dot.png"];
  _spaceship.position = CGPointMake(134,256);
  
  _spaceship.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:1];
  [self.tiledMap addChild:_spaceship];
}

- (void)rotorAt:(CGPoint)point
{
  _spaceship.position = point;
}

-(void)update:(CFTimeInterval)currentTime {
  /* Called before each frame is rendered */
  
  NSArray *array = self.tiledMap.objectGroups;
  
  TMXObjectGroup *group0 = array[0];
  
  NSMutableDictionary *dict = [[group0 objects] lastObject];
  
  NSLog(@"%@", dict);
  
  NSString *polylines = dict[@"polylinePoints"];
  
  NSArray *polylineArray = [polylines componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
  
  __block NSMutableArray *pointArray = [[NSMutableArray alloc] init];
  
  [polylineArray enumerateObjectsUsingBlock:^(NSString *pointString, NSUInteger idx, BOOL *stop) {
    
    
    NSArray *pointArray = [pointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    
    NSString *xString = pointArray[0];
    xString = [xString stringByReplacingOccurrencesOfString:@"," withString:@""];
   
    NSString *yString = pointArray[1];
    
    CGPoint point = CGPointMake(xString.integerValue, yString.integerValue);
    
    
    
    
  //  NSString *stringNoCommas = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
  //  NSString *stringNoSpaces = [stringNoCommas stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    
    
    
  }];
  
  //  [self rotorAt:polylines]
  
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
