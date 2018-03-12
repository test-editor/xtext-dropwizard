package org.testeditor.web.xtext.index.buildutils

import com.google.common.base.Predicate
import com.google.common.collect.Sets
import java.io.File
import java.io.FileFilter
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.mwe.PathTraverser

/**
 * Traverses only directories and files that are accepted by the provided filter.
 * 
 * Note that, if a directory is not accepted by the filter, its content will not
 * be considered, either.
 * Paths to archives passed to the traverser are handled as usual.
 */
@FinalFieldsConstructor
class FilterablePathTraverser extends PathTraverser {

	val FileFilter filter

	override traverseDir(File file, Predicate<URI> isValidPredicate) {
		val result = Sets.newHashSet
		val files = file.listFiles(filter)
		if (files === null) {
			return result
		}
		for (File f : files) {
			if (f.isDirectory()) {
				result.addAll(traverseDir(f, isValidPredicate))
			} else {
				val uri = URI.createFileURI(f.getAbsolutePath())
				if (isValidPredicate.apply(uri)) {
					result.add(uri)
				}
			}
		}
		return result
	}

}
