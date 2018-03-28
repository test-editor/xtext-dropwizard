package org.testeditor.web.xtext.index.changes

import java.io.File
import java.nio.file.Path
import javax.inject.Inject
import javax.inject.Provider
import org.apache.commons.io.FilenameUtils
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.eclipse.emf.common.util.URI

interface IndexFilter {

	def boolean isRelevantForIndex(URI uri)

}

class LanguageExtensionBasedIndexFilter implements IndexFilter {

	@Inject LanguageAccessRegistry languages

	override boolean isRelevantForIndex(URI fileURI) {
		return if (fileURI !== null) {
			val knownLanguageExtensions = languages.extensions
			val fileExtension = FilenameUtils.getExtension(fileURI.toString)
			knownLanguageExtensions.exists[equalsIgnoreCase(fileExtension)]
		} else {
			false
		}
	}

}

class SearchPathBasedIndexFilter implements IndexFilter {

	@Inject Provider<XtextConfiguration> config

	var Iterable<Path> searchPaths = null

	override boolean isRelevantForIndex(URI resourceURI) {
		val absolutePath = new File(resourceURI.path).toPath.toAbsolutePath
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

	override boolean isRelevantForIndex(URI uri) {
		return conditions.forall[it.isRelevantForIndex(uri)]
	}

}

class LogicalOrBasedIndexFilter implements IndexFilter {
	
	@Inject Iterable<IndexFilter> conditions
	
	override isRelevantForIndex(URI uri) {
		return conditions.exists[it.isRelevantForIndex(uri)]
	}
	
}
