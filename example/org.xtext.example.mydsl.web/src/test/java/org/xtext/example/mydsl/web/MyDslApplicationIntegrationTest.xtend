package org.xtext.example.mydsl.web

import org.junit.Test

import static javax.ws.rs.core.Response.Status.*

class MyDslApplicationIntegrationTest extends AbstractMyDslApplicationIntegrationTest {

	@Test
	def void canAccessValidationService() {
		// given
		val example = '''
			Hello world!
		'''
		val validateRequest = createValidationRequest('Minimal.mydsl', example)

		// when
		val response = validateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
	}

}
