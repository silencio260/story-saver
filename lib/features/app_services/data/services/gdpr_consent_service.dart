import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async'; // For Completer

// Add this flag to ensure MobileAds is initialized only once
bool _mobileAdsInitialized = false;
Completer<void> _consentFlowCompleter = Completer<void>();

Future<void> handleGDPRConsent() async {
  try {
    print("GDPR Consent: Starting consent flow...");

    await ConsentInformation.instance.reset();

    // For testing, you can force a specific geography and use test device IDs.
    final ConsentDebugSettings debugSettings = ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea, // Test as if in EEA
      // testIdentifiers: ["2784111F57168032C0CA8904D8AF16A5"]
      // testDeviceIdentifiers: ['YOUR_TEST_DEVICE_HASHED_ID_PLACEHOLDER'], // Get this from device logs when app runs
    );
    final ConsentRequestParameters params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );
    // For production, use default parameters (comment out the above debugSettings and params):
    // final ConsentRequestParameters params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        print(
          "GDPR Consent: Consent info updated. Status: ${await ConsentInformation.instance.getConsentStatus()}",
        );
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          print("GDPR Consent: Consent form is available. Loading form...");
          await _loadAndShowConsentForm(); // Added await here
        } else {
          print(
            "GDPR Consent: Consent form not available or not required at this time.",
          );
          await _completeConsentFlowAndInitializeAds(); // Added await here
        }
      },
      (FormError error) async {
        // Added async here
        print(
          'GDPR Consent: Error requesting consent info update: ${error.message}',
        );
        await _completeConsentFlowAndInitializeAds(); // Proceed even on error, SDK handles limited ads. Added await.
      },
    );

    return _consentFlowCompleter.future; // Allow main to await completion
  } catch (e) {
    print('GDPR Consent: Error in handleGDPRConsent: $e');
    await _completeConsentFlowAndInitializeAds(); // Proceed even on error. Added await.
  }
}

Future<void> _loadAndShowConsentForm() async {
  // Changed to Future<void> and made async
  try {
    ConsentForm.loadConsentForm(
      // Added await
      (ConsentForm consentForm) async {
        print(
          "GDPR Consent: Form loaded. Current status: ${await ConsentInformation.instance.getConsentStatus()}",
        );
        // Show the form if consent is required.
        if (await ConsentInformation.instance.getConsentStatus() ==
            ConsentStatus.required) {
          // It's good practice for the show method's callback to be async if it performs async operations,
          // though show itself might not return a Future that needs awaiting here directly.
          // The primary await is on loadConsentForm.
          consentForm.show((FormError? formError) async {
            // Made callback async
            if (formError != null) {
              print(
                'GDPR Consent: Error showing consent form: ${formError.message}',
              );
            }
            print('GDPR Consent: Form dismissed.');
            // After the form is dismissed, re-check status and proceed.
            await _completeConsentFlowAndInitializeAds(); // Added await
          });
        } else {
          // Consent not required (e.g., already obtained, or user not in EEA/UK)
          print("GDPR Consent: Consent status is not 'required'. Proceeding.");
          await _completeConsentFlowAndInitializeAds(); // Added await
        }
      },
      (FormError? formError) async {
        // Made callback async
        print(
          'GDPR Consent: Error loading consent form: ${formError?.message}',
        );
        await _completeConsentFlowAndInitializeAds(); // Proceed even on error. Added await.
      },
    );
  } catch (e) {
    print('GDPR Consent: Error in _loadAndShowConsentForm: $e');
    await _completeConsentFlowAndInitializeAds(); // Proceed even on error. Added await.
  }
}

// This function will now initialize MobileAds
Future<void> _completeConsentFlowAndInitializeAds() async {
  // Changed to Future<void>
  try {
    final status = await ConsentInformation.instance.getConsentStatus();
    print("GDPR Consent: Final Consent Status before Ad Init: $status");

    if (!_mobileAdsInitialized) {
      print("GDPR Consent: Initializing Mobile Ads SDK...");
      // MobileAds.instance.initialize() returns a Future, so it should be awaited
      // if subsequent logic depends on its completion immediately.
      // However, we are using a Completer to signal overall flow completion.
      MobileAds.instance
          .initialize()
          .then((InitializationStatus initStatus) {
            _mobileAdsInitialized = true;
            print('GDPR Consent: Mobile Ads Initialized.');
            // TODO: You can now proceed to load your ads (e.g., in AdConfig or elsewhere)
            // Make sure your ad loading logic waits for this initialization.

            // Complete the completer here if it hasn't been already and ads are initialized.
            if (!_consentFlowCompleter.isCompleted) {
              _consentFlowCompleter.complete();
            }
          })
          .catchError((error) {
            print('GDPR Consent: Error initializing Mobile Ads: $error');
            // Complete with error or normally depending on desired behavior
            if (!_consentFlowCompleter.isCompleted) {
              _consentFlowCompleter.complete(); // Or completeError(error)
            }
          });
    } else {
      // If ads are already initialized, but completer isn't done (e.g., consent form wasn't needed)
      if (!_consentFlowCompleter.isCompleted) {
        _consentFlowCompleter.complete();
      }
    }
  } catch (e) {
    print('GDPR Consent: Error in _completeConsentFlowAndInitializeAds: $e');
  }
}

// Optional: Function to allow users to change their consent
// You would call this from your app's settings screen.
Future<void> showPrivacyOptionsForm() async {
  try {
    print("GDPR Consent: Showing privacy options form...");
    ConsentForm.loadConsentForm(
      // Added await
      (ConsentForm consentForm) async {
        consentForm.show((FormError? formError) {
          if (formError != null) {
            print(
              'GDPR Consent: Error showing privacy options form: ${formError.message}',
            );
          }
          // Handle dismissal/update
        });
      },
      (FormError? formError) {
        print(
          'GDPR Consent: Error loading privacy options form: ${formError?.message}',
        );
      },
    );
  } catch (e) {
    print('GDPR Consent: Error in showPrivacyOptionsForm: $e');
  }
}
