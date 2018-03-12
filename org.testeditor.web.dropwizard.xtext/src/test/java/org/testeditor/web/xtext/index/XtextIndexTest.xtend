package org.testeditor.web.xtext.index

import com.google.inject.Module
import java.io.FileOutputStream
import java.nio.file.FileSystems
import java.nio.file.Files
import java.util.List
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import javax.inject.Inject
import org.eclipse.xtend.core.XtendStandaloneSetup
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.XtextRuntimeModule
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.builder.standalone.ILanguageConfiguration
import org.eclipse.xtext.builder.standalone.LanguageAccessFactory
import org.eclipse.xtext.builder.standalone.compiler.EclipseJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.xbase.testing.RegisteringFileSystemAccess
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater
import org.testeditor.web.xtext.index.buildutils.XtextBuilderUtils
import org.xtext.example.mydsl.MyDslStandaloneSetup

import static org.assertj.core.api.Assertions.*

import static extension org.eclipse.emf.common.util.URI.createFileURI

class XtextIndexTest extends AbstractTestWithExampleLanguage {

	@Rule public val TemporaryFolder tmpFolder = new TemporaryFolder

	@Inject IncrementalBuilder builder
	@Inject LanguageAccessFactory languageAccessFactory
	@Inject OutputConfigurationProvider configurationProvider
	@Inject XtextResourceSet indexResourceSet
	@Inject extension XtextBuilderUtils builderUtils

	@Test
	def void addingJarsToIndexAddsAllRelevantContents() {
		// given
		val jarFilename = tmpFolder.root.absolutePath + '/mydsl.jar'

		new JarOutputStream(new FileOutputStream(jarFilename)) => [
			add('peter.mydsl', '''Hello Peter'''.toString.bytes)
			add('test.xtend', '''class Test { }'''.toString.bytes)
			add('jxtest.java', '''class jxtest { }'''.toString.bytes)
			add('jtest.class', Files.readAllBytes(FileSystems.getDefault.getPath('src/test/resources/jtest.class')))
			close
		]

		val languages = languageAccessFactory.createLanguageAccess(#[
			createLanguageConfiguration(MyDslStandaloneSetup),
			createLanguageConfiguration(XtendStandaloneSetup)
		], class.classLoader)

		indexResourceSet.installTypeProvider(#[jarFilename])

		val initRequest = new BuildRequest => [
			baseDir = tmpFolder.root.absolutePath.createFileURI
			resourceSet = indexResourceSet
			dirtyFiles = collectResources(#[jarFilename], indexResourceSet, languages.keySet).toList
		]

		// when
		val result = builder.build(initRequest, [languages.get(fileExtension).resourceServiceProvider])

		// then
		result.indexState.resourceDescriptions.exportedObjects.map[qualifiedName.toString].toSet => [
			assertThat(it).containsOnly('Peter', 'Test') // java artifact (jxtest) is NOT indexed
		]
		// classloader of this resource set resolve classes from jar (hopefully this will mean, that java references will be resolved for dsl resources)
		val clazz = (indexResourceSet.classpathURIContext as ClassLoader).loadClass('jtest')
		assertThat(clazz.name).isEqualTo('jtest')
	}

	private def void add(JarOutputStream jarOutputStream, String fileName, byte[] content) {
		val jarEntry = new JarEntry(fileName)
		jarOutputStream.putNextEntry(jarEntry)
		jarOutputStream.write(content)
		jarOutputStream.closeEntry
	}

	override def void collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules.add(new XtextRuntimeModule)
		modules += [ binder |
			binder.bind(AbstractFileSystemAccess).to(RegisteringFileSystemAccess).asEagerSingleton
			binder.bind(IJavaCompiler).to(EclipseJavaCompiler)
			binder.bind(IIssueHandler).to(ValidationMarkerUpdater)
		]

	}

	private def ILanguageConfiguration createLanguageConfiguration(Class<? extends ISetup> setupClass) {
		return new ILanguageConfiguration() {

			override getOutputConfigurations() {
				return configurationProvider.getOutputConfigurations()
			}

			override getSetup() {
				return setupClass.name
			}

			override isJavaSupport() {
				return true
			}

		}
	}

}
