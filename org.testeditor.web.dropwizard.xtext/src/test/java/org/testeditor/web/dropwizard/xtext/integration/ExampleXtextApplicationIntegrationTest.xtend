package org.testeditor.web.dropwizard.xtext.integration

import java.io.File
import org.eclipse.jgit.api.Git
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.resource.EObjectDescription
import org.junit.Test
import org.xtext.example.mydsl.myDsl.impl.MyDslFactoryImpl

import static javax.ws.rs.core.Response.Status.*

class ExampleXtextApplicationIntegrationTest extends AbstractExampleIntegrationTest {
   
   static val fileWithError = 'src/test/java/Broken.mydsl'
   
	override protected initializeRemoteRepository(Git git, File parent) {
		write(parent, 'build.gradle', '''apply plugin: 'java' ''')
		addAndCommit(git, 'build.gradle', 'Add build.gradle')
		write(parent, 'gradlew', '''
			#!/bin/bash
			echo "running dummy gradle ..."
			if [ "$1" == "tasks" ]; then
			  echo "printTestClasspath"
			elif [ "$1" == "printTestClasspath" ]; then
			  echo "«parent.absolutePath»/mydsl.jar"
			fi
		''')
		new File(parent, 'gradlew').executable = true
		addAndCommit(git, 'gradlew', 'Add dummy gradlew')
		write(parent, 'src/test/java/Demo.mydsl', 'Hello Peter!')
		addAndCommit(git, 'src/test/java/Demo.mydsl', 'Add MyDsl.xtext as an example')
		
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(git, fileWithError, 'add file with syntax error')
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
	
	@Test
	// tests whether jackson is configured properly `objectMapper.enable(MapperFeature.PROPAGATE_TRANSIENT_MARKER)`
	// otherwise serialization fails (see https://stackoverflow.com/a/38956032/1839228)
	def void serializingContentAssistEntryWorksEvenIfEObjectIsPresent() {
		// given
		val contentAssistEntry = new ContentAssistEntry => [
			description = 'MyFancyDescription'
			source = EObjectDescription.create('some', new MyDslFactoryImpl().createGreeting)
		]

		// when
		val asJson = dropwizardAppRule.environment.objectMapper.writeValueAsString(contentAssistEntry)

		// then
		asJson.contains('"description":"MyFancyDescription"').assertTrue
		asJson.contains('"source":').assertFalse
	}
	
	
	@Test
	def void canRetrieveValidationMarkers() {
		// given
		val parent = remoteRepoTemporaryFolder.root;
		val fileWithError = 'src/test/java/Broken.mydsl'
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(remoteGit, fileWithError, 'add file with syntax error')
		
		// when
		val response = createValidationMarkerRequest(fileWithError).submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('[{"path":"src/test/java/Broken.mydsl","errors":1,"warnings":0,"infos":0}]')
	}
	
	@Test
	def void providesAllValidationMarkersOnUpdate() {
		// given
		val testStartTime = System.currentTimeMillis
		val parent = remoteRepoTemporaryFolder.root;
		val fileWithError = 'src/test/java/Broken.mydsl'
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(remoteGit, fileWithError, 'add file with syntax error')
		
		// when
		val response = createValidationMarkerUpdateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('[{"path":"src/test/java/Broken.mydsl","errors":1,"warnings":0,"infos":0}]')
		response.headers.containsKey('lastAccessed').assertTrue
		assertTrue(Long.parseLong(response.headers.getFirst('lastAccessed') as String) >= testStartTime)
	}
	
	@Test
	def void returnsEmptyResponseIfStillUpToDate() {
		// given
		val testStartTime = System.currentTimeMillis
		val parent = remoteRepoTemporaryFolder.root;
		val fileWithError = 'src/test/java/Broken.mydsl'
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(remoteGit, fileWithError, 'add file with syntax error')
		
		// when
		val response = createValidationMarkerUpdateRequest(testStartTime).submit.get

		// then
		response.status.assertEquals(NO_CONTENT.statusCode)
		response.headers.containsKey('lastAccessed').assertTrue
		assertTrue(Long.parseLong(response.headers.getFirst('lastAccessed') as String) >= testStartTime)
	}
	/**
	 * 	@Test
	def void testThatSuccessStatusIsReturned() {
		// given
		val testFile = 'test.tcl'
		workspaceRoot.newFolder(userId)
		workspaceRoot.newFile(userId + '/' + testFile)
		workspaceRoot.newFile(userId + '/gradlew') => [
			executable = true
			JGitTestUtil.write(it, '''
				#!/bin/sh
				echo "test was run" > test.ok.txt
			''')
		]
		val executionResponse = createTestExecutionRequest(testFile).post(null)
		assertThat(executionResponse.status).isEqualTo(Status.CREATED.statusCode)

		// when
		val actualTestStatus = createAsyncTestStatusRequest(testFile).get

		// then
		assertThat(actualTestStatus.readEntity(String)).isEqualTo('SUCCESS')

	}
	 */

}
