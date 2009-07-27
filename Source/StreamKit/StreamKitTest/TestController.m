//
//  TestController.m
//  StreamKit
//
//  Created by Q on 30.06.09.
//
//

#import "TestController.h"
#import "PlayerTest.h"


@implementation TestController

- (void)awakeFromNib
{
	PlayerTest *pt = [[PlayerTest alloc] init];
	[pt test];
}

@end
