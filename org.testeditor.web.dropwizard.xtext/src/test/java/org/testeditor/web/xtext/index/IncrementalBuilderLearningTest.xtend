package org.testeditor.web.xtext.index

import javax.inject.Inject
import org.apache.commons.io.FileUtils
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

import static org.assertj.core.api.Assertions.assertThat

import static extension org.eclipse.emf.common.util.URI.createFileURI

class IncrementalBuilderLearningTest extends AbstractTestWithExampleLanguage {

	@Inject IncrementalBuilder builder
	@Inject extension IResourceServiceProvider.Registry languageRegistry
	@Inject XtextResourceSet resourceSet
	@Rule public TemporaryFolder tmpFolder = new TemporaryFolder

	@Test
	def void canBeInstantiated() {
		assertThat(builder).isNotNull
	}

	@Test
	def void canHandleEmptyBuildRequest() {
		// given
		val buildRequest = new BuildRequest() => [
			it.resourceSet = resourceSet
		]

		// when
		val actualResult = builder.build(buildRequest, [getResourceServiceProvider])

		// then
		assertThat(actualResult).isNotNull
	}

	@Test
	def void canBuildSimpleRequest() {
		// given
		val testFile = tmpFolder.newFile('test.mydsl')
		FileUtils.write(testFile, 'Hello World!', 'UTF-8')
		val resource = resourceSet.getResource(testFile.absolutePath.createFileURI, true)
		val buildRequest = new BuildRequest() => [
			it.resourceSet = resourceSet
			it.dirtyFiles = #[resource.URI]
		]

		// when
		val actualResult = builder.build(buildRequest, [getResourceServiceProvider])

		// then
		assertThat(actualResult).isNotNull
		assertThat(actualResult.indexState.resourceDescriptions.exportedObjects.map[qualifiedName.toString]).containsOnly('World')
	}

	@Test
	def void indexesNewResource() {
		// given
		val testFile = tmpFolder.newFile('test.mydsl')
		FileUtils.write(testFile, 'Hello World!', 'UTF-8')
		val initialResource = resourceSet.getResource(testFile.absolutePath.createFileURI, true)
		val initialRequest = new BuildRequest() => [
			it.resourceSet = resourceSet
			it.dirtyFiles = #[initialResource.URI]
		]
		val initialResult = builder.build(initialRequest, [getResourceServiceProvider])
		assertThat(initialResult.indexState.resourceDescriptions.exportedObjects.map[qualifiedName.toString]).containsOnly('World')

		val newFile = tmpFolder.newFile('test2.mydsl')
		FileUtils.write(newFile, 'Hello AddedFile!', 'UTF-8')
		val newResource = resourceSet.getResource(newFile.absolutePath.createFileURI, true)
		val newRequest = new BuildRequest() => [
			it.resourceSet = resourceSet
			it.state = initialResult.indexState
			it.dirtyFiles = #[newResource.URI]
		]

		// when
		val actualResult = builder.build(newRequest, [getResourceServiceProvider])

		// then
		assertThat(actualResult).isNotNull
		assertThat(actualResult.indexState.resourceDescriptions.exportedObjects.map[qualifiedName.toString])
			.containsOnly('World', 'AddedFile')
	}

}
