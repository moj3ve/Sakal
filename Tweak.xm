#import <libcolorpicker.h>

@interface SBFPagedScrollView : UIScrollView
@end

@interface _UILegibilitySettings
	@property (nonatomic,retain) UIColor * primaryColor;
@end

@interface SBUILegibilityLabel : UIView
	@property (assign,nonatomic) long long textAlignment;
	@property (nonatomic,retain) _UILegibilitySettings * legibilitySettings;
@end

@interface SBFLockScreenDateSubtitleView : UIView
@end

@interface SBFLockScreenDateView : UIView
	@property (nonatomic,retain) UIColor * textColor;
	@property (nonatomic,retain) UIView * sakalNextAlarmView;
	@property (nonatomic,retain) UILabel * sakalAlarmLabel;
	@property (nonatomic,readonly) double contentAlpha;
	@property (nonatomic,retain) SBFLockScreenDateSubtitleView * customSubtitleView;
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

// Bundle
static const NSBundle *tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Sakal"];

static NSDate *lastKnownFireDate;
static bool wantsCustomFontColor = NO;
static int fontSize = 16;
static int fontWeight = 2;
static int alarmType = 1;
static CGFloat verticalOffset = -15;
static NSString *alarmFormat = @" EEE hh:mm a";
static NSString *placeHolderText = @"No upcoming Alarms!";
static NSString *customFontColor = @"#00000";
static int nextAlarmThreshold = 24;

%hook SBFLockScreenDateView
	%property (nonatomic,retain) UILabel * sakalAlarmLabel;

-(id)initWithFrame:(CGRect)arg1
{
	id orig = %orig;

	if (orig)
	{
		 // Add label
 		self.sakalAlarmLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.sakalAlarmLabel.adjustsFontSizeToFitWidth = YES;
		[orig addSubview:self.sakalAlarmLabel];
		self.sakalAlarmLabel.translatesAutoresizingMaskIntoConstraints = NO;

		SBUILegibilityLabel* timeLabel = MSHookIvar<SBUILegibilityLabel*>(self,"_timeLabel");
		[self.sakalAlarmLabel.centerXAnchor constraintEqualToAnchor:timeLabel.centerXAnchor constant:0].active = YES;
		[self.sakalAlarmLabel.topAnchor constraintEqualToAnchor:timeLabel.topAnchor constant:verticalOffset].active = YES;
	}

	return orig;
}

-(void)_updateLabels
{
	%orig;
	[self updateNextAlarm];
}

-(void)_updateLabelAlpha
{
	%orig;
	self.sakalAlarmLabel.alpha = self.contentAlpha;
}

%new
-(void)updateNextAlarm
{
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
			self.sakalAlarmLabel.text = nil;
			self.sakalAlarmLabel.attributedText = nil;
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

	 	//self.sakalAlarmLabel.textAlignment = fontAlignment;

		SBUILegibilityLabel *timelabel = MSHookIvar<SBUILegibilityLabel *>(self, "_timeLabel");

		if (wantsCustomFontColor)
		{
			self.sakalAlarmLabel.textColor = LCPParseColorString(customFontColor, @"#000000");
		}
		else
		{
			self.sakalAlarmLabel.textColor = timelabel.legibilitySettings.primaryColor;
		}

	 self.sakalAlarmLabel.font = [UIFont systemFontOfSize:fontSize weight:weightFont];
	 self.sakalAlarmLabel.attributedText = attachmentString;
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
		wantsCustomFontColor = [prefs objectForKey:@"wantsCustomColor"] ? [[prefs objectForKey:@"wantsCustomColor"] boolValue] : wantsCustomFontColor;
		customFontColor = [prefs objectForKey:@"customFontColor"] ? [[prefs objectForKey:@"customFontColor"] stringValue] : customFontColor;
		alarmType = [prefs objectForKey:@"alarmType"] ? [[prefs objectForKey:@"alarmType"] intValue] : alarmType;
		nextAlarmThreshold = [prefs objectForKey:@"alarmThreshold"] ? [[prefs objectForKey:@"alarmThreshold"] intValue] : nextAlarmThreshold;
		verticalOffset = [prefs objectForKey:@"verticalOffset"] ? [[prefs objectForKey:@"verticalOffset"] floatValue] : verticalOffset;
	}
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettings, CFSTR("com.p2kdev.sakal.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings();
}
