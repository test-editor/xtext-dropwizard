package org.testeditor.web.dropwizard.xtext.integration

import java.io.File
import org.eclipse.jgit.api.Git
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.resource.EObjectDescription
import org.junit.Before
import org.junit.Test
import org.xtext.example.mydsl.myDsl.impl.MyDslFactoryImpl

import static javax.ws.rs.core.Response.Status.*

class ExampleXtextApplicationIntegrationTest extends AbstractExampleIntegrationTest {

	static val fileWithError = 'src/test/java/Broken.mydsl'

	val gradleAssembleCalledFileName = 'gradle.assemble.called.txt'

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
			elif [ "$1" == "assemble" ]; then
			  echo "Gradle 'assemble' called (would build classes anew)"
			  touch «gradleAssembleCalledFileName»
			fi
		''')
		new File(parent, 'gradlew').executable = true
		addAndCommit(git, 'gradlew', 'Add dummy gradlew')
		write(parent, 'src/test/java/Demo.mydsl', 'Hello Peter!')
		addAndCommit(git, 'src/test/java/Demo.mydsl', 'Add MyDsl.xtext as an example')
		
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(git, fileWithError, 'add file with syntax error')
	}

	@Before
	def void cleanupTouchedFiles() {
		new File(localRepoTemporaryFolder.root, gradleAssembleCalledFileName).delete
	}

	@Test
	def void runFullBuildUponRequest() {
		// given (the index is populated)
		 
		// when
		write(remoteRepoTemporaryFolder.root, 'src/test/java/Unknown.mydsl', 'Hello Unknown!')
		addAndCommit(remoteGit, 'src/test/java/Unknown.mydsl', 'added unknown')
		createIndexRefreshRequest.submit.get

		// then
		val validateRequest = createValidationRequest('Another.mydsl', 'Hello Another from Unknown!')
		val response = validateRequest.submit.get
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('{"issues":[]}')
		new File(localRepoTemporaryFolder.root, gradleAssembleCalledFileName).exists.assertTrue
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
		val parent = remoteRepoTemporaryFolder.root;
		val fileWithError = 'src/test/java/Broken.mydsl'
		write(parent, fileWithError, 'Helo Typo!')
		addAndCommit(remoteGit, fileWithError, 'add file with syntax error')
		
		// when
		val response = createValidationMarkerUpdateRequest.submit.get

		// then
		response.status.assertEquals(OK.statusCode)
		response.readEntity(String).assertEquals('[{"path":"src/test/java/Broken.mydsl","errors":1,"warnings":0,"infos":0}]')
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
	}

	@Test
	def void carriesLastAccessedHeaderField() {
		// given
		val testStartTime = System.currentTimeMillis
		
		// when
		val response = createValidationMarkerUpdateRequest.submit.get

		// then
		response.headers.containsKey('lastAccessed').assertTrue
		assertTrue(Long.parseLong(response.headers.getFirst('lastAccessed') as String) >= testStartTime)
	}

}
