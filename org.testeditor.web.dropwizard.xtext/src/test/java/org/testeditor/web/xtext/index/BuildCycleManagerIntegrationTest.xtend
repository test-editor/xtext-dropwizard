package org.testeditor.web.xtext.index

import com.google.inject.Guice
import com.google.inject.Module
import com.google.inject.TypeLiteral
import com.google.inject.name.Names
import java.io.File
import java.io.FileOutputStream
import java.net.URLClassLoader
import java.nio.file.FileSystems
import java.nio.file.Files
import java.util.List
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.jgit.api.Git
import org.eclipse.xtend.core.XtendRuntimeModule
import org.eclipse.xtend.core.XtendStandaloneSetup
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.XtextRuntimeModule
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.builder.standalone.compiler.EclipseJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.resource.impl.SimpleResourceDescriptionsBasedContainerManager
import org.eclipse.xtext.resource.persistence.SerializableEObjectDescription
import org.eclipse.xtext.util.Modules2
import org.eclipse.xtext.web.server.DefaultWebModule
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.mockito.ArgumentCaptor
import org.testeditor.web.dropwizard.testing.files.FileTestUtils
import org.testeditor.web.dropwizard.testing.git.JGitTestUtils
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerMap
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater
import org.testeditor.web.dropwizard.xtext.validation.ValidationSummary
import org.testeditor.web.xtext.index.changes.ChangeFilter
import org.testeditor.web.xtext.index.changes.IndexFilter
import org.testeditor.web.xtext.index.changes.LanguageExtensionBasedIndexFilter
import org.testeditor.web.xtext.index.changes.TestEditorChangeDetector
import org.testeditor.web.xtext.index.persistence.GitService
import org.xtext.example.mydsl.MyDslRuntimeModule
import org.xtext.example.mydsl.MyDslStandaloneSetup
import org.xtext.example.mydsl.ide.MyDslIdeModule

import static com.google.common.base.Suppliers.memoize
import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.Mockito.*

class BuildCycleManagerIntegrationTest extends AbstractTestWithExampleLanguage {

	protected extension val JGitTestUtils = new JGitTestUtils
	protected extension val FileTestUtils = new FileTestUtils

	@Inject BuildCycleManager buildManagerUnderTest
	@Inject XtextResourceSet xtextResourceSet
	@Inject ValidationMarkerUpdater validationMarkerUpdater
	@Inject GitService gitService
	@Inject ChunkedResourceDescriptionsProvider indexProvider
	@Inject XtextIndexModule indexModule
	@Inject ValidationMarkerMap validationMarkers

	val initialIndexState = new IndexState

	@Rule public TemporaryFolder tmpDir = new TemporaryFolder

	static val remoteRoot = 'remote'
	static val localRoot = 'local'
	val XtextConfiguration config = new XtextConfiguration

	var BuildRequest sampleBuildRequest
	Git remoteGit

	override protected collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules += [ binder |
			binder.bind(IndexFilter).annotatedWith(Names.named(ChangeFilter.FILTER_CHANGES_FOR_INDEX)).to(LanguageExtensionBasedIndexFilter)
			binder.bind(ChangeDetector).to(TestEditorChangeDetector)
			binder.bind(XtextConfiguration).toInstance(config)
			binder.bind(new TypeLiteral<Iterable<ISetup>>() {}).toProvider[getLanguageSetups(indexModule)]
			binder.bind(ValidationMarkerMap).toInstance(spy(ValidationMarkerMap))
			binder.bind(IndexSearchPathProvider).toInstance[#[]]
			binder.bind(AbstractFileSystemAccess).to(JavaIoFileSystemAccess)
			binder.bind(IJavaCompiler).to(EclipseJavaCompiler)
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
		remoteGit = Git.init.setDirectory(root).call
		write(root, 'build.gradle', '''
			apply plugin: 'java' 
			
			repositories {
			   flatDir {
			       dirs 'libs'
			   }
			}
			
			dependencies {
			   compile name: 'mydsl'
			}
			''')
		remoteGit.addAndCommit('build.gradle', 'Add build.gradle')
		write(root, 'gradlew', '''
			#!/bin/bash
			echo "running dummy gradle ..."
			if [ "$1" == "tasks" ]; then
			  echo "printTestClasspath"
			elif [ "$1" == "printTestClasspath" ]; then
			  echo "«new File(tmpDir.root, localRoot).absolutePath»/mydsl.jar"
			fi
		''')
		new File(root, 'gradlew').executable = true
		remoteGit.addAndCommit('gradlew', 'Add dummy gradlew')
		write(root, 'src/test/java/Demo.mydsl', 'Hello Peter!')
		remoteGit.addAndCommit('src/test/java/Demo.mydsl', 'Add MyDsl.xtext as an example')
		
		new File(root, 'libs').mkdir
		writeJarFile(root, 'libs/mydsl.jar')
		remoteGit.addAndCommit('libs/mydsl.jar', 'Add sample jar file')

		gitService.init(config.localRepoFileRoot, config.remoteRepoUrl)
	}

	@Test
	def void detectChangesReturnsIndexRelevantModifiedFiles() {
		// given
		val initialBuildRequest = new BuildRequest

		// when
		val actualBuildRequest = buildManagerUnderTest.addChanges(initialBuildRequest)

		// then
		assertThat(actualBuildRequest.dirtyFiles).containsOnly(URI.createFileURI(config.localRepoFileRoot + '/src/test/java/Demo.mydsl'))
	}

	@Test
	def void createBuildRequestSetsRequiredFields() {
		// when
		val actualBuildRequest = buildManagerUnderTest.createBuildRequest

		// then
		assertThat(actualBuildRequest.baseDir).isEqualTo(URI.createFileURI(config.localRepoFileRoot))
		assertThat(actualBuildRequest.resourceSet).isInstanceOf(XtextResourceSet)
		assertThat(actualBuildRequest.afterValidate).isEqualTo(validationMarkerUpdater)
		assertThat(actualBuildRequest.state.getResourceDescriptions.exportedObjects).isEmpty
	}

	@Test
	def void createBuildRequestAlwaysUsesSameResourceSet() {
		// given
		val firstBuildRequest = buildManagerUnderTest.createBuildRequest

		// when
		val secondBuildRequest = buildManagerUnderTest.createBuildRequest

		// then
		assertThat(firstBuildRequest.resourceSet).isSameAs(secondBuildRequest.resourceSet)
	}

	@Test
	def void launchReturnsUpdatedIndexState() {
		// given
		val buildRequest = sampleBuildRequest

		// when
		val actualIndexState = buildManagerUnderTest.build(buildRequest).indexState

		// then
		assertThat(actualIndexState.resourceDescriptions.exportedObjects.head.qualifiedName.toString).isEqualTo('Peter')
	}

	@Test
	def void updateIndexPublishesNewIndexState() {
		// given
		val exportedObjectNames = #['modelElement', 'anotherElement']
		val newIndexState = getMockedIndexState(exportedObjectNames)
		val indexResourceSet = buildManagerUnderTest.createBuildRequest.resourceSet

		// when
		buildManagerUnderTest.updateIndex(newIndexState)

		// then
		assertThat(indexProvider.getResourceDescriptions(indexResourceSet).exportedObjects.map[qualifiedName.toString]).containsOnly('modelElement',
			'anotherElement')
	}

	@Test
	def void buildSetsCorrectClasspathURIContext() {
		// when
		buildManagerUnderTest.startBuild

		// then
		val classLoader = indexProvider.indexResourceSet.classpathURIContext as URLClassLoader
		assertThat(classLoader.URLs.map[path]).containsOnly(#[
			'''«tmpDir.root.absolutePath»/«localRoot»/mydsl.jar''', /* jars collected by Gradle */
			'''«tmpDir.root.absolutePath»/«localRoot»/build/classes/java/main''', /* path(s) provided via Dropwizard config */
			'''«tmpDir.root.absolutePath»/«localRoot»/build'''] /* Gradle default output of 'assemble' task */)
	}
	
