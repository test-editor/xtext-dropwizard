package org.testeditor.web.xtext.index.persistence

import com.google.common.annotations.VisibleForTesting
import com.google.common.io.CharStreams
import java.io.File
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.List
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.Constants
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.ILanguageConfiguration
import org.eclipse.xtext.builder.standalone.LanguageAccessFactory
import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.CustomStandaloneBuilder
import org.testeditor.web.xtext.index.XtextIndex

class IndexUpdater {

	static val logger = LoggerFactory.getLogger(IndexUpdater)

	@Inject XtextIndex index
	@Inject CustomStandaloneBuilder builder
	@Inject LanguageAccessFactory languageAccessFactory
	@Inject OutputConfigurationProvider configurationProvider

	var List<ISetup> languageSetups

	/**
	 * Recursively traverses the file tree and adds all files to the
	 * index that are relevant (with registered language extensions).
	 */
	def void addToIndex(File file) {
		if (file.isDirectory && !shouldSkipDirectory(file)) {
			file.listFiles.forEach[addToIndex]
		} else if (file.isFile && isRelevantForIndex(file.path)) {
			val uri = getAbsoluteFileURI(file)
			index.updateOrAdd(uri)
		}
	}

	private def void prepareGradleTask(File repoRoot) {
		val process = new ProcessBuilder('./gradlew', 'tasks', '--all').directory(repoRoot).start
		process.waitFor(10, TimeUnit.MINUTES) // allow for downloads and the like
		val jars = CharStreams.readLines(new InputStreamReader(process.inputStream, StandardCharsets.UTF_8)).filter['printTestClasspath'.equals(it)]
		if (jars.empty) {
			Files.write(Paths.get(repoRoot.absolutePath).resolve('build.gradle'), '''
				task printTestClasspath {
								doLast {
												configurations.testRuntime.each { println it }
					}
				}
			'''.toString.bytes, StandardOpenOption.APPEND)
		}
	}

	private def Iterable<String> collectClasspathJarsViaGradle(File repoRoot) {
		val process = new ProcessBuilder('./gradlew', 'printTestClassPath').directory(repoRoot).start
		process.waitFor(10, TimeUnit.MINUTES) // allow for downloads and the like
		val jars = CharStreams.readLines(new InputStreamReader(process.inputStream, StandardCharsets.UTF_8)).filter[startsWith('/')].filter[endsWith('.jar')].filter [
			new File(it).exists
		]
		return jars
	}

	def void initIndexWithGradleRoot(File file) {
		if (new File(file.absolutePath + '/build.gradle').exists) {
			prepareGradleTask(file)
			val jars = collectClasspathJarsViaGradle(file)
			builder => [
				languages = languageAccessFactory.createLanguageAccess(languageSetups.map[createLanguageConfiguration(class)], class.classLoader)
				configureSourcePaths(file.absolutePath + "/src/main/java", file.absolutePath + '/src/test/java')

				configureClassPathEntries(#[file.absolutePath + '/classes/java/main' /*, file.absolutePath + '/classes/java/test'*/ ] + jars)
			// test holds generated test classes
			]
			builder.launch // does all the indexing ...
		}
	}

	@VisibleForTesting
	protected def boolean shouldSkipDirectory(File directory) {
		return directory.name == Constants.DOT_GIT
	}

	@VisibleForTesting
	protected def boolean isRelevantForIndex(String filePath) {
		if (filePath === null) {
			return false
		}
		val knownLanguageExtensions = Resource.Factory.Registry.INSTANCE.extensionToFactoryMap.keySet
		val fileExtension = FilenameUtils.getExtension(filePath).toLowerCase
		return knownLanguageExtensions.exists[ext|ext.toLowerCase == fileExtension]
	}

	private def boolean isRelevantForIndex(DiffEntry diff) {
		return isRelevantForIndex(diff.newPath) || isRelevantForIndex(diff.oldPath)
	}

	/**
	 * Analyzes the Git diff and updates the index accordingly.
	 */
	def void updateIndex(File root, List<DiffEntry> diffs) {
		for (diff : diffs) {
			if (isRelevantForIndex(diff)) {
				handleRelevantDiff(root, diff)
			} else {
				logger.debug("Skipping index update for irrelevant diff='{}'.", diff)
			}
		}
	}

	private def void handleRelevantDiff(File root, DiffEntry diff) {
		logger.debug("Handling Git diff='{}'.", diff)
		switch (diff.changeType) {
			case ADD: {
				index.add(getAbsoluteFileURI(root, diff.newPath))
			}
			case COPY: {
				if (isRelevantForIndex(diff.newPath)) {
					index.add(getAbsoluteFileURI(root, diff.newPath))
				} else {
					logger.debug("Skipping index update for irrelevant diff='{}'.", diff)
				}
			}
			case DELETE: {
				index.remove(getAbsoluteFileURI(root, diff.oldPath))
			}
			case MODIFY: {
				index.update(getAbsoluteFileURI(root, diff.oldPath))
			}
			case RENAME: {
				if (isRelevantForIndex(diff.oldPath)) {
					index.remove(getAbsoluteFileURI(root, diff.oldPath))
				}
				if (isRelevantForIndex(diff.newPath)) {
					index.add(getAbsoluteFileURI(root, diff.newPath))
				}
			}
			default: {
				throw new RuntimeException('''Unknown Git diff change type='«diff.changeType.name»'.''')
			}
		}
	}

	private def URI getAbsoluteFileURI(File file) {
		return URI.createFileURI(file.absolutePath)
	}

	private def URI getAbsoluteFileURI(File parent, String child) {
		val file = new File(parent, child)
		return getAbsoluteFileURI(file)
	}

	def setLanguageSetups(List<ISetup> setups) {
		languageSetups = setups
	}

	private def ILanguageConfiguration createLanguageConfiguration(Class<? extends ISetup> setupClass) {
		return new ILanguageConfiguration() {

			override getOutputConfigurations() {
				configurationProvider.getOutputConfigurations()
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
