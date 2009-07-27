//
//  SkinSelectView.h
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

#import <Cocoa/Cocoa.h>


@interface SkinSelectView : NSView {

	NSImage *background;
	
	NSArray *skinBundles;
	NSArray *skinPanels;
	NSUInteger selectedIndex;
	
	IBOutlet NSButton *leftArrow;
	IBOutlet NSButton *rightArrow;
	IBOutlet NSButton *remove;
}

@property (retain) NSArray *skinPanels;
@property (retain) NSArray *skinBundles;

- (void)reload;
- (void)showSkinAtIndex:(NSUInteger)idx animate:(BOOL)anim;

- (IBAction)scrollLeft:(id)sender;
- (IBAction)scrollRight:(id)sender;
- (IBAction)removeSkin:(id)sender;
- (IBAction)selectSkin:(id)sender;

@end


@interface SkinBundle : NSBundle {
	
}

- (NSString *)name;
- (NSString *)author;
- (NSString *)version;

- (NSImage *)previewImage;
- (NSImage *)previewImageFitInRect:(NSRect)aRect;
- (NSURL *)location;

- (NSString *)valueForParameter:(NSString *)aParam;

@end

@interface SkinPanel : NSView
{
	SkinBundle *bundle;
}

- (id)initWithFrame:(NSRect)aFrame skinBundle:(SkinBundle *)aBundle;

@end
