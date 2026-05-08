I want to make an iOS app named Timer using the frameworks - UIKit, SwiftData. Use Swift as the programming language. Have iOS18 as the minimum version.

It will have these view controllers - 
TimerViewController
ActivityTypesViewController
ActivityHistoryViewController
ActivityDetailsViewController


#### Persistence Behavior

1. SwiftData entity called ActivityCache with these properties - activityTypeUniqueID, startTime, timeElapsed, isRunning, lastUpdateTime. Each of them are required, and it need not have any relationship to any other entity. isRunning true indicates timer is running, false indicates timer is false

2. Anytime the user starts a timer, persist a new ActivityCache instance. Have the isRunning as true, generate a UUID for activityTypeUniqueID, timeElapsed as 0, both startTime and lastUpdateTime as current time.

3. Anytime the user pauses a timer, locate the ActivityCache instance which has the associated activitytype's id as the activityTypeUniqueID and update it. Mark isRunning as false, increment timeElapased as the time that has passed between the previously saved lastUpdateTime and current time, and then mark lastUpdateTime as current time.

4. Anytime user resumes a paused timer, locate the ActivityCache instance which has the associated activitytype's id as the activityTypeUniqueID and update it. Mark isRunning as true, don't touch timeElapased, and then mark lastUpdateTime as current time.

5. Anytime user stops a timer, locate the ActivityCache instance which has the associated activitytype's id as the activityTypeUniqueID and delete it.

6. Anytime user deletes an activitytype, locate all ActivityCache which have that activitytype's id as their activitytypeUniqueID and delete them too

7. Every 5 min, inspect all the activitycache instances and update them by matching with active timers

8. When app is launched, check if activitycache has any entries and for the ones whose lastUpdateTime is less than 8 hrs, reinstante those timers accordingly. Make sure all of the UI is also updated


Next things - 
k ActivityDetailsVC: UI for all fields + edit persistence + delete persistence
k ActivityTypesVC: Swipe to delete persistence
k ActivityHistoryVC: Intelligent icons in bottom floating button
k ActivityHistoryVC: Swipe to delete UI + persistence

k tags - show in activitytypesvc rows
k tags - a way to filter using tags, add/rename/remove too
k tags - show in activityhistoryvc too
k tags - empty state in both activitytypesvc and activityhistoryvc
k tags- edit tags for an existing type
k tags - filter using tags in activityttpesvc
force quit app - how to continue
if a type is deleted, both the activies and its cache should be cleared

redesign theme, explore mode designs
settings for dark/light mode


activityhistoryvc: Better UI when there are plenty of entries, may be year/month sections.
watchOS app
widgets/intents
insights