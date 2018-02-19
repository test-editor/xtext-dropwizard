package org.testeditor.web.dropwizard.xtext.integration

import java.io.File
import org.eclipse.jgit.api.Git
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.resource.EObjectDescription
import org.junit.Test
import org.xtext.example.mydsl.myDsl.impl.MyDslFactoryImpl

import static javax.ws.rs.core.Response.Status.*

class ExampleXtextApplicationIntegrationTest extends AbstractExampleIntegrationTest {
   
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

}
