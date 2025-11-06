# Fly Feedback

A comprehensive Flutter feedback system with fully customizable, theme-based handlers.

## Color System

All colors in Fly Feedback are dynamically derived from Material Design 3 `ColorScheme`. No
hardcoded colors are used, ensuring perfect theme adaptation for both light and dark modes.

### Color Mapping by Feedback Type

#### Success Feedback

- **Background Color**: `colorScheme.primary`
- **Icon Color**: `colorScheme.onPrimary`
- **Text Color**: `colorScheme.onPrimary`

#### Error Feedback

- **Background Color**: `colorScheme.error`
- **Icon Color**: `colorScheme.onError`
- **Text Color**: `colorScheme.onError`

#### Warning Feedback

- **Background Color**: `colorScheme.tertiary`
- **Icon Color**: `colorScheme.onTertiary`
- **Text Color**: `colorScheme.onTertiary`

#### Info Feedback

- **Background Color**: `colorScheme.secondary`
- **Icon Color**: `colorScheme.onSecondary`
- **Text Color**: `colorScheme.onSecondary`

### Fallback Colors

When configuration doesn't specify colors, the following fallbacks are used:

#### Background Colors

- **Default Fallback**: `colorScheme.surfaceContainer`
    - Used when no background color is configured for a feedback type
    - Provides a neutral surface that works in both light and dark themes

#### Icon and Text Colors

- **Default Fallback**: `colorScheme.onSurface`
    - Used when no icon or text color is configured
    - Ensures proper contrast on neutral backgrounds

#### Error Color Fallback

- **Primary**: `colorScheme.error` (from config or theme)
- **Secondary**: `colorScheme.error` (from theme if config unavailable)
- **Last Resort**: `ColorScheme.light().error` (should never be reached)

### Handler-Specific Colors

#### Banner Handler

- **Background**: Uses feedback type color mapping (see above)
- **Icon**: Uses feedback type icon color mapping
- **Text**: Uses feedback type text color mapping
- **Action Buttons**: Use icon color for text color

#### Snackbar Handler

- **Background**: Uses feedback type color mapping
- **Icon**: Uses feedback type icon color mapping
- **Text**: Uses feedback type text color mapping
- **Action Button**: Uses text color for label color

#### Toast Handler

- **Background**: Uses feedback type color mapping
- **Icon**: Uses feedback type icon color mapping
- **Text**: Uses feedback type text color mapping
- **Shadow Color**: `colorScheme.shadow`
    - Default fallback for toast shadow
    - Provides appropriate shadow color for current theme

#### Dialog Handler

- **Background**: Uses theme's default dialog background
- **Error Button Background**: `colorScheme.error` (for dangerous actions)
- **Error Button Text**: `colorScheme.onError`

#### Bottom Sheet Handler

##### Confirmation Bottom Sheet

- **Background**: Uses theme's default bottom sheet background
- **Handle Bar Color**: `colorScheme.outline`
    - Default fallback when not configured
    - Provides subtle visual indicator
- **Confirm Button (Dangerous)**:
    - Background: `colorScheme.error`
    - Text: `colorScheme.onError`
- **Confirm Button (Normal)**:
    - Uses theme's default button styling

##### Feedback Bottom Sheet

- **Background**: Uses feedback type color mapping
- **Icon**: Uses feedback type icon color mapping
- **Text**: Uses feedback type text color mapping
- **Handle Bar Color**: `colorScheme.onSurface.withValues(alpha: 0.3)`
    - Semi-transparent on-surface color for visual indicator
- **Action Button Background**: `colorScheme.surface`
- **Action Button Text**: Uses background color of feedback type

### ColorScheme Properties Used

The following `ColorScheme` properties are utilized throughout the feedback system:

#### Primary Colors

- `colorScheme.primary` - Success feedback background
- `colorScheme.onPrimary` - Success feedback text/icon
- `colorScheme.secondary` - Info feedback background
- `colorScheme.onSecondary` - Info feedback text/icon
- `colorScheme.tertiary` - Warning feedback background
- `colorScheme.onTertiary` - Warning feedback text/icon

#### Error Colors

- `colorScheme.error` - Error feedback background
- `colorScheme.onError` - Error feedback text/icon, dangerous button text

#### Surface Colors

- `colorScheme.surface` - Button backgrounds, default surfaces
- `colorScheme.surfaceContainer` - Fallback background color
- `colorScheme.onSurface` - Fallback text/icon color, handle bars

#### Outline Colors

- `colorScheme.outline` - Handle bar color (confirmation bottom sheet)

#### Shadow Colors

- `colorScheme.shadow` - Toast shadow color

### Customization

All colors can be customized through handler configurations:

```dart

final config = BannerFeedbackHandlerConfig(
  backgroundColors: {
    FeedbackType.success: Colors.customGreen,
    // ... other types
  },
  iconColors: {
    FeedbackType.success: Colors.customWhite,
    // ... other types
  },
  textColors: {
    FeedbackType.success: Colors.customWhite,
    // ... other types
  },
);

final handler = BannerFeedbackHandler(config: config);
```

When colors are not specified in the configuration, the system automatically uses theme-based
defaults as described above.

### Theme Adaptation

The color system automatically adapts to:

- **Light Theme**: Uses light ColorScheme colors
- **Dark Theme**: Uses dark ColorScheme colors
- **Custom Themes**: Uses any custom ColorScheme provided

All colors maintain proper contrast ratios for accessibility in both light and dark modes.

## Usage

See the main package documentation for usage examples and API reference.
