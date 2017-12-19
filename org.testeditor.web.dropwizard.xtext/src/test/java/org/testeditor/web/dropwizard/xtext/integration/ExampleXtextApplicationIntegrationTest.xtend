package org.testeditor.web.dropwizard.xtext.integration

import java.io.File
import org.eclipse.jgit.api.Git
import org.junit.Test

import static javax.ws.rs.core.Response.Status.*

class ExampleXtextApplicationIntegrationTest extends AbstractExampleIntegrationTest {
   
	override protected initializeRemoteRepository(Git git, File parent) {
		write(parent, 'Demo.mydsl', 'Hello Peter!')
		addAndCommit(git, 'Demo.mydsl', 'Add MyDsl.xtext as an example')
	}

	@Test
	def void canValidateModelWithCrossReference() {
		// given
		val greeting = 'Hello Example from Peter!'
		val validateRequest = createValidationRequest('Another.mydsl', greeting)

		// when
		val response = validateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
	}
	
}
