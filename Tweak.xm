
@interface PUCollectionView : UICollectionView 
@property(assign,nonatomic) id delegate;
@property(assign,nonatomic) NSArray* visibleCells;
@property(assign,nonatomic) NSArray* indexPathsForVisibleItems;
@property(assign,nonatomic) id reorderDelegate;
@property(assign,nonatomic) id selectionDelegate;
-(id) idexPathForItemAtPoint:(id) arg1;
-(id) cellForItemAtIndexPath:(id) arg1;
-(id) indexPathForCell:(id) arg1;
-(void) _updateVisibleCellsNow:(BOOL) arg1;

@end

@interface PUPhotosGridViewController 
@property(assign,nonatomic)id assetCollection;
@property(assign,nonatomic)id assetCollectionAssets;
@property(assign, nonatomic)id dataSource;
@property(assign, nonatomic) id collectionView;
@property(assign, nonatomic) UINavigationItem *navigationItem;
-(void) handleToggleSelectionOfItemAtIndexPath:(NSIndexPath*) arg1;
-(void) setSelected:(BOOL) arg1 itemsAtIndexes:(id) arg2 inSection:(long long) arg3 animated:(BOOL) arg4;
-(BOOL) isEditing;
-(NSInteger) collectionView:(id) arg1 numberOfItemsInSection:(NSInteger) arg2;

//custom elememnts
@property(assign,nonatomic) BOOL ctrlEnabled;
@property(assign,nonatomic) NSIndexPath* ctrlFirstIndexPath;
@property(assign,nonatomic) UIBarButtonItem* ctrlButton;
@property(assign,nonatomic) UITapGestureRecognizer* ctrlTapRecognizer;
@property(assign,nonatomic) UIImageView* ctrlSelectOverlayView;

-(void)updateCtrlButton;

@end

@interface PUPhotosGridCell : UIView
@property(assign, nonatomic) id photoContentView;
-(void) prepareForReuse;

//custom elements
@property(retain, nonatomic) UIImageView *ctrlSelectOverlayView;
-(void) removeSelectOverlayViewImage;

@end


%group Tweak

%hook PUPhotosGridViewController
%property(assign,nonatomic) BOOL ctrlEnabled;
%property(assign,nonatomic) NSIndexPath* ctrlFirstIndexPath;
%property(assign, nonatomic) UIBarButtonItem* ctrlButton;
%property(assign, nonatomic) UITapGestureRecognizer* ctrlTapRecognizer;
%property(assign,nonatomic) UIImageView* ctrlSelectOverlayView;

%new
-(void) updateCtrlButton{
	if ([self ctrlEnabled]){
		[[self ctrlButton] setTintColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5]];
		[self ctrlTapRecognizer].cancelsTouchesInView = YES;
	} else {
		[[self ctrlButton] setTintColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
		[self ctrlTapRecognizer].cancelsTouchesInView = NO;
	}
}


%new 
-(void) ctrlButtonPressed{

	if (![self ctrlEnabled]){
		[self setCtrlEnabled:YES];
	} else {
		[self setCtrlEnabled:NO];
	}
		
	
	[self updateCtrlButton];
	[self setCtrlFirstIndexPath:nil];
}


-(void) updateNavigationBarAnimated:(BOOL) arg1{
	%orig;

	UINavigationItem* navItem = [self navigationItem];

	if ([self isEditing]){
		UIBarButtonItem* ctrlButton = [self ctrlButton];
		[navItem setLeftBarButtonItem:ctrlButton];
	} else {
		[navItem setLeftBarButtonItem:nil];
		[self setCtrlEnabled:NO];
	}

	[self updateCtrlButton];
}


-(void) viewDidLoad{
	%orig;

	[self setCtrlEnabled:NO];
	[self setCtrlFirstIndexPath:nil];

	id collectionView = [self collectionView];

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:collectionView action:@selector(ctrlScreenTapRecognized:)];
	tap.numberOfTapsRequired = 1;
	tap.cancelsTouchesInView = NO;
	[collectionView addGestureRecognizer:tap];
	[self setCtrlTapRecognizer:tap];
	[tap release];

	UIBarButtonItem* ctrlButton = [[UIBarButtonItem alloc] initWithTitle:@"Ctrl" style:UIBarButtonItemStylePlain target:self action:@selector(ctrlButtonPressed)];
	[self setCtrlButton:ctrlButton];
	
	

}


%end


%hook PUCollectionView

