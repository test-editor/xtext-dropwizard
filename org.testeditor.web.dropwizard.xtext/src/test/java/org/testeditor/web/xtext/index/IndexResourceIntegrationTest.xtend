package org.testeditor.web.xtext.index

import java.io.File
import javax.ws.rs.client.Entity
import javax.ws.rs.client.Invocation
import org.eclipse.jgit.api.Git
import org.junit.Test
import org.testeditor.web.dropwizard.xtext.integration.AbstractExampleIntegrationTest

import static javax.ws.rs.core.Response.Status.*

class IndexResourceIntegrationTest extends AbstractExampleIntegrationTest {

	String firstCommitId
	String secondCommitId

	override protected initializeRemoteRepository(Git git, File parent) {
		firstCommitId = writeToRemote('src/main/java/Peter.mydsl', 'Hello Peter!').name()
		secondCommitId = writeToRemote('src/main/java/Heinz.mydsl', 'Hello Heinz!').name()
	}

	@Test
	def void indexRefreshUpdatesLocalRepository() {
		// given
		val lastCommit = writeToRemote('src/main/java/unrelated.txt', 'random content').name()

		// when
		val response = createRequest.submit.get

		// then
		response.status.assertEquals(NO_CONTENT.statusCode)
		val localRepo = Git.init.setDirectory(localRepoTemporaryFolder.root).call
		localRepo.lastCommit.name().assertEquals(lastCommit)
	}

	@Test
	def void indexRefreshUpdatesIndex() {
		// given
		createFancyCommitHistory
		val greeting = createFancyGreeting
		val indexRefreshRequest = createRequest
		val validateRequest = createValidationRequest('src/main/java/Another.mydsl', greeting)

		// when
		val indexRefreshResponse = indexRefreshRequest.submit.get
		val validationResponse = validateRequest.submit.get

		// then
		indexRefreshResponse.status.assertEquals(NO_CONTENT.statusCode)
		validationResponse.status.assertEquals(OK.statusCode)
		val expectedIssues = '''{"issues":[{"description":"Couldn't resolve reference to Greeting 'Heinz'.","severity":"error","line":3,"column":20,"offset":73,"length":5}]}'''
		validationResponse.readEntity(String).assertEquals(expectedIssues)
	}

	private def Invocation createRequest() {
		return createRequest('index/refresh').buildPost(Entity.json('{}'))
	}

	private def String createFancyCommitHistory() {
		writeToRemote('src/main/java/Rudolf.mydsl', 'Hello Rudolf!') // add
		writeToRemote('src/main/java/Peter.mydsl', 'Hello Peter2!') // modify
		return deleteOnRemote('src/main/java/Heinz.mydsl').name() // delete
	}

	private def String createFancyGreeting() '''
		Hello Example from Rudolf!
		Hello Example from Peter2!
		Hello Example from Heinz!
	'''

}
