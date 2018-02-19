package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.notify.Notifier
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.resource.impl.ResourceSetBasedResourceDescriptions
import org.slf4j.LoggerFactory

import static org.eclipse.xtext.resource.impl.ResourceDescriptionsData.ResourceSetAdapter.installResourceDescriptionsData

/**
 * index that holds all xtext (language) relevant resources of this project
 */
@Singleton
class XtextIndex extends ResourceSetBasedResourceDescriptions {

	static val logger = LoggerFactory.getLogger(XtextIndex)

	@Inject IResourceDescription.Manager resourceDescriptionManager
	ResourceDescriptionsData data

	@Inject
	new(XtextResourceSet resourceSet) {
		data = new ResourceDescriptionsData(emptyList)
		installResourceDescriptionsData(resourceSet, data)
		super.context = resourceSet
	}
	
	/** used by the custom standalone builder to write the collected information into this index */
	def void init(ResourceDescriptionsData newData, XtextResourceSet resourceSet) {
		data = new ResourceDescriptionsData(emptyList)
		super.context = resourceSet
	}

	/** 
	 * add resource to index
	 */
	def void add(URI uri) {
		logger.debug("Loading resource='{}'", uri)
		val resource = resourceSet.getResource(uri, true)
		resource.addToIndex
	}

	/**
	 * update index with given resource
	 */
	def void update(URI uri) {
		logger.debug("Reloading resource='{}'", uri)
		val oldResource = resourceSet.getResource(uri, false)

		if (oldResource.isLoaded) {
			oldResource.unload
		}
		val resource = resourceSet.getResource(uri, true)
		synchronized (data) {
			data.removeDescription(uri)
		}
		resource.addToIndex
	}

	/**
	 * update (if present) or add (if absent) resource to index
	 */
	def void updateOrAdd(URI uri) {
		if (data.getResourceDescription(uri) !== null) {
			uri.update
		} else {
			uri.add
		}
	}

	/**
	 * remove the resource (if present) by uri from index
	 */
	def void remove(URI uri) {
		val resource = resourceSet.getResource(uri, false)
		if (resource !== null) {
			logger.debug("Removing resource='{}'", uri)
			if (resource.isLoaded) {
				synchronized (data) {
					data.removeDescription(uri)
				}
				resource.unload
			}
			resourceSet.resources.remove(resource)
		}
	}

	/** 
	 * get resource by uri from index
	 */
	def Resource getResource(URI uri) {
		return resourceSet.getResource(uri, true)
	}

	/**
	 * get number of resource w/i this index
	 */
	def int getResourceCount() {
		return resourceSet.resources.size
	}

	override setContext(Notifier ctx) {
		// Ignore resetting of the context
	}

	private def void addToIndex(Resource resource) {
		val resourceDescription = resourceDescriptionManager.getResourceDescription(resource)
		if (resourceDescription !== null) {
			val uri = resource.URI
			synchronized (data) {
				data.addDescription(uri, resourceDescription)
			}
			if (logger.traceEnabled) {
				val exportedObjects = resourceDescription.exportedObjects.map [
					toString + " (" + EClass.name + ")"
				]
				logger.trace('''Adding description for uri='«uri»'. Exported objects='«exportedObjects»'.''')
			}
		}
	}

}
