## NEXT

* Updates minimum supported SDK version to Flutter 3.13/Dart 3.1.

## 1.0.37

* Adds compatibility with `intl` 0.19.0.
* Updates compileSdk version to 34.

## 1.0.36

* Updates androidx.fragment version to 1.6.2.

## 1.0.35

* Updates androidx.fragment version to 1.6.1.

## 1.0.34

* Updates pigeon to 11.0.0 and removes enum wrappers.

## 1.0.33

* Adds pub topics to package metadata.
* Updates minimum supported SDK version to Flutter 3.7/Dart 2.19.

## 1.0.32

* Fixes stale ignore: prefer_const_constructors.
* Updates minimum supported SDK version to Flutter 3.10/Dart 3.0.
* Updates androidx.fragment version to 1.6.0.

## 1.0.31

* Updates androidx.fragment version to 1.5.7.
* Updates androidx.core version to 1.10.1.

## 1.0.30

* Updates androidx.fragment version to 1.5.6

## 1.0.29

* Fixes a regression in 1.0.23 that caused canceled auths to return success.
* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.

## 1.0.28

* Removes unused resources as indicated by Android lint warnings.

## 1.0.27

* Fixes compatibility with AGP versions older than 4.2.

## 1.0.26

* Adds `targetCompatibilty` matching `sourceCompatibility` for older toolchains.

## 1.0.25

* Adds a namespace for compatibility with AGP 8.0.

## 1.0.24

* Fixes `getEnrolledBiometrics` return value handling.

## 1.0.23

* Switches internals to Pigeon and fixes Java warnings.

## 1.0.22

* Sets an explicit Java compatibility version.

## 1.0.21

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 1.0.20

* Fixes compilation warnings.
* Updates compileSdkVersion to 33.

## 1.0.19

* Updates links for the merge of flutter/plugins into flutter/packages.

## 1.0.18

* Updates minimum Flutter version to 3.0.
* Updates androidx.core version to 1.9.0.
* Upgrades compile SDK version to 33.

## 1.0.17

* Adds compatibility with `intl` 0.18.0.

## 1.0.16

* Updates androidx.fragment version to 1.5.5.

## 1.0.15

* Updates androidx.fragment version to 1.5.4.

## 1.0.14

* Fixes device credential authentication for API versions before R.

## 1.0.13

* Updates imports for `prefer_relative_imports`.

## 1.0.12

* Updates androidx.fragment version to 1.5.2.
* Updates minimum Flutter version to 2.10.

## 1.0.11

* Fixes avoid_redundant_argument_values lint warnings and minor typos.

## 1.0.10

* Updates `local_auth_platform_interface` constraint to the correct minimum
  version.

## 1.0.9

* Updates  androidx.fragment version to 1.5.1.

## 1.0.8

* Removes usages of `FingerprintManager` and other `BiometricManager` deprecated method usages.

## 1.0.7

* Updates gradle version to 7.2.1.

## 1.0.6

* Updates androidx.core version to 1.8.0.

## 1.0.5

* Updates references to the obsolete master branch.

## 1.0.4

* Minor fixes for new analysis options.

## 1.0.3

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 1.0.2

* Fixes `getEnrolledBiometrics` to match documented behaviour:
  Present biometrics that are not enrolled are no longer returned.
* `getEnrolledBiometrics` now only returns `weak` and `strong` biometric types.
* `deviceSupportsBiometrics` now returns the correct value regardless of enrollment state.

## 1.0.1

* Adopts `Object.hash`.

## 1.0.0

* Initial release from migration to federated architecture.
