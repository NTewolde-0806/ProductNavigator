# ProductNavigator

An iOS Coordinator-pattern exercise built with Swift and UIKit. **The agreed learning scope is complete.**

The current app starts with a navigation controller and a Products list showing sample names and descriptions.

The completed exercise includes storyboard-free app launch, a `Product` model, an injectable `ProductProviding` protocol with sample data, a product list, and a detail screen. Tap a product to see its name and description, then use Back to return to the list. The view-model extension adds asynchronous loading, explicit screen states, and Retry.

`SceneDelegate` creates the window and retains `AppCoordinator`. The coordinator creates screens, injects their dependencies, and handles navigation. The list reports selection through a weak delegate; the detail screen displays its injected product.

The list receives a `ProductListViewModel`. The view model owns the provider and exposes `.idle`, `.loading`, `.loaded(products)`, `.empty`, or `.failed(message:)` state. Its async `load()` publishes loading before awaiting the provider, ignores overlapping loads, and publishes the result afterward. `products` is derived from state. The controller binds `onStateChange` before starting a Task, then renders a spinner, rows, an empty message, or a failure message with Retry. The callback captures the controller weakly; the Task captures only the view model. This is a single-observer binding for one screen.

`ProductProviding.products()` is async, throwing, and main-actor isolated. Provider errors become a friendly screen message; Retry uses the same guarded load operation. The sample provider returns immediately, so its spinner may only flash briefly. Tests use a suspended provider to verify loading without artificial delays.

This is a focused learning project using fictional data. Refresh with retained data, cancellation, real networking, persistence, and pagination are optional future exercises, outside the completed scope. No required implementation tasks remain.

Open `ProductNavigator.xcodeproj` in Xcode, select the ProductNavigator scheme and an iOS simulator, then run the app.

The 13 unit tests cover injected data, state notifications, loading and empty states, duplicate-request prevention, failure and Retry recovery, weak ownership, and coordinator-driven detail navigation. The UI test opens each sample product, checks its details, and returns to the list.

Run both test targets with **Product → Test** in Xcode. To run only the unit tests from this project directory (replace the destination with an available simulator):

```sh
xcodebuild -project ProductNavigator.xcodeproj -scheme ProductNavigator \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:ProductNavigatorTests test
```

Remove `-only-testing:ProductNavigatorTests` from the command to run both the unit and UI tests.

### Following a selection

1. The coordinator injects the provider into a view model and the view model into the list. The list asks the view model to load, then renders its products.
2. A row tap invokes the list's delegate with the selected product.
3. `AppCoordinator`, the delegate, creates the detail screen and pushes it.
4. The detail screen displays its injected product. The navigation controller supplies Back behavior.

`SceneDelegate` strongly retains the coordinator. The coordinator retains the navigation controller, which retains its screens. The list's delegate is weak so the list does not keep the coordinator alive through a reference cycle.
