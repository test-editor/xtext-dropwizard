package org.testeditor.web.xtext.index

import com.google.inject.Module
import com.google.inject.TypeLiteral
import java.io.File
import java.util.List
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.jgit.api.Git
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.XtextRuntimeModule
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.resource.persistence.SerializableEObjectDescription
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.testeditor.web.dropwizard.testing.files.FileTestUtils
import org.testeditor.web.dropwizard.testing.git.JGitTestUtils
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater
import org.testeditor.web.xtext.index.changes.IndexFilterModule
import org.testeditor.web.xtext.index.persistence.GitService

import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.*
import org.testeditor.web.xtext.index.changes.TestEditorChangeDetector

class BuildCycleManagerIntegrationTest extends AbstractTestWithExampleLanguage {

	protected extension val JGitTestUtils = new JGitTestUtils
	protected extension val FileTestUtils = new FileTestUtils

	@Inject extension BuildCycleManager unitUnderTest
	@Inject XtextResourceSet xtextResourceSet
	@Inject ValidationMarkerUpdater validationMarkerUpdater
	@Inject GitService gitService
	@Inject IResourceDescriptionsProvider indexProvider

	val initialIndexState = new IndexState

	@Rule public TemporaryFolder tmpDir = new TemporaryFolder

	static val remoteRoot = 'remote'
	static val localRoot = 'local'
	val XtextConfiguration config = new XtextConfiguration

	var BuildRequest sampleBuildRequest

	override protected collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules += [ binder |
			binder.install(new IndexFilterModule)
			binder.bind(ChangeDetector).to(TestEditorChangeDetector)
			binder.bind(XtextConfiguration).toInstance(config)
			binder.bind(new TypeLiteral<Iterable<ISetup>>() {
			}).toInstance(#[myDslSetup])
			binder.bind(ValidationMarkerUpdater).toInstance(mock(ValidationMarkerUpdater))
			binder.bind(IndexSearchPathProvider).toInstance[#[]]
		]
		modules += new XtextRuntimeModule
	}

	@Before
	def void setupMocks() {
		config => [
			remoteRepoUrl = 'file://' + tmpDir.newFolder(remoteRoot).absolutePath
			localRepoFileRoot = tmpDir.newFolder(localRoot).absolutePath
		]

		sampleBuildRequest = new BuildRequest => [
			baseDir = URI.createFileURI(config.localRepoFileRoot)
			resourceSet = xtextResourceSet
			afterValidate = validationMarkerUpdater
			dirtyFiles = #[URI.createFileURI(config.localRepoFileRoot + '/src/test/java/Demo.mydsl')]
			state = initialIndexState
		]
	}

	@Before
	def void initializeRemoteRepository() {
		val root = new File(tmpDir.root, remoteRoot)
		val remoteGit = Git.init.setDirectory(root).call
		write(root, 'build.gradle', '''apply plugin: 'java' ''')
		addAndCommit(remoteGit, 'build.gradle', 'Add build.gradle')
		write(root, 'gradlew', '''
			#!/bin/bash
			echo "running dummy gradle ..."
			if [ "$1" == "tasks" ]; then
			  echo "printTestClasspath"
			elif [ "$1" == "printTestClasspath" ]; then
			  echo "«root.absolutePath»/mydsl.jar"
			fi
		''')
		new File(root, 'gradlew').executable = true
		addAndCommit(remoteGit, 'gradlew', 'Add dummy gradlew')
		write(root, 'src/test/java/Demo.mydsl', 'Hello Peter!')
		addAndCommit(remoteGit, 'src/test/java/Demo.mydsl', 'Add MyDsl.xtext as an example')

		gitService.init(config.localRepoFileRoot, config.remoteRepoUrl)
	}

	@Test
	def void detectChangesReturnsModifiedFiles() {
		// given
		val initialBuildRequest = new BuildRequest

		// when
		val actualBuildRequest = initialBuildRequest.addChanges

		// then
		assertThat(actualBuildRequest.dirtyFiles).containsOnly(URI.createFileURI(config.localRepoFileRoot + '/src/test/java/Demo.mydsl'))
	}

	@Test
	def void createBuildRequestSetsRequiredFields() {
		// given
		unitUnderTest.init(URI.createFileURI(config.localRepoFileRoot))

		// when
		val actualBuildRequest = unitUnderTest.createBuildRequest

		// then
		assertThat(actualBuildRequest.baseDir).isEqualTo(URI.createFileURI(config.localRepoFileRoot))
		assertThat(actualBuildRequest.resourceSet).isInstanceOf(XtextResourceSet)
		assertThat(actualBuildRequest.afterValidate).isEqualTo(validationMarkerUpdater)
		assertThat(actualBuildRequest.state.getResourceDescriptions.exportedObjects).isEmpty
	}

	@Test
	def void createBuildRequestAlwaysUsesSameResourceSet() {
		// given
		val firstBuildRequest = unitUnderTest.createBuildRequest

		// when
		val secondBuildRequest = unitUnderTest.createBuildRequest

		// then
		assertThat(firstBuildRequest.resourceSet).isSameAs(secondBuildRequest.resourceSet)
	}

	@Test
	def void launchReturnsUpdatedIndexState() {
		// given
		val buildRequest = sampleBuildRequest

		// when
		val actualIndexState = unitUnderTest.build(buildRequest)

		// then
		assertThat(actualIndexState.resourceDescriptions.exportedObjects.head.qualifiedName.toString).isEqualTo('Peter')
	}

	@Test
	def void launchInvokesValidationMarkerUpdaterState() {
		// given
		val buildRequest = sampleBuildRequest

		// when
		unitUnderTest.build(buildRequest)

		// then
		verify(validationMarkerUpdater).afterValidate(any, any)
	}

	@Test
	def void updateIndexPublishesNewIndexState() {
		// given
		val exportedObjectNames = #['modelElement', 'anotherElement']
		val newIndexState = getMockedIndexState(exportedObjectNames)
		val baseURI = URI.createFileURI(config.localRepoFileRoot)
		unitUnderTest.init(baseURI)
		val indexResourceSet = unitUnderTest.createBuildRequest.resourceSet

		// when
		unitUnderTest.updateIndex(newIndexState)

		// then
		assertThat(indexProvider.getResourceDescriptions(indexResourceSet).exportedObjects.head.qualifiedName.toString).isEqualTo('modelElement')
	}

	private def getMockedIndexState(Iterable<String> eObjectNames) {
		val indexState = mock(IndexState)
		val resourceDescriptionsData = mock(ResourceDescriptionsData)
		when(resourceDescriptionsData.exportedObjects).thenReturn(
			eObjectNames.map [ eObjectName |
			val desc = new SerializableEObjectDescription()
			desc.qualifiedName = QualifiedName.create(eObjectName)
			return desc
		])
		when(indexState.resourceDescriptions).thenReturn(resourceDescriptionsData)
		return indexState
	}

}
