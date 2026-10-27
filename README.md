# ProductNavigator

An iOS Coordinator-pattern exercise built with Swift and UIKit. **Work in progress.**

The current app starts with a navigation controller and a Products list showing sample names and descriptions.

Steps 2–5 are in place: storyboard-free app launch, a `Product` model, an injectable `ProductProviding` protocol with sample data, a product list, and a detail screen. Tap a product to see its name and description, then use Back to return to the list.

`SceneDelegate` creates the window and retains `AppCoordinator`. The coordinator creates screens, injects their dependencies, and handles navigation. The list reports selection through a weak delegate; the detail screen displays its injected product.

The list now receives a `ProductListViewModel`. The view model owns the provider and the current products; its synchronous `load()` replaces those products with the provider's result. The controller asks it to load and renders its products. Loading indicators, errors, networking, and pagination will be introduced incrementally.

Open `ProductNavigator.xcodeproj` in Xcode, select the ProductNavigator scheme and an iOS simulator, then run the app.

The unit tests cover injected list data, empty data, selection callbacks, weak delegate ownership, and coordinator-driven detail navigation. The UI test opens each sample product, checks its details, and returns to the list.

Run the unit tests with **Product → Test** in Xcode, or from this project directory (replace the destination with an available simulator):

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
