package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.xtend.lib.annotations.AccessorType
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.builder.standalone.StandaloneBuilder
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData

import static extension org.eclipse.xtend.lib.annotations.AccessorType.*

/** 
 * derived from StandaloneBuilder, initializing the custom xtext index when builder has built the resource set
 * and the resource descriptions data  
 */
@Singleton
class CustomStandaloneBuilder extends StandaloneBuilder {

	@Accessors(AccessorType.PUBLIC_GETTER)
	@Inject XtextIndex index

	/** make sure to initialize index with collected resourceSet and indexData */
	override protected installIndex(XtextResourceSet resourceSet, ResourceDescriptionsData indexData) {
		super.installIndex(resourceSet, indexData)
		index.init(indexData, resourceSet)
	}

	def XtextResourceSet getResourceSet() {
		return index.resourceSet as XtextResourceSet
	}

}
