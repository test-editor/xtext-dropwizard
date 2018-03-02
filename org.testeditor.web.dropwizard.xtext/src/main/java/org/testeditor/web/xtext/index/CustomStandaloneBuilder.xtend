package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.AccessorType
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.builder.standalone.StandaloneBuilder
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

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

	override launch() {
		val result = super.launch()
		(issueHandler as ValidationMarkerUpdater).updateMarkerMap
		return result
	}

	override protected validate(Resource resource) {
		(issueHandler as ValidationMarkerUpdater).setContext(resource)
		val result = super.validate(resource)
		return result
	}

}
