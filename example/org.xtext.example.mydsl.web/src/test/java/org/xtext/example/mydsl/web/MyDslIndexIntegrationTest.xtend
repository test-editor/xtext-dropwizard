package org.xtext.example.mydsl.web

import org.junit.Test
import static javax.ws.rs.core.Response.Status.*
import org.eclipse.jgit.api.Git
import java.io.File

class MyDslIndexIntegrationTest extends AbstractMyDslApplicationIntegrationTest {

	override protected initializeRemoteRepository(Git git, File parent) {
		super.initializeRemoteRepository(git, parent)
		writeToRemote('src/test/java/ChuckNorris.mydsl', 'Hello ChuckNorris!')
		writeToRemote('src/test/java/fully/qualified/JavaClass.java', '''
			package fully.qualified
			
			public class JavaClass {}
		''')
	}

	@Test
	def void canLinkAgainstIndex() {
		// given
		val example = '''
			Hello world from ChuckNorris!
		'''
		val validateRequest = createValidationRequest('src/test/java/Minimal.mydsl', example)

		// when
		val response = validateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
	}

	@Test
	def void canLinkAgainstJvmTypes() {
		// given
		val example = '''
			Hello world! Resolve fully.qualified.JavaClass
		'''
		val validateRequest = createValidationRequest('src/test/java/Minimal.mydsl', example)

		// when
		val response = validateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
	}

}
