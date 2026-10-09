# TrainMe
Online Technology Training Application

# Why this architecture?
SwiftUI + MVVM with a repository layer:
View → ViewModel (@Observable, @MainActor) → Repository (actor) → CourseAPI (mock) + CourseStore (SwiftData) Session:     SessionStore → TokenStorage (Keychain)
I choose this because the app has one data source and little business logic. If the domain grows, use cases slot in between ViewModel and repository.
And since the view model is not importing any of the UI elements, it maintains modularity and testability.

# How is offline data stored and loaded?
Storage: SwiftData with two models, CourseEntity and LessonEntity, linked by a cascade-delete relationship. All access goes through a @ModelActor, so database work is off the main thread and each operation is atomic.

  b) It tries the network first and syncs the result into the database: upsert in server order, delete courses the server no longer returns.
  a) If the request fails and courses were stored before, it shows the stored list with an “offline” banner. The network error only appears when nothing is stored, which is the first visit.

# Where would authentication tokens be stored in production?
In the iOS Keychain, which is what the app already does. Not in UserDefaults, SwiftData or files, because those are readable in backups and on jailbroken devices.

# Improvements for 1 million users and hundreds of courses
a)  We will bring pagination for large set of courses.
b)  Convert the app to a offline-fist app by implementing a background scheduler to sync the pending data into server
c)  Add a SwiftData versioned schema with migrations, because a failed migration on a million devices is a disaster.
d)  Add crash reporting tools for reporting crashes and troubleshooting.

# How would I implement it on Android?
The architecture carries over almost one-to-one:
#iOS                                #Android
----                                ----------
SwiftUI                 -- >         Jetpack Compose
@Observable ViewModel   -- > 	       ViewModel exposing StateFlow<UiState> 
async/await, actors	    -- >         Kotlin coroutines and Flow
AppContainer	          -- >         Hilt modules for dependency injection
NavigationStack	        -- >         Navigation Compose
URLSession / mock API	  -- >         Retrofit + OkHttp with kotlinx.serialization
SwiftData	              -- >         Room DB
Keychain	              -- >         Keystore-backed encryption


