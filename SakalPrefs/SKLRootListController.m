#import <Preferences/Preferences.h>
#import <libcolorpicker.h>

#define tweakPrefPath @"/User/Library/Preferences/com.p2kdev.sakal.plist"

@interface SKLRootListController : PSListController
@end

@implementation SKLRootListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Sakal" target:self] retain];
	}
	return _specifiers;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:tweakPrefPath];

	NSString *key = [specifier propertyForKey:@"key"];
	id defaultValue = [specifier propertyForKey:@"default"];
	id plistValue = [tweakSettings objectForKey:key];
	if (!plistValue) plistValue = defaultValue;

	if ([key isEqualToString:@"wantsCustomColor"])
	{
		BOOL enableCell = plistValue && [plistValue boolValue];
		[self setCellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] enabled:enableCell];
	}

	return plistValue;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:tweakPrefPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:tweakPrefPath atomically:YES];

	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);

	if ([specifier.properties[@"key"] isEqualToString:@"wantsCustomColor"])
	{
		BOOL enableCell = [value boolValue];
		[self setCellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] enabled:enableCell];
	}
}

- (void)setCellForRowAtIndexPath:(NSIndexPath *)indexPath enabled:(BOOL)enabled
{
	UITableViewCell *cell = [self tableView:self.table cellForRowAtIndexPath:indexPath];
	if (cell) {
		cell.userInteractionEnabled = enabled;
		cell.textLabel.enabled = enabled;
		cell.detailTextLabel.enabled = enabled;

		if ([cell isKindOfClass:[PSControlTableCell class]]) {
			PSControlTableCell *controlCell = (PSControlTableCell *)cell;
			if (controlCell.control) {
				controlCell.control.enabled = enabled;
			}
		}
	}
}


- (void)visitTwitter {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/p2kdev"]];
}

@end
