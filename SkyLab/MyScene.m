#import "MyScene.h"
#import "JSTileMap.h"
#import "NSString+PointArray.h"ki

//
const NSUInteger KLapsRequired = 3;

// 100 slow 10 fast
const float KRotationSpeeed = 80;

// 50 slow 5 fast
const float KInterpolationDivider = 20;

// Number of ghosts to display behind the rotor
const NSUInteger KSpaceshipGhostCount = 50;
// 0.2 slow 1 fast
const CGFloat initialSpeed = 1.2;

//0.001 very light 1 solid;
const CGFloat KGhostAlpha = 0.005;

// 0.0001 = slow increase
const CGFloat KSpeedIncrease = 0.5;

// the number of 'lives'
const NSUInteger KInitialPower = 20;

// 1 = normal 3 = zoomed in 0.5 is zoomed out
const CGFloat KInitialZoomLevel = 2.0;

@interface MyScene () <SKPhysicsContactDelegate>
@property (nonatomic,weak) SKLabelNode* mapNameLabel;
@property (nonatomic, strong) NSArray *interpolatedPointArray;
@end

@implementation MyScene {
  SKSpriteNode *_space;
  SKSpriteNode *_spaceship;
  NSMutableArray *_spaceShipGhostArray;
  CGFloat _pathPoint;
  CGPoint _pathOffset;
  BOOL _pressingScreen;
  CGFloat _pressingScreenPosition;
  CGFloat _speed;
  NSUInteger _lapsCompleted;
  NSUInteger _power;
  
  CGFloat _zoom;
  
  SKAction *_crashSound;
  SKAction *_dieSound;
  SKAction *_whooshSound;
  
}

- (NSArray *)interpolatedPointArray
{
  if (!_interpolatedPointArray) {
    NSArray *array = self.tiledMap.objectGroups;
    TMXObjectGroup *group0 = array[0];
    NSMutableDictionary *dict = [[group0 objects] lastObject];
    NSString *polylines = dict[@"polylinePoints"];
    _pathOffset = CGPointMake(((NSString *)dict[@"x"]).integerValue, ((NSString *)dict[@"y"]).integerValue );
    NSArray *pointArray = [polylines pointArray];
    _interpolatedPointArray = [self interpolatePointArray:pointArray withCount:KInterpolationDivider];
  }
  return _interpolatedPointArray;
}

- (void)setMapPath:(NSString *)mapPath
{
  _mapPath = mapPath;
  
  [self loadTileMap:mapPath];
}

-(id)initWithSize:(CGSize)size
{
  
  CGSize zoomedSize = CGSizeMake(size.width/KInitialZoomLevel, size.height / KInitialZoomLevel);
  
	if (self = [super initWithSize:zoomedSize])
	{
		// put anchor point in center of scene
		self.anchorPoint = CGPointMake(0.5,0.5);
  
    _space = [[SKSpriteNode alloc] initWithImageNamed:@"space"];
    _space.zPosition = -1000;
    _space.color = [UIColor blueColor];
    [self addChild:_space];
    
    // create a world Node to allow for easy panning & zooming
    SKNode* worldNode = [[SKNode alloc] init];
		[self addChild:worldNode];
		self.worldNode = worldNode;
    
    _zoom = KInitialZoomLevel;
  //  self.worldNode.xScale = _zoom;
  //  self.worldNode.yScale = _zoom;
    
    self.physicsWorld.contactDelegate = self;
    
    _speed = initialSpeed;
    
    _power = KInitialPower;
    
    
    _crashSound = [SKAction playSoundFileNamed:@"crash.wav" waitForCompletion:NO];
  //  _dieSound = [SKAction playSoundFileNamed:@"die.mp3" waitForCompletion:NO];
    _whooshSound = [SKAction playSoundFileNamed:@"whoosh.wav" waitForCompletion:NO];
    
    
}
	return self;
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
  NSLog(@"Contact");
  
  if (contact.bodyB.categoryBitMask == 3) {
   [contact.bodyB.node runAction:[SKAction removeFromParent]];
    
   // [UIView animateWithDuration:1.5 animations:^ {
  //  contact.bodyB.node.alpha = 0.0;
   // }];
    
  }
  else if(_power) {
    _power--;
    
    double alpha = _power;
    alpha /= KInitialPower;
    
    [UIView animateWithDuration:1.5 animations:^ {
      _spaceship.alpha = alpha;
    }];
 
    
    [UIView animateWithDuration:1.5 animations:^ {
      _space.colorBlendFactor = 1.0;
    } completion:^(BOOL completed){ _space.colorBlendFactor = 0.0;  }];
   
    
    
    [_spaceship runAction:_crashSound];
    
    
  }
  
  NSLog(@"power = %d", _power);
  
  if (_power == 0) {
    _spaceship.physicsBody = nil;
    [self performSelector:@selector(diedTimedOut) withObject:nil afterDelay:1.0];
    [_spaceship runAction:_dieSound];
    
  
  }
}

- (void)diedTimedOut
{
  [self.delegate died];
}

- (void)createRotor
{
  _spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"rectangle.png"];
  _spaceship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_spaceship.size];
  _spaceship.physicsBody.affectedByGravity = NO;
  _spaceship.physicsBody.dynamic = NO;
  _spaceship.physicsBody.categoryBitMask = 1;
  
  _spaceship.physicsBody.collisionBitMask = 2;
  _spaceship.physicsBody.contactTestBitMask = 2;
  
  
  [self.tiledMap addChild:_spaceship];
  
  _spaceShipGhostArray = [[NSMutableArray alloc] init];
  
  for (NSUInteger i = 0 ; i < KSpaceshipGhostCount ; i++) {
    SKSpriteNode *ghost = [SKSpriteNode spriteNodeWithImageNamed:@"rectangle.png"];
    
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

  _space.position= CGPointMake(-((point.x + _pathOffset.x)/2), -(( _pathOffset.y - point.y)/2));
  
  for (NSUInteger i = KSpaceshipGhostCount ; i>1 ; i--) {
  SKSpriteNode *ghost = _spaceShipGhostArray[i-1];
    SKSpriteNode *previousGhost = _spaceShipGhostArray[i-2];
    ghost.position = previousGhost.position;
    ghost.zRotation = previousGhost.zRotation;
    ghost.alpha = previousGhost.alpha;
    
  }

  SKSpriteNode *firstGhost = _spaceShipGhostArray[0];

  firstGhost.position = _spaceship.position;
  firstGhost.zRotation = _spaceship.zRotation;
  firstGhost.alpha = _spaceship.alpha/50;
  
  self.worldNode.position = CGPointMake(-_spaceship.position.x + 400, -_spaceship.position.y +400);
}

-(void)update:(CFTimeInterval)currentTime {
  NSValue *pointValue = self.interpolatedPointArray[(NSUInteger)_pathPoint];
  
  [self rotorAt: pointValue.CGPointValue];
  
  _pathPoint+=_speed;
  
  if(_pathPoint > self.interpolatedPointArray.count-1) {
    _pathPoint = 0;
    _lapsCompleted ++;
    _speed += KSpeedIncrease;
    
    [_spaceship runAction:_whooshSound];
    
    if (_lapsCompleted == KLapsRequired) {
      [self.delegate levelComplete];
    }
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
		//	[self addChild:mapLabel];
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
    rotation = [SKAction rotateByAngle: -M_PI/KRotationSpeeed duration:0];
  }
  else {
    rotation = [SKAction rotateByAngle: M_PI/KRotationSpeeed duration:0];
  }
  [_spaceship runAction: rotation];
}



@end
