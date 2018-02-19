package org.testeditor.web.xtext.index.persistence

import com.google.common.io.CharStreams
import java.io.File
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import org.testeditor.web.xtext.index.CustomStandaloneBuilder
import javax.inject.Singleton
import org.slf4j.LoggerFactory

@Singleton
class GradleProjectIndexUpdater extends IndexUpdater {
	
	static val GRADLE_PROCESS_TIMEOUT_MINUTES = 10

	static val logger = LoggerFactory.getLogger(GradleProjectIndexUpdater)

	@Inject CustomStandaloneBuilder builder	

	override def void initIndex(File projectRoot) {
		builder.languages = languageAccessors
		if (new File(projectRoot.absolutePath, 'build.gradle').exists) {
			runGradleAssemble(projectRoot)
			prepareGradleTask(projectRoot)
			val jars = collectClasspathJarsViaGradle(projectRoot)
			builder => [
				baseDir = projectRoot.absolutePath
				sourceDirs = #[baseDir + "/src/main/java", baseDir + '/src/test/java']
				classPathEntries = jars + #[baseDir + '/build/classes/java/main']
			]
			builder.launch // does all the indexing ...
		} else {
			super.initIndex(projectRoot)
		}
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
		val jars = CharStreams.readLines(new InputStreamReader(process.inputStream, StandardCharsets.UTF_8)).filter[startsWith('/')].filter[endsWith('.jar')]
		logger.info('found the following classpath entries:\n' + jars.join('\n'))
		return jars
	}

}
