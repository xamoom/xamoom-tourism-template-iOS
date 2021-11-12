# xamoom-tourism-template-iOS

## Pods
1. Install pods via command ```pod install```

## Buid system
1. Open File -> Workpace settings
2. Select ```Legacy Build System```
3. Check ```Do not show a diagnostics issue about buid system deprication```.

## Firebase
1. Register your app in Firebase.
2. Upload ```GoogleService-Info.plist``` to the tourismtemplate folder.
3. Change Bundle Identifier in General -> Identity.

## Info.plist
1. Set ```MGLMapboxAccessToken```
2. Change Bundle display name 

## gen.plist
1. Set ```maps-api-key```
2. Set ```beacon-major```
3. Set ```custom-webclient``` (contact Xamoom support)
4. Set ```custom-webclient-host``` (contact Xamoom support)
5. Set ```tracking_id``` in format UA-******** (Google Analytics)
6. Set ```urls``` if you need to access to specific urls only.
7. Set ```non-internal-urls```, if you want to block custom urls.
8. Set ```is_background_image``` = true, if you want to use background image for tabbar and navigation bar.
9. Set ```enable_quiz_feature``` = true, if you want to use quiz app feature (contact Xamoom support).
