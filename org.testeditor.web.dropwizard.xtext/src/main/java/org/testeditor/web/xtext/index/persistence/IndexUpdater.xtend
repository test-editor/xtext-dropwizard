package org.testeditor.web.xtext.index.persistence

import com.google.common.annotations.VisibleForTesting
import java.io.File
import java.util.List
import java.util.Map
import javax.inject.Inject
import javax.inject.Singleton
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.Constants
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.LanguageAccess
import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.resource.FileExtensionProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.XtextIndex

/**
 * Default implementation of an index used for xtext web services in the context of dropwizard applications
 */
@Singleton
class IndexUpdater {

	static val logger = LoggerFactory.getLogger(IndexUpdater)

	@Inject protected XtextIndex index
	@Inject OutputConfigurationProvider configurationProvider

	@Accessors(PUBLIC_GETTER)
	var List<ISetup> languageSetups
	@Accessors(PUBLIC_GETTER)
	var Map<String, LanguageAccess> languageAccessors

	def void initLanguages(List<ISetup> newLanguageSetups) {
		languageSetups = newLanguageSetups
		languageAccessors = createLanguageAccess(languageSetups)
	}

	/**
	 * override to change default initialization of index (make sure to use a singleton for subclasses)
	 */
	def void initIndex(File file) {
		addToIndex(file)
	}

	/**
	 * Recursively traverses the file tree and adds all files to the
	 * index that are relevant (with registered language extensions).
	 */
	protected def void addToIndex(File file) {
		if (file.isDirectory && !shouldSkipDirectory(file)) {
			file.listFiles.forEach[addToIndex]
		} else if (file.isFile && isRelevantForIndex(file.path)) {
			val uri = getAbsoluteFileURI(file)
			index.updateOrAdd(uri)
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

	/** partial copy of LanguageAccessFactory */
	private def Map<String, LanguageAccess> createLanguageAccess(List<? extends ISetup> languageSetups) {
		val result = newHashMap
		for (ISetup setup : languageSetups) {
			val injector = setup.createInjectorAndDoEMFRegistration
			val serviceProvider = injector.getInstance(IResourceServiceProvider)
			val fileExtensionProvider = injector.getInstance(FileExtensionProvider)
			val languageAccess = new LanguageAccess(configurationProvider.outputConfigurations, serviceProvider, true)
			fileExtensionProvider.fileExtensions.forEach[result.put(it, languageAccess)]
		}

		return result
	}

}
