package org.testeditor.web.xtext.index.changes

import com.google.common.io.CharStreams
import com.google.inject.Inject
import com.google.inject.Provider
import java.io.File
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.concurrent.TimeUnit
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.common.types.access.impl.IndexedJvmTypeAccess
import org.slf4j.LoggerFactory
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.testeditor.web.xtext.index.buildutils.XtextBuilderUtils

import static com.google.common.base.Suppliers.memoize

import static extension com.google.common.collect.Sets.difference

/**
 * Invokes a Gradle build job, if a previous change detector in the chain
 * reported the 'build.gradle' file to have changed. 
 */
@Singleton
class GradleBuildChangeDetector implements ChangeDetector {

	static val BUILD_GRADLE_FILE_NAME = 'build.gradle'
	static val GRADLE_PROCESS_TIMEOUT_MINUTES = 10
	static val logger = LoggerFactory.getLogger(GradleBuildChangeDetector)

	public static val String SUCCESSOR_NAME = 'GradleBuildChangeDetectorSuccessor'

	@Inject extension XtextBuilderUtils builderUtils
	
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject IndexedJvmTypeAccess jvmTypeAccess
	@Inject LanguageAccessRegistry languages
	@Inject Provider<XtextConfiguration> config

	var buildScriptPath = memoize[new File(projectRoot.get, BUILD_GRADLE_FILE_NAME).absolutePath]
	var projectRoot = memoize[new File(config.get.localRepoFileRoot)]
	var lastDetectedResources = <URI>emptySet

	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		if (accumulatedChanges.modifiedResources.exists[buildScriptPath.get.equals(path)]) {
			runGradleAssemble(projectRoot.get)
			prepareGradleTask(projectRoot.get)
			val jarFiles = collectClasspathJarsViaGradle(projectRoot.get)
			val detectedResources = jarFiles.collectResources(resourceSet, languages.extensions)
			accumulatedChanges => [
				// conservatively assume that all resources found have also been modified.
				// There may be room for optimization here, e.g. checking whether underlying 
				// jars have actually been modified (last modified meta-data of file)
				modifiedResources += detectedResources
				deletedResources += lastDetectedResources.difference(detectedResources.toSet)
				classPath += jarFiles
				resourceDescriptionsProvider.indexResourceSet.installTypeProvider(classPath, jvmTypeAccess)
			]
			lastDetectedResources = detectedResources
		}
		
		return accumulatedChanges
	}

	/** make sure the task 'printTestClasspath' exists */
	private def void prepareGradleTask(File repoRoot) {
		val process = new ProcessBuilder('./gradlew', 'tasks', '--all').directory(repoRoot).start
		logger.info('running gradle tasks.')
		process.waitFor(GRADLE_PROCESS_TIMEOUT_MINUTES, TimeUnit.MINUTES) // allow for downloads and the like
		val completeOutput = CharStreams.readLines(new InputStreamReader(process.inputStream, StandardCharsets.UTF_8))
		logger.info(completeOutput.join('\n'))
		val hasPrintTestClasspathTask = completeOutput.exists['printTestClasspath'.equals(it)]
		if (!hasPrintTestClasspathTask) {
			logger.info('Adding standard gradle job to print test classpath.')
			Files.write(Paths.get(repoRoot.absolutePath).resolve('build.gradle'), '''
				task printTestClasspath {
					doLast {
						configurations.testRuntime.each { println it }
					}
				}
			'''.toString.bytes, StandardOpenOption.APPEND)
		}
	}

	/** execute task 'assemble' and wait until done */
	private def void runGradleAssemble(File repoRoot) {
		val process = new ProcessBuilder('./gradlew', 'assemble').directory(repoRoot).inheritIO.start
		logger.info('running gradle assemble.')
		process.waitFor(GRADLE_PROCESS_TIMEOUT_MINUTES, TimeUnit.MINUTES) // allow for downloads and the like
	}

	private def Iterable<String> collectClasspathJarsViaGradle(File repoRoot) {
		val process = new ProcessBuilder('./gradlew', 'printTestClasspath').directory(repoRoot).start
		logger.info('running gradle printTestClasspath.')
		process.waitFor(GRADLE_PROCESS_TIMEOUT_MINUTES, TimeUnit.MINUTES) // allow for downloads and the like
		val jars = CharStreams.readLines(new InputStreamReader(process.inputStream, StandardCharsets.UTF_8)).filter[startsWith('/')].filter [
			endsWith('.jar')
		]
		logger.info('found the following classpath entries:\n' + jars.join('\n'))
		return jars
	}

}
