package org.testeditor.web.xtext.index.changes

import java.io.File
import java.nio.file.Path
import javax.inject.Inject
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.ecore.resource.Resource
import org.testeditor.web.dropwizard.xtext.XtextConfiguration

interface IndexFilter {

	def boolean isRelevantForIndex(String path)

}

class LanguageExtensionBasedIndexFilter implements IndexFilter {

	override boolean isRelevantForIndex(String filePath) {
		if (filePath === null) {
			return false
		}
		val knownLanguageExtensions = Resource.Factory.Registry.INSTANCE.extensionToFactoryMap.keySet
		val fileExtension = FilenameUtils.getExtension(filePath).toLowerCase
		return knownLanguageExtensions.exists[ext|ext.toLowerCase == fileExtension]
	}

}

class SearchPathBasedIndexFilter implements IndexFilter {

	@Inject XtextConfiguration config

	var Iterable<Path> searchPaths = null

	override boolean isRelevantForIndex(String path) {
		return getSearchPaths.exists[new File(path).toPath.toAbsolutePath.startsWith(it)]
	}

	private def Iterable<Path> getSearchPaths() {
		if (searchPaths === null) {
			val baseDir = new File(config.localRepoFileRoot)
			searchPaths = config.indexSearchPaths.map[new File(baseDir, it).toPath.toAbsolutePath]
		}
		return searchPaths
	}

}

class LogicalAndBasedIndexFilter implements IndexFilter {

	@Inject Iterable<IndexFilter> conditions

	override boolean isRelevantForIndex(String path) {
		return conditions.forall[it.isRelevantForIndex(path)]
	}

}
