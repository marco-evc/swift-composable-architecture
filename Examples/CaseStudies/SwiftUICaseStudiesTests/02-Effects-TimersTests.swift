import ComposableArchitecture
import XCTest

@testable import SwiftUICaseStudies

@MainActor
final class TimersTests: XCTestCase {
  func testStart() async {
    let store = TestStore(
      initialState: Timers.State(),
      reducer: Timers()
    )

    let mainQueue = DispatchQueue.test
    store.dependencies.mainQueue = mainQueue.eraseToAnyScheduler()

    await store.send(.toggleTimerButtonTapped) {
      $0.isTimerActive = true
    }
    await mainQueue.advance(by: 1)
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 1
    }
    await mainQueue.advance(by: 5)
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 2
    }
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 3
    }
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 4
    }
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 5
    }
    await store.receive(.timerTicked) {
      $0.secondsElapsed = 6
    }
    await store.send(.toggleTimerButtonTapped) {
      $0.isTimerActive = false
    }
  }
}
