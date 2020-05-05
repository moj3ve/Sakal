#import <libcolorpicker.h>

// Bundle
static const NSBundle *tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Sakal"];

static UILabel *sakalAlarmLabel;
static NSDate *lastKnownFireDate;
//static bool isEnabled = YES;
static bool wantsCustomFontColor = NO;
static int fontSize = 16;
static int fontWeight = 2;
static int fontAlignment = 1;
static int alarmType = 1;
static CGFloat horizontalOffset = 0;
static CGFloat verticalOffset = -35;
static CGFloat horizontalOffsetLS = 0;
static CGFloat verticalOffsetLS = -20;
static NSString *alarmFormat = @" EEE hh:mm a";
static NSString *placeHolderText = @"No upcoming Alarms!";
static NSString *customFontColor = @"#00000";
static int nextAlarmThreshold = 24;


@interface SBFPagedScrollView : UIScrollView
@end

@interface _UILegibilitySettings
	@property (nonatomic,retain) UIColor * primaryColor;
@end

@interface SBUILegibilityLabel : UIView
	@property (assign,nonatomic) long long textAlignment;
	@property (nonatomic,retain) _UILegibilitySettings * legibilitySettings;
@end

@interface SBFLockScreenDateView : UIView
	@property (nonatomic,retain) UIColor * textColor;
	@property (nonatomic,readonly) double contentAlpha;
	@property (assign,nonatomic) double dateToTimeStretch;
	-(void)updateNextAlarm;
@end

@interface CSCoverSheetView : UIView
	@property (nonatomic,retain) SBFLockScreenDateView * dateView;
	@property (nonatomic,retain) SBFPagedScrollView * scrollView;
@end

@interface CSCoverSheetViewController : UIViewController
	@property (nonatomic,readonly) CSCoverSheetView * coverSheetView;
@end

@interface SBScheduledAlarmObserver : NSObject
	+(id)sharedInstance;
	-(id)init;
	-(void)_nextAlarmChanged:(id)arg1;
@end

@interface MTAlarm
	@property (nonatomic,readonly) NSDate * nextFireDate;
@end

@interface MTAlarmManager
	-(MTAlarm *)nextAlarmSync;
@end


static void updateVisibility(int action)
{
	[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
	 animations:^{ sakalAlarmLabel.alpha = action;}
	 completion:nil];
}


%hook SBFPagedScrollView

	-(void)setCurrentPageIndex:(unsigned long long)arg1
	{
		%orig;

		if (arg1 == 1)
			updateVisibility(1);
		 else
		 	updateVisibility(0);
	}
%end

%hook SBFLockScreenDateView

-(void)layoutSubviews
{
	%orig;

	if (!sakalAlarmLabel)
	{
		 // Add label
 		sakalAlarmLabel = [[UILabel alloc] init];
		[self addSubview:sakalAlarmLabel];

		[self updateNextAlarm];
	}
}

-(void)_updateLabels
{
	%orig;
	[self updateNextAlarm];
}

-(void)_updateLabelAlpha
{
	%orig;
	sakalAlarmLabel.alpha = self.contentAlpha;
}

-(void)setDateToTimeStretch:(double)arg1
{
	%orig;
	if (arg1 > 0)
		sakalAlarmLabel.frame = CGRectMake(sakalAlarmLabel.frame.origin.x,self.frame.origin.y + verticalOffset + arg1,sakalAlarmLabel.frame.size.width,sakalAlarmLabel.frame.size.height);
}

