package org.testeditor.web.xtext.index.changes

import java.io.File
import java.nio.file.Path
import javax.inject.Inject
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.ecore.resource.Resource
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import javax.inject.Provider

interface IndexFilter {

	def boolean isRelevantForIndex(String path)

}

class LanguageExtensionBasedIndexFilter implements IndexFilter {

	override boolean isRelevantForIndex(String filePath) {
		return if (filePath !== null) {
			val knownLanguageExtensions = Resource.Factory.Registry.INSTANCE.extensionToFactoryMap.keySet
			val fileExtension = FilenameUtils.getExtension(filePath)
			knownLanguageExtensions.exists[equalsIgnoreCase(fileExtension)]
		} else {
			false
		}
	}

}

class SearchPathBasedIndexFilter implements IndexFilter {

	@Inject Provider<XtextConfiguration> config

	var Iterable<Path> searchPaths = null

	override boolean isRelevantForIndex(String path) {
		val absolutePath = new File(path).toPath.toAbsolutePath
		return getSearchPaths.exists[absolutePath.startsWith(it)]
	}

	private def Iterable<Path> getSearchPaths() {
		if (searchPaths === null) {
			val baseDir = new File(config.get.localRepoFileRoot)
			searchPaths = config.get.indexSearchPaths.map[new File(baseDir, it).toPath.toAbsolutePath]
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
