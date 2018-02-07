package org.testeditor.web.xtext.index

import org.eclipse.xtext.builder.standalone.StandaloneBuilder
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.AccessorType

/** 
 * derived from StandaloneBuilder, initializing the custom xtext index when builder has built the resource set
 * and the resource descriptions data  
 */
class CustomStandaloneBuilder extends StandaloneBuilder {

	@Accessors(AccessorType.PUBLIC_GETTER)	
	@Inject XtextIndex index
	
	override protected installIndex(XtextResourceSet resourceSet, ResourceDescriptionsData indexData) {
		super.installIndex(resourceSet, indexData)
		index.init(indexData, resourceSet)
	}
	
	def XtextResourceSet getResourceSet() {
		return index.resourceSet as XtextResourceSet
	}
	
	def CustomStandaloneBuilder configureSourcePaths(String rootPath, String ... paths) {
		baseDir = rootPath
		sourceDirs = paths
		return this
	}

	def CustomStandaloneBuilder configureClassPathEntries(String ... classpathEntries) {
		classPathEntries = classpathEntries
		return this
	}

}