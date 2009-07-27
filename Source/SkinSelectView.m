//
//  SkinSelectView.m
//  SweetFM
//
//  Created by Q on 02.06.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "SkinSelectView.h"

#import "XLog.h"
#import "NSString+FormatUtilities.h"
#import "HSettings.h"



@implementation SkinSelectView

@synthesize skinBundles, skinPanels;

- (void)awakeFromNib
{
	background = [[NSImage imageNamed:@"pref-skinsBackground"] retain];
	
	//
	// Load skins
	//
	[self reload];
}

- (void)dealloc
{
	self.skinBundles = nil;
	self.skinPanels = nil;
	[background release];
	[super dealloc];
}

- (void)reload
{
	XMark();
	
	//
	// Remove all former panels
	//
	for(NSView *panel in self.skinPanels)
		[panel removeFromSuperview];
	
	//
	// Load contents at skin folder path
	//
	NSString *skinPath = [HSettings skinPath];
	NSArray *skins = [[NSFileManager defaultManager] directoryContentsAtPath:skinPath];
	
	//
	// Generate new SkinBundles
	//
	NSMutableArray *bundles = [NSMutableArray array];
	NSMutableArray *panels = [NSMutableArray array];
	
	for(NSString *bundle in skins)
	{
		if([[bundle pathExtension] isEqualToString:@"sweets"])
		{
			NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", skinPath, bundle];
			
			SkinBundle *skinBundle = [[SkinBundle alloc] initWithPath:bundlePath];		
			[bundles addObject:skinBundle];
			
			SkinPanel *skinPanel = [[SkinPanel alloc] initWithFrame:NSMakeRect(0, 0, 450, 260)
																									 skinBundle:skinBundle];
			
			NSSize viewSize = [self frame].size;
			NSSize panelSize = [skinPanel frame].size;
			NSPoint loc = NSMakePoint((viewSize.width-panelSize.width)/2.0f, 
																(viewSize.height-panelSize.height)/2.0f+40.0f);

			[skinPanel setFrameOrigin:loc];
			[skinPanel setAlphaValue:0];
			
			[panels addObject:skinPanel];
			[self addSubview:skinPanel];
			
			[skinPanel release];
			[skinBundle release];
		}
	}
	
	if([bundles count])
	{
		self.skinBundles = [NSArray arrayWithArray:bundles];
		self.skinPanels = [NSArray arrayWithArray:panels];
		selectedIndex = 0;
		
		[self showSkinAtIndex:selectedIndex animate:NO];
	}
}

- (void)showSkinAtIndex:(NSUInteger)idx animate:(BOOL)anim
{
	if(idx < [skinPanels count])
	{
		//
		// Check if buttons need disabling
		//
		[leftArrow setEnabled:!(idx <= 0)];
		[rightArrow setEnabled:!(idx >= [skinPanels count]-1)];
		
		SkinBundle *selectedBundle = [skinBundles objectAtIndex:idx];
		[remove setEnabled:![[selectedBundle name] isEqualToString:@"Fibre"]];
		
		//
		// Move skin panels
		//
		for(int i=0; i < [skinPanels count]; i++)
		{
			SkinPanel *panel = [skinPanels objectAtIndex:i];
			SkinPanel *proxy = anim ? [panel animator]: panel;
			
			NSRect frame = [panel frame];
			if(i < idx)
			{
				[proxy setFrameOrigin:NSMakePoint(-frame.size.width-20.0f, frame.origin.y)];
				[proxy setAlphaValue:0.0f];
			}
			else if( i > idx)
			{
				[proxy setFrameOrigin:NSMakePoint([self frame].size.width+20.0f, frame.origin.y)];
				[proxy setAlphaValue:0.0f];
			}
			else
			{
				NSSize viewSize = [self frame].size;
				NSSize panelSize = frame.size;
				
				NSPoint loc = NSMakePoint((viewSize.width-panelSize.width)/2.0f, 
																	(viewSize.height-panelSize.height)/2.0f+40.0f);
				
				[proxy setFrameOrigin:loc];
				[proxy setAlphaValue:1.0f];
			}
		}
	}
}

- (IBAction)scrollLeft:(id)sender
{
	XMark();
	if(selectedIndex > 0)
		selectedIndex--;
	
	[self showSkinAtIndex:selectedIndex animate:YES];
}

- (IBAction)scrollRight:(id)sender
{
	XMark();
	if(selectedIndex < [skinPanels count]-1)
		selectedIndex++;
	
	[self showSkinAtIndex:selectedIndex animate:YES];
}

- (IBAction)removeSkin:(id)sender
{
	SkinBundle *bundle = [skinBundles objectAtIndex:selectedIndex];
	XLog(@"Removing %@", [bundle bundlePath]);
	
	int tag;
	[[NSWorkspace sharedWorkspace]
	 performFileOperation:NSWorkspaceRecycleOperation
	 source:[[bundle bundlePath] stringByDeletingLastPathComponent]
	 destination:@""
	 files:[NSArray arrayWithObject:[[bundle bundlePath] lastPathComponent]]
	 tag:&tag];
	
	if(tag)
		XLog(@"Error moving skin to trash.");
	else
	{
		XLog(@"Moved skin to trash.");
		[self reload];
	}
}