%new
-(void)updateNextAlarm
{
	//sakalAlarmView = [[UIView alloc] init];
	MTAlarmManager *alarmManager = MSHookIvar<MTAlarmManager *>([%c(SBScheduledAlarmObserver) sharedInstance], "_alarmManager");
	MTAlarm *nextAlarm = [alarmManager nextAlarmSync];

	NSString *nextAlarmString = nil;

	if (nextAlarm)
	{
		@try
		{
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:alarmFormat];
			NSString *nextAlarmAt = [formatter stringFromDate:nextAlarm.nextFireDate];

			int difference = [nextAlarm.nextFireDate timeIntervalSinceNow];

			if (difference > 0)
			{
				difference += 60; // Round to next minute
			}

			int hours = difference / 3600;
			int minutes = (difference / 60) % 60;

			if (hours < nextAlarmThreshold)
			{
				NSString *timeUntilAlarm = (hours > 0) ? [NSString stringWithFormat:@"%02d hr %02d min",hours,minutes] : [NSString stringWithFormat:@"%02d min",minutes];

				if (alarmType == 1)
					nextAlarmString = nextAlarmAt;
				else if (alarmType == 2)
					nextAlarmString = timeUntilAlarm;
				else
					nextAlarmString = [NSString stringWithFormat:@"%@ (%@)",nextAlarmAt,timeUntilAlarm];
			}
		}
		@catch (NSException *exception)
		{
			nextAlarmString = @"Invalid DateTime Format!";
		}
	}


	if (!nextAlarmString)
	{
		if (!placeHolderText.length)
		{
			sakalAlarmLabel.text = nil;
			sakalAlarmLabel.attributedText = nil;
			//updateVisibility(0);
			return;
		}
		else
		{
			nextAlarmString = placeHolderText;
		}
	}

	NSString *imagePath = [tweakBundle pathForResource:@"SakalLSIcon@2x" ofType:@"png"];
	UIImage *alarmImage = [[UIImage imageWithContentsOfFile:imagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

	NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
	attachment.image = alarmImage;
	UIFont *temp = [UIFont systemFontOfSize:fontSize];
	CGFloat mid = temp.descender + temp.capHeight;
	//CGFloat imgRatio = attachment.image.size.width / attachment.image.size.height;
	attachment.bounds = CGRectIntegral( CGRectMake(0, temp.descender - attachment.image.size.height / 2 + mid + 1, attachment.image.size.width, attachment.image.size.height));
	//[attachment setBounds:CGRectMake(0, roundf(sakalAlarmLabel.font.capHeight - alarmImage.size.height)/2.f, alarmImage.size.width, alarmImage.size.height)];

	 NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
	 NSMutableAttributedString *myString= [[NSMutableAttributedString alloc] initWithString:[@" " stringByAppendingString:nextAlarmString]];
	 [attachmentString appendAttributedString:myString];

	 UIFontWeight weightFont = UIFontWeightBold;

	 if (fontWeight == 0)
	 	weightFont = UIFontWeightThin;
	 else if (fontWeight == 1)
	 	weightFont = UIFontWeightRegular;
	 else if (fontWeight == 3)
	 	weightFont = UIFontWeightHeavy;

	 sakalAlarmLabel.textAlignment = fontAlignment;

		if (wantsCustomFontColor)
		{
			sakalAlarmLabel.textColor = LCPParseColorString(customFontColor, @"#000000");
		}
		else
		{
			SBUILegibilityLabel *timelabel = MSHookIvar<SBUILegibilityLabel *>(self, "_timeLabel");
			sakalAlarmLabel.textColor = timelabel.legibilitySettings.primaryColor;
		}

	 sakalAlarmLabel.font = [UIFont systemFontOfSize:fontSize weight:weightFont];
	 sakalAlarmLabel.attributedText = attachmentString;

	 // CGSize titleSize = [attachmentString.string sizeWithAttributes:
	 // @{NSFontAttributeName: [UIFont systemFontOfSize:16]}];
	 if ([[UIScreen mainScreen] bounds].size.width <= [[UIScreen mainScreen] bounds].size.height)
	 {
		 [sakalAlarmLabel setFrame:CGRectMake(horizontalOffset,self.frame.origin.y + verticalOffset, self.frame.size.width , fontSize + 5)];
	 }
	 else
	 {
		 [sakalAlarmLabel setFrame:CGRectMake(horizontalOffsetLS,self.frame.origin.y + verticalOffsetLS, self.frame.size.width , fontSize + 5)];
	 }

	 //updateVisibility(1);
}

%end

static void reloadSettings() {

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.p2kdev.sakal.plist"];
	if(prefs)
	{
		alarmFormat = [prefs objectForKey:@"formatSpecifier"] ? [[prefs objectForKey:@"formatSpecifier"] stringValue] : alarmFormat;
		placeHolderText = [prefs objectForKey:@"noAlarmText"] ? [[prefs objectForKey:@"noAlarmText"] stringValue] : placeHolderText;
		fontWeight = [prefs objectForKey:@"fontWeight"] ? [[prefs objectForKey:@"fontWeight"] intValue] : fontWeight;
		fontSize = [prefs objectForKey:@"fontSize"] ? [[prefs objectForKey:@"fontSize"] intValue] : fontSize;
		fontAlignment = [prefs objectForKey:@"fontAlignment"] ? [[prefs objectForKey:@"fontAlignment"] intValue] : fontAlignment;
		wantsCustomFontColor = [prefs objectForKey:@"wantsCustomColor"] ? [[prefs objectForKey:@"wantsCustomColor"] boolValue] : wantsCustomFontColor;
		customFontColor = [prefs objectForKey:@"customFontColor"] ? [[prefs objectForKey:@"customFontColor"] stringValue] : customFontColor;
		alarmType = [prefs objectForKey:@"alarmType"] ? [[prefs objectForKey:@"alarmType"] intValue] : alarmType;
		nextAlarmThreshold = [prefs objectForKey:@"alarmThreshold"] ? [[prefs objectForKey:@"alarmThreshold"] intValue] : nextAlarmThreshold;
		horizontalOffset = [prefs objectForKey:@"offsetWidth"] ? [[prefs objectForKey:@"offsetWidth"] floatValue] : horizontalOffset;
		verticalOffset = [prefs objectForKey:@"offsetHeight"] ? [[prefs objectForKey:@"offsetHeight"] floatValue] : verticalOffset;
		horizontalOffsetLS = [prefs objectForKey:@"offsetWidthLandscape"] ? [[prefs objectForKey:@"offsetWidthLandscape"] floatValue] : horizontalOffsetLS;
		verticalOffsetLS = [prefs objectForKey:@"offsetHeightLandscape"] ? [[prefs objectForKey:@"offsetHeightLandscape"] floatValue] : verticalOffsetLS;
	}
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.p2kdev.sakal.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
}