%new 
-(void)ctrlScreenTapRecognized:(id) sender {
	
	if ([self selectionDelegate] && ![self reorderDelegate]) {

		id gvController = [self delegate];

		if ([gvController ctrlEnabled]){

			CGPoint tapPoint = [sender locationInView:self];
			NSIndexPath *nextIndexPath = [self indexPathForItemAtPoint:tapPoint];
	 
			if (![gvController ctrlFirstIndexPath]){

				[gvController setCtrlFirstIndexPath:nextIndexPath];
				
				
				PUPhotosGridCell* firstSelectedCell = [self cellForItemAtIndexPath:nextIndexPath];
				
				firstSelectedCell.ctrlSelectOverlayView = [[UIImageView alloc] init];
				firstSelectedCell.ctrlSelectOverlayView.frame = CGRectMake(0,0,31,31);
				firstSelectedCell.ctrlSelectOverlayView.image = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/PhotoCtrl/check.png"];
				
				[firstSelectedCell addSubview:firstSelectedCell.ctrlSelectOverlayView];
				

			} else {
				
				//PUPhotosGridCell* firstSelectedCell = [self cellForItemAtIndexPath:[gvController ctrlFirstIndexPath]];
				
				//[firstSelectedCell.ctrlSelectOverlayView removeFromSuperview];
				//firstSelectedCell.ctrlSelectOverlayView = nil;
				
				NSRange indexRange;
				NSInteger firstRow = [gvController ctrlFirstIndexPath].row;
				NSInteger firstSection = [gvController ctrlFirstIndexPath].section;
				NSInteger nextRow = nextIndexPath.row;
				NSInteger nextSection = nextIndexPath.section;

				NSInteger lowRow = 0;
				NSInteger highRow = 0;
				NSInteger lowSection = 0;
				NSInteger highSection = 0;
				NSInteger sectionItemCount = 0;
				
				if (firstRow == nextRow && nextSection == firstSection){
					
					[gvController setCtrlFirstIndexPath:nil];
					
				} else {

					if (nextSection == firstSection){

						if (firstRow < nextRow){
							indexRange = NSMakeRange(firstRow, nextRow - firstRow + 1);
						} else {
							indexRange = NSMakeRange(nextRow, firstRow - nextRow + 1);
						}

						[gvController setSelected:YES itemsAtIndexes:[%c(NSIndexSet) indexSetWithIndexesInRange:indexRange] inSection:(long long)firstSection animated:NO];

					} else {

						if (nextSection > firstSection){

							lowRow = firstRow;
							lowSection = firstSection;
							highRow = nextRow;
							highSection = nextSection;

						} else if (nextSection < firstSection){

							lowRow = nextRow;
							lowSection = nextSection;
							highRow = firstRow;
							highSection = firstSection;

						} 

						for (NSInteger i = lowSection; i <= highSection; i++){
							sectionItemCount = [gvController collectionView:self numberOfItemsInSection:i];

							if (i == lowSection){
								indexRange = NSMakeRange(lowRow, sectionItemCount - lowRow);
							} else if (i == highSection){
								indexRange = NSMakeRange(0, highRow+1);
							} else {
								indexRange = NSMakeRange(0, sectionItemCount);
							}

							[gvController setSelected:YES itemsAtIndexes:[%c(NSIndexSet) indexSetWithIndexesInRange:indexRange] inSection:(long long)i animated:NO];
						}
					}

					[gvController handleToggleSelectionOfItemAtIndexPath:nextIndexPath];
					
					[gvController setCtrlEnabled:NO];
					
				}
			}
		}
		
		[gvController updateCtrlButton];
	}
}


-(id) dequeueReusableCellWithReuseIdentifier: (id) arg1 forIndexPath:(id) arg2{
	id orig = %orig;
	
	if ([self selectionDelegate] && ![self reorderDelegate] && [orig isKindOfClass:[%c(PUPhotosGridCell) class]]) {
	
		id gvController = [self delegate];
		
		if ([orig ctrlSelectOverlayView]){
			
			[orig ctrlSelectOverlayView].image = nil;
			
			if ([gvController ctrlEnabled] && [gvController ctrlFirstIndexPath]){
				
				NSIndexPath* firstIndexPath = [gvController ctrlFirstIndexPath];
				NSIndexPath* thisIndexPath = arg2;

				HBLogDebug(@"firstIndexPath: %ld-%ld thisIndexPath: %ld-%ld", (long)firstIndexPath.section, (long)firstIndexPath.row, (long)thisIndexPath.section, (long)thisIndexPath.row);
				if ( firstIndexPath.section == thisIndexPath.section && firstIndexPath.row == thisIndexPath.row){
					
					[orig ctrlSelectOverlayView].image = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/PhotoCtrl/check.png"];
					
				}
			}	 
		}
	}
	
	return orig;
}

%end


%hook PUPhotosGridCell
%property(retain,nonatomic) UIImageView* ctrlSelectOverlayView;
%end

%end


%ctor{
	@autoreleasepool{
		%init(Tweak);
	}
}



