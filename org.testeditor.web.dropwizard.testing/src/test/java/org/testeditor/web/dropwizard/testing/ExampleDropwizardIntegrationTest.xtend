package org.testeditor.web.dropwizard.testing

import org.junit.Test

import static javax.ws.rs.core.Response.Status.*

class ExampleDropwizardIntegrationTest extends AbstractDropwizardIntegrationTest<ExampleConfiguration> {

	override protected getApplicationClass() {
		return ExampleApplication
	}

	@Test
	def void canAccessHelloWorldResource() {
		// given
		val request = createRequest('helloworld').buildGet

		// when
		val response = request.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
	}

}
