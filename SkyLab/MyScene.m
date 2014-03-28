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


// 100 slow 10 fast
const float rotationSpeeed = 60;

// 50 slow 5 fast
const float interpolationDivider = 20;

// Number of ghosts to display behind the rotor
const NSUInteger spaceshipGhostCount = 100;


@interface MyScene ()
@property (nonatomic,weak) SKLabelNode* mapNameLabel;

@property (nonatomic, strong) NSArray *interpolatedPointArray;


@end

@implementation MyScene {
  SKSpriteNode *_spaceship;
  
  NSMutableArray *_spaceShipGhostArray;
  
  CGFloat _pathPoint;
  
  CGPoint _pathOffset;
  
  BOOL _pressingScreen;
  
  CGFloat _pressingScreenPosition;
  
  
  
  CGFloat _speed;
  
  
  
}

- (NSArray *)interpolatedPointArray
{
  if (!_interpolatedPointArray) {
    NSArray *array = self.tiledMap.objectGroups;
    
    TMXObjectGroup *group0 = array[0];
    
    NSMutableDictionary *dict = [[group0 objects] lastObject];
    
    NSLog(@"%@", dict);
    
    NSString *polylines = dict[@"polylinePoints"];
    
    _pathOffset = CGPointMake(((NSString *)dict[@"x"]).integerValue, ((NSString *)dict[@"y"]).integerValue );
    
    NSArray *pointArray = [polylines pointArray];
    
    _interpolatedPointArray = [self interpolatePointArray:pointArray withCount:interpolationDivider];
    
  }
  
  return _interpolatedPointArray;
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
    
    
		[self swapToNextMap];
    
    _speed = 0.2;
    
	}
	return self;
}

- (void)createRotor
{
  _spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"rectangle.png"];
  _spaceship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_spaceship.size];
  _spaceship.physicsBody.affectedByGravity = NO;
  _spaceship.physicsBody.dynamic = YES;
  _spaceship.physicsBody.collisionBitMask = 1;
  _spaceship.physicsBody.categoryBitMask = 1;
  
  [self.tiledMap addChild:_spaceship];
  
  _spaceShipGhostArray = [[NSMutableArray alloc] init];
  
  for (NSUInteger i = 0 ; i < spaceshipGhostCount ; i++) {
    SKSpriteNode *ghost = [SKSpriteNode spriteNodeWithImageNamed:@"rectangle.png"];
    
    double pc = spaceshipGhostCount;
    pc/=i;
    
    
    ghost.alpha = 0.025;
    [self.tiledMap addChild:ghost];
    
    [_spaceShipGhostArray addObject:ghost];
  }
}

- (void)rotorAt:(CGPoint)point
{
  if(!_spaceship) {
    [self createRotor];
  }
  
  _spaceship.position = CGPointMake(point.x + _pathOffset.x,  _pathOffset.y - point.y);
  
  
  
  for (NSUInteger i = spaceshipGhostCount ; i>1 ; i--) {

    
    
    SKSpriteNode *ghost = _spaceShipGhostArray[i-1];
    SKSpriteNode *previousGhost = _spaceShipGhostArray[i-2];
    
    ghost.position = previousGhost.position;
    ghost.zRotation = previousGhost.zRotation;
  }

 
  SKSpriteNode *firstGhost = _spaceShipGhostArray[0];
  
  firstGhost.position = _spaceship.position;
  firstGhost.zRotation = _spaceship.zRotation;
  
  self.worldNode.position = CGPointMake(-_spaceship.position.x + 400, -_spaceship.position.y +400);
}

-(void)update:(CFTimeInterval)currentTime {
  NSValue *pointValue = self.interpolatedPointArray[(NSUInteger)_pathPoint];
  
  
  
  _speed += 0.0001;
  
  [self rotorAt: pointValue.CGPointValue];
  
  _pathPoint+=_speed;
  
  if(_pathPoint > self.interpolatedPointArray.count-1) {
    _pathPoint = 0;
    //[self swapToNextMap];
  }
  
  if (_pressingScreen) {
    [self pressingAtX:_pressingScreenPosition];
  }
  
}

- (double)lerpFrom:(float)from to:(float)to count:(double)count
{
  return from + (to - from) * count;
}

- (NSArray *)interpolatePointArray:(NSArray *)pointArray withCount:(NSUInteger)count
{
  CGFloat iteratiorStep = 1;
  iteratiorStep = iteratiorStep / count;
  
  
  NSMutableArray *interpolatedPointArray = [[NSMutableArray alloc] init];
  
  for (NSUInteger pointIterator = 0 ; pointIterator < pointArray.count-1 ; pointIterator++) {
    
    
    CGPoint point = ((NSValue *)pointArray[pointIterator]).CGPointValue;
    CGPoint nextPoint = ((NSValue *)pointArray[pointIterator+1]).CGPointValue;
    
    
    
    for (double interpolationIterator = 0 ; interpolationIterator < 1 ; interpolationIterator += iteratiorStep) {
      
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
  [self loadTileMap:@"Level1.tmx"];
}

// update map label to always be near bottom of scene view
-(void)didChangeSize:(CGSize)oldSize
{
	self.mapNameLabel.position = CGPointMake(0, -self.size.height/2.0 + 30);
}







-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  
  for (UITouch *touch in touches) {
    CGPoint location = [touch locationInNode:self];
    _pressingScreen = YES;
    _pressingScreenPosition = location.x;
  }
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  for (UITouch *touch in touches) {
    CGPoint location = [touch locationInNode:self];
    _pressingScreen = YES;
    _pressingScreenPosition = location.x;
  }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  
  _pressingScreen = NO;
  
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  
  _pressingScreen = NO;
}

- (void)pressingAtX:(CGFloat)x
{
  
  
  SKAction *rotation;
  
  if (x>0) {
    rotation = [SKAction rotateByAngle: -M_PI/rotationSpeeed duration:0];
  }
  else {
    rotation = [SKAction rotateByAngle: M_PI/rotationSpeeed duration:0];
    
  }
  
  [_spaceship runAction: rotation];

}


@end
