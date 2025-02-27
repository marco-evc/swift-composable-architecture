import Combine
import ComposableArchitecture
import XCTest

@testable import SpeechRecognition

@MainActor
final class SpeechRecognitionTests: XCTestCase {
  let recognitionTask = AsyncThrowingStream<SpeechRecognitionResult, Error>.streamWithContinuation()

  func testDenyAuthorization() async {
    let store = TestStore(
      initialState: SpeechRecognition.State(),
      reducer: SpeechRecognition()
    )

    store.dependencies.speechClient.requestAuthorization = { .denied }

    await store.send(.recordButtonTapped) {
      $0.isRecording = true
    }
    await store.receive(.speechRecognizerAuthorizationStatusResponse(.denied)) {
      $0.alert = AlertState(
        title: TextState(
          """
          You denied access to speech recognition. This app needs access to transcribe your speech.
          """
        )
      )
      $0.isRecording = false
    }
  }

  func testRestrictedAuthorization() async {
    let store = TestStore(
      initialState: SpeechRecognition.State(),
      reducer: SpeechRecognition()
    )

    store.dependencies.speechClient.requestAuthorization = { .restricted }

    await store.send(.recordButtonTapped) {
      $0.isRecording = true
    }
    await store.receive(.speechRecognizerAuthorizationStatusResponse(.restricted)) {
      $0.alert = AlertState(title: TextState("Your device does not allow speech recognition."))
      $0.isRecording = false
    }
  }

  func testAllowAndRecord() async {
    let store = TestStore(
      initialState: SpeechRecognition.State(),
      reducer: SpeechRecognition()
    )

    store.dependencies.speechClient.finishTask = { self.recognitionTask.continuation.finish() }
    store.dependencies.speechClient.startTask = { _ in self.recognitionTask.stream }
    store.dependencies.speechClient.requestAuthorization = { .authorized }

    let firstResult = SpeechRecognitionResult(
      bestTranscription: Transcription(
        formattedString: "Hello",
        segments: []
      ),
      isFinal: false,
      transcriptions: []
    )
    var secondResult = firstResult
    secondResult.bestTranscription.formattedString = "Hello world"

    await store.send(.recordButtonTapped) {
      $0.isRecording = true
    }

    await store.receive(.speechRecognizerAuthorizationStatusResponse(.authorized))

    self.recognitionTask.continuation.yield(firstResult)
    await store.receive(.speech(.success("Hello"))) {
      $0.transcribedText = "Hello"
    }

    self.recognitionTask.continuation.yield(secondResult)
    await store.receive(.speech(.success("Hello world"))) {
      $0.transcribedText = "Hello world"
    }

    await store.send(.recordButtonTapped) {
      $0.isRecording = false
    }

    await store.finish()
  }

  func testAudioSessionFailure() async {
    let store = TestStore(
      initialState: SpeechRecognition.State(),
      reducer: SpeechRecognition()
    )

    store.dependencies.speechClient.startTask = { _ in self.recognitionTask.stream }
    store.dependencies.speechClient.requestAuthorization = { .authorized }

    await store.send(.recordButtonTapped) {
      $0.isRecording = true
    }

    await store.receive(.speechRecognizerAuthorizationStatusResponse(.authorized))

    recognitionTask.continuation.finish(throwing: SpeechClient.Failure.couldntConfigureAudioSession)
    await store.receive(.speech(.failure(SpeechClient.Failure.couldntConfigureAudioSession))) {
      $0.alert = AlertState(title: TextState("Problem with audio device. Please try again."))
    }
  }

  func testAudioEngineFailure() async {
    let store = TestStore(
      initialState: SpeechRecognition.State(),
      reducer: SpeechRecognition()
    )

    store.dependencies.speechClient.startTask = { _ in self.recognitionTask.stream }
    store.dependencies.speechClient.requestAuthorization = { .authorized }

    await store.send(.recordButtonTapped) {
      $0.isRecording = true
    }

    await store.receive(.speechRecognizerAuthorizationStatusResponse(.authorized))

    recognitionTask.continuation.finish(throwing: SpeechClient.Failure.couldntStartAudioEngine)
    await store.receive(.speech(.failure(SpeechClient.Failure.couldntStartAudioEngine))) {
      $0.alert = AlertState(title: TextState("Problem with audio device. Please try again."))
    }
  }
}
