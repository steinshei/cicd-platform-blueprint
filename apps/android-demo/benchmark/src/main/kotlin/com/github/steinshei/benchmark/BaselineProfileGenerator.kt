package com.github.steinshei.benchmark

import android.os.Build
import android.util.Log
import androidx.benchmark.macro.junit4.BaselineProfileRule
import androidx.test.filters.SdkSuppress
import androidx.test.uiautomator.By
import androidx.test.uiautomator.BySelector
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiObject2
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test

/**
 * Generates a baseline profile which can be copied to `app/src/main/baseline-prof.txt`.
 */
@SdkSuppress(minSdkVersion = Build.VERSION_CODES.P)
class BaselineProfileGenerator {
  @get:Rule
  val baselineProfileRule = BaselineProfileRule()

  @Test
  fun startup() = baselineProfileRule.collect(
    packageName = PACKAGE_NAME,
    stableIterations = 2,
    maxIterations = 5,
    includeInStartupProfile = true
  ) {
    pressHome()
    // This block defines the app's critical user journey. Here we are interested in
    // optimizing for app startup. But you can also navigate and scroll
    // through your most important UI.
    startActivityAndWait()
    device.waitForIdle()

    if (!device.discover()) {
      Log.e("BaselineProfile", "Discover screen not found, skipping this iteration")
      return@collect
    }

    device.fromMainToDetails()
    device.pressBack()
  }
}

private fun UiDevice.discover(): Boolean {
  return wait(Until.hasObject(By.res(PACKAGE_NAME, "constraintLayout")), 1_000)
}

private fun UiDevice.fromMainToDetails() {
  waitForObject(By.res(PACKAGE_NAME, "clickButton")).click()
  wait(Until.hasObject(By.res(PACKAGE_NAME, "messageText")), 1_000)
  waitForIdle()
  pressBack()
}

private fun UiDevice.waitForObject(selector: BySelector, timeout: Long = 5_000): UiObject2 {
  if (wait(Until.hasObject(selector), timeout)) {
    return findObject(selector)
  }
  error("Object with selector [$selector] not found")
}
