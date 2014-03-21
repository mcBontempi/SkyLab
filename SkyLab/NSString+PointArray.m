//
//  NSString+PointArray.m
//  SkyLab
//
//  Created by Daren David Taylor on 21/03/2014.
//  Copyright (c) 2014 Sparx. All rights reserved.
//

#import "NSString+PointArray.h"

@implementation NSString (PointArray)

- (NSArray *)pointArray
{
    NSArray *polylineArray = [self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    
    __block NSMutableArray *pointArray = [[NSMutableArray alloc] init];
    
    [polylineArray enumerateObjectsUsingBlock:^(NSString *pointString, NSUInteger idx, BOOL *stop) {
        
        
        NSArray *pointPairArray = [pointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        
        NSString *xString = pointPairArray[0];
        xString = [xString stringByReplacingOccurrencesOfString:@"," withString:@""];
        
        NSString *yString = pointPairArray[1];
        
        CGPoint point = CGPointMake(xString.integerValue, yString.integerValue);
        
        [pointArray addObject:[NSValue valueWithCGPoint:point]];
        
    }];
    
    return pointArray;
}

@end