- (IBAction)selectSkin:(id)sender
{
	SkinBundle *bundle = [skinBundles objectAtIndex:selectedIndex];
	XLog(@"Selecting %@", [bundle bundlePath]);
	
	//if(![[bundle bundlePath] isEqualToString:[[HSettings selectedSkin] bundlePath]])
	[HSettings setSelectedSkinBundleName:[[bundle bundlePath] lastPathComponent]];
}

- (void)drawRect:(NSRect)aRect
{
	[background drawInRect:[self frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
}

@end

#pragma mark SkinBundle
#pragma mark -

@implementation SkinBundle

- (NSString *)valueForParameter:(NSString *)aParam
{
	NSString *cssPath = [NSString stringWithFormat:@"%@/Skin/skin.css", [self resourcePath]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:cssPath])
	{
		NSString *css = [NSString stringWithContentsOfFile:cssPath];
		NSRange r = [css rangeOfString:aParam];
		
		if(r.location != NSNotFound)
		{
			NSString *paramLine = [[css substringFromIndex:r.location+r.length] stringByTrimmingLeadSpaces];
			r = [paramLine rangeOfString:@"\n"];
			
			if(r.location != NSNotFound)
			{
				return [paramLine substringToIndex:r.location];
			}
			else
				return paramLine;
		}
	}
	
	return nil;
}

- (NSString *)name
{
	return [self valueForParameter:@"@name:"];
}

- (NSString *)author
{
	return [self valueForParameter:@"@author:"];
}

- (NSString *)version
{
	return [self valueForParameter:@"@version:"];
}

- (NSImage *)previewImage
{
	NSString *imagePath = [NSString stringWithFormat:@"%@/Skin/skin.png", [self resourcePath]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
		return [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	
	return nil;
}

- (NSImage *)previewImageFitInRect:(NSRect)aRect
{
	NSImage *orig = [self previewImage];
	
	if(!orig)
		return nil;
	
	double scaleFactor = 1.0f;
	
	NSSize origSize = [orig size];
	
	if(origSize.width > aRect.size.width)
		scaleFactor = aRect.size.width/origSize.width;
	
	if(origSize.height*scaleFactor > aRect.size.height)
		scaleFactor = aRect.size.height/origSize.height;
	
	NSSize newSize = NSMakeSize(origSize.width*scaleFactor, origSize.height*scaleFactor);
	
	NSImage *resized = [[NSImage alloc] initWithSize:newSize];
	[resized lockFocus];
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	NSRect drawIn = NSMakeRect(0, 0, newSize.width, newSize.height);
	
	[orig drawInRect:NSOffsetRect(NSIntegralRect(drawIn), 0.5, 0.5) 
					fromRect:NSZeroRect
				 operation:NSCompositeSourceOver 
					fraction:1.0f];
	
	[resized unlockFocus];
	
	return [resized autorelease];
}

- (NSURL *)location
{
	NSString *htmlPath = [NSString stringWithFormat:@"%@/Skin/skin.htm", [self resourcePath]];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:htmlPath])
		return [NSURL URLWithString:htmlPath];
	
	return nil;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (author: %@, version: %@)", 
					[self name],
					[self author],
					[self version]];
}

@end

#pragma mark SkinPanel
#pragma mark -

@implementation SkinPanel

- (id)initWithFrame:(NSRect)aFrame skinBundle:(SkinBundle *)aBundle
{	
	if(aFrame.size.height < 100 || aFrame.size.width < 100)
		return nil;
	
	if(self = [super initWithFrame:aFrame])
	{
		bundle = [aBundle retain];
		
		NSRect imgRect = NSMakeRect(0, 50, aFrame.size.width, aFrame.size.height-70);
		NSImageView *image = [[NSImageView alloc] initWithFrame:imgRect];
		[image setImageFrameStyle:NSImageFrameNone];
		//[image setImageScaling:NSScaleProportionally];
		[image setEditable:NO];
		[image setImage:[bundle previewImageFitInRect:imgRect]];

		NSTextField *name = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 15, aFrame.size.width, 25)];
		[name setAlignment:NSCenterTextAlignment];
		[name setEditable:NO];
		[name setSelectable:NO];
		[name setDrawsBackground:NO];
		[name setBordered:NO];
		[name setStringValue:[bundle name]];
		[name setFont:[NSFont boldSystemFontOfSize:13]];
		[name setTextColor:[NSColor whiteColor]];
		
		NSTextField *info = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, aFrame.size.width, 15)];
		[info setAlignment:NSCenterTextAlignment];
		[info setEditable:NO];
		[info setSelectable:NO];
		[info setDrawsBackground:NO];
		[info setBordered:NO];
		[info setStringValue:[NSString stringWithFormat:@"%@ - %@", [bundle author], [bundle version]]];
		[info setFont:[NSFont boldSystemFontOfSize:10]];
		[info setTextColor:[NSColor whiteColor]];
		
		[self addSubview:name];
		[self addSubview:info];
		[self addSubview:image];
		
		[image release];
		[name release];
		[info release];
	}
	
	return self;
}

- (void)dealloc
{
	[bundle release];
	[super dealloc];
}

@end

