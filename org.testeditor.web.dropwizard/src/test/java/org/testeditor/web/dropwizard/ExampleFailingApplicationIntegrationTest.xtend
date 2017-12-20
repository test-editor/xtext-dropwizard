package org.testeditor.web.dropwizard

import io.dropwizard.testing.junit.DropwizardAppRule
import org.junit.Test

import static org.junit.Assert.assertTrue
import static org.junit.Assert.fail

class ExampleFailingApplicationIntegrationTest {

	@Test
	def void failingAppStartWithInvalidApiTokenButApiTokenAuthAnnotatedResources() {
		// given (Example app has ApiTokenAuth annotated resources!)
		val illegalApiToken = ''
		val config = new ExampleConfiguration => [
			allowedOrigins = '*'
			apiToken = illegalApiToken
		]
		val dropwizardRule = new DropwizardAppRule(ExampleApplication, config)

		// when (starting the application)
		try {
			dropwizardRule.testSupport.before

			// then
			fail('expected exception NOT thrown')
		} catch (Exception exception) {
			val expectedExceptionThrown = exception.anyCauseMatches(RuntimeException, "dropwizard configuration exception: missing field 'apiToken' for accessing")
			assertTrue(expectedExceptionThrown)
		}
	}

	@Test
	def void failingAppStartWithMissingApiTokenButApiTokenAuthAnnotatedResources() {
		// given (Example app has ApiTokenAuth annotated resources!)
		val config = new ExampleConfiguration => [
			allowedOrigins = '*'
		]
		val dropwizardRule = new DropwizardAppRule(ExampleApplication, config)

		// when (starting the application)
		try {
			dropwizardRule.testSupport.before

			// then
			fail('expected exception NOT thrown')
		} catch (Exception exception) {
			val expectedExceptionThrown = exception.anyCauseMatches(RuntimeException, "dropwizard configuration exception: missing field 'apiToken' for accessing")
			assertTrue(expectedExceptionThrown)
		}
	}

	private def boolean anyCauseMatches(Throwable e, Class<?> clazz, String message) {
		if (clazz.isAssignableFrom(e.class) && e.message.contains(message)) {
			return true
		} else if (e.cause !== null) {
			return anyCauseMatches(e.cause, clazz, message)
		}
		return false
	}

}
