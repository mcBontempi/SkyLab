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
- (IBAction)quitTapped:(id)sender {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
 
  _level = 1;
  
  _spriteKitView.alpha = 1.0;
  
  
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  [self loadLevel:_level];
}

- (void)loadLevel:(NSUInteger)level
{
  [UIView animateWithDuration:1.0 animations:^{ _spriteKitView.alpha = 1.0;}];
  
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
  [UIView animateWithDuration:1.0 animations:^{ _spriteKitView.alpha = 0.0;} completion:^(BOOL finished) {
    [self loadLevel:++_level];
  }];
}

- (void)died
{
  [UIView animateWithDuration:1.0 animations:^{ _spriteKitView.alpha = 0.0;} completion:^(BOOL finished) {
    [self loadLevel:_level];
  }];
}

@end
