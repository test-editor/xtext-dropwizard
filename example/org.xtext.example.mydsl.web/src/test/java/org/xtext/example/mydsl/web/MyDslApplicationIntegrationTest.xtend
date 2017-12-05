package org.xtext.example.mydsl.web

import javax.ws.rs.client.Entity
import javax.ws.rs.client.Invocation
import javax.ws.rs.core.Form
import org.junit.Test
import org.testeditor.web.dropwizard.testing.AbstractDropwizardIntegrationTest

import static javax.ws.rs.core.Response.Status.*

class MyDslApplicationIntegrationTest extends AbstractDropwizardIntegrationTest<MyDslConfiguration> {

	override protected getApplicationClass() {
		return MyDslApplication
	}

	@Test
	def void canAccessValidationService() {
		// given
		val example = '''
			Hello world!
		'''
		val url = 'xtext-service/validate?resource=Minimal.mydsl'
		val validateRequest = createPostWithFullText(url, example)

		// when
		val response = validateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
	}

	private def Invocation createPostWithFullText(String url, String fullText) {
		val form = new Form('fullText', fullText)
		return createRequest(url).buildPost(Entity.form(form))
	}

}
