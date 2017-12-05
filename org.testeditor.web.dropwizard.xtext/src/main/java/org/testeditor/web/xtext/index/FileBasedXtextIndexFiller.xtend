package org.testeditor.web.xtext.index

import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.slf4j.LoggerFactory

/**
 * fill the index with files relevant to the registered xtext languages, found from a filesystem root
 */
class FileBasedXtextIndexFiller {

	protected static var logger = LoggerFactory.getLogger(FileBasedXtextIndexFiller)

	/**
	 * which files should be collected into the index (and are parseable by the languages registered)
	 */
	def boolean isIndexRelevant(File file) {
		val knownLanguageExtensions = Resource.Factory.Registry.INSTANCE.extensionToFactoryMap.keySet
		return knownLanguageExtensions.exists[file.name.endsWith('''.«it»''')]
	}

	/**
	 * recursively traverse the file tree and add all files to the index that are index relevant
	 */
	def void fillWithFileRecursively(XtextIndex index, File file) {
		file.listFiles?.forEach [
			fillWithFileRecursively(index, it)
		]
		if (file.isFile && file.isIndexRelevant) {
			logger.info("adding file '{}' to index", file.absolutePath)
			val uri = URI.createFileURI(file.absolutePath)
			index.add(uri)
			logger.info("added file with uri = '{}' to index", uri)
		}
	}

}
