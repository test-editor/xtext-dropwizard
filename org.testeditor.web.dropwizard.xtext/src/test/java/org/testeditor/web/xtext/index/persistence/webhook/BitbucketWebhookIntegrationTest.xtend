package org.testeditor.web.xtext.index.persistence.webhook

import java.io.File
import javax.ws.rs.client.Entity
import javax.ws.rs.client.Invocation
import org.eclipse.jgit.api.Git
import org.junit.Test
import org.testeditor.web.dropwizard.xtext.integration.AbstractExampleIntegrationTest

import static javax.ws.rs.core.Response.Status.*

class BitbucketWebhookIntegrationTest extends AbstractExampleIntegrationTest {

	String firstCommitId
	String secondCommitId

	override protected initializeRemoteRepository(Git git, File parent) {
		firstCommitId = writeToRemote('Peter.mydsl', 'Hello Peter!').name()
		secondCommitId = writeToRemote('Heinz.mydsl', 'Hello Heinz!').name()
	}

	@Test
	def void webhookUpdatesLocalRepository() {
		// given
		val lastCommit = writeToRemote('unrelated.txt', 'random content').name()

		// when
		val response = createRequest.submit.get

		// then
		response.status.assertEquals(NO_CONTENT.statusCode)
		val localRepo = Git.init.setDirectory(localRepoTemporaryFolder.root).call
		localRepo.lastCommit.name().assertEquals(lastCommit)
	}

	@Test
	def void webhookUpdatesIndex() {
		// given
		createFancyCommitHistory
		val greeting = createFancyGreeting
		val webhookRequest = createRequest
		val validateRequest = createValidationRequest('Another.mydsl', greeting)

		// when
		val webhookResponse = webhookRequest.submit.get
		val validationResponse = validateRequest.submit.get

		// then
		webhookResponse.status.assertEquals(NO_CONTENT.statusCode)
		validationResponse.status.assertEquals(OK.statusCode)
		val expectedIssues = '''{"issues":[{"description":"Couldn't resolve reference to Greeting 'Heinz'.","severity":"error","line":3,"column":20,"offset":73,"length":5}]}'''
		validationResponse.readEntity(String).assertEquals(expectedIssues)
	}

	private def Invocation createRequest() {
		return createRequestWithApiToken('webhook/git', apiToken).buildPost(Entity.json('{}'))
	}

	private def String createFancyCommitHistory() {
		writeToRemote('Rudolf.mydsl', 'Hello Rudolf!') // add
		writeToRemote('Peter.mydsl', 'Hello Peter2!') // modify
		return deleteOnRemote('Heinz.mydsl').name() // delete
	}

	private def String createFancyGreeting() '''
		Hello Example from Rudolf!
		Hello Example from Peter2!
		Hello Example from Heinz!
	'''

}
