//
//  ViewController.m
//  SkyLab
//
//  Created by Daren taylor on 15/03/2014.
//  Copyright (c) 2014 Sparx. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"
#import "MySceneDelegate.h"

@interface ViewController () <MySceneDelegate>
@end

@implementation ViewController {
  __weak IBOutlet SKView *_spriteKitView;
  
  NSUInteger _level;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
 
  _level = 1;
  
  _spriteKitView.showsFPS = YES;
  _spriteKitView.showsNodeCount = YES;
  
  [self loadLevel:_level];
}

- (void)loadLevel:(NSUInteger)level
{
  [self showMapPath:[NSString stringWithFormat:@"Level%d.tmx",level]];
}

- (void)showMapPath:(NSString *)mapPath
{
  MyScene * scene = [MyScene sceneWithSize:_spriteKitView.bounds.size];
  scene.scaleMode = SKSceneScaleModeAspectFill;
  scene.delegate = self;
  
  [_spriteKitView presentScene:scene];
  
  scene.mapPath = mapPath;
}

- (IBAction)button1Tapped:(id)sender
{
  [self showMapPath:@"Simple.tmx"];
}

- (IBAction)button2Tapped:(id)sender
{
  [self showMapPath:@"Simple2.tmx"];
}

- (void)levelComplete
{
    [self loadLevel:++_level];
}

- (void)died
{
  [self loadLevel:_level];
}

@end
