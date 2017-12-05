package org.testeditor.web.xtext.index.persistence

import com.google.common.annotations.VisibleForTesting
import java.io.File
import java.util.List
import javax.inject.Inject
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.Constants
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.XtextIndex

class IndexUpdater {

	static val logger = LoggerFactory.getLogger(IndexUpdater)

	@Inject XtextIndex index

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
				index.add(getAbsoluteFileURI(root, diff.newPath))
			}
			case DELETE: {
				index.remove(getAbsoluteFileURI(root, diff.oldPath))
			}
			case MODIFY: {
				index.update(getAbsoluteFileURI(root, diff.oldPath))
			}
			case RENAME: {
				index.remove(getAbsoluteFileURI(root, diff.oldPath))
				index.add(getAbsoluteFileURI(root, diff.newPath))
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

}