	@Test
	def void startBuildUpdatesValidationMarkers() {
		// given
		val actualValidationSummaries = ArgumentCaptor.forClass(Iterable)
		
		// when
		buildManagerUnderTest.startBuild

		// then
		verify(validationMarkers).updateMarkers(actualValidationSummaries.capture)
		assertThat(actualValidationSummaries.value).containsOnly(ValidationSummary.noMarkers('src/test/java/Demo.mydsl'))
	}
	
	@Test
	def void startBuildUpdatesIndex() {
		// given
		// when
		buildManagerUnderTest.startBuild

		// then
		val index = indexProvider.getResourceDescriptions(indexProvider.indexResourceSet)
		assertThat(index.exportedObjects.map[qualifiedName.toString]).containsOnly('Peter')

	}
	
	@Test
	def void startBuildRecompilesModifiedJavaFiles() {
		// given
		val root = new File(tmpDir.root, remoteRoot)
		val javaFilePath = 'src/main/java/SampleClass.java'
		write(root, javaFilePath, 'public class SampleClass {}')
		remoteGit.addAndCommit(javaFilePath, 'Add sample Java file')
		
		val gradleWrapperFile = new File(root, 'gradlew')
		gradleWrapperFile.delete
		new ProcessBuilder('gradle', 'wrapper').directory(root).start.waitFor
		remoteGit.add.addFilepattern('gradle').call
		remoteGit.addAndCommit('gradlew', 'replace dummy with real gradle wrapper')
		
		buildManagerUnderTest.startBuild
		
		// when
		write(root, javaFilePath, 'public class SampleClass implements Cloneable {}')
		remoteGit.addAndCommit(javaFilePath, 'Modify Java file')
		buildManagerUnderTest.startBuild

		// then
		val classLoader = indexProvider.indexResourceSet.classpathURIContext as URLClassLoader
		assertThat(classLoader.loadClass('SampleClass').interfaces).contains(Cloneable)
	}
	
	private def writeJarFile(File root, String jarName) {
		val jarFilename = root.absolutePath + '/' + jarName

		new JarOutputStream(new FileOutputStream(jarFilename)) => [
			add('peter.mydsl', '''Hello Peter'''.toString.bytes)
			add('test.xtend', '''class Test { }'''.toString.bytes)
			add('jxtest.java', '''class jxtest { }'''.toString.bytes)
			add('jtest.class', Files.readAllBytes(FileSystems.getDefault.getPath('src/test/resources/jtest.class')))
			close
		]
		
		return jarFilename
	}
 
 	private def void add(JarOutputStream jarOutputStream, String fileName, byte[] content) {
		val jarEntry = new JarEntry(fileName)
		jarOutputStream.putNextEntry(jarEntry)
		jarOutputStream.write(content)
		jarOutputStream.closeEntry
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

	private def Iterable<ISetup> getLanguageSetups(XtextIndexModule indexModule) {
		return memoize[
			#[new MyDslStandaloneSetup {

				override createInjector() {
					val module = Modules2.mixin(new MyDslRuntimeModule, new MyDslIdeModule, new DefaultWebModule, indexModule)
					return Guice.createInjector(module)
				}

			}, new XtendStandaloneSetup {

				override createInjector() {
					val module = Modules2.mixin(new XtendRuntimeModule, new DefaultWebModule, indexModule)
					return Guice.createInjector(module)
				}

			}]
		].get
	}

}
