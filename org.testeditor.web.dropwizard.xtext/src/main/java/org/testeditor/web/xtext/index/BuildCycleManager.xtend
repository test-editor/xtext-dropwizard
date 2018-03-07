package org.testeditor.web.xtext.index

import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

@Singleton
class BuildCycleManager {

	@Inject ChangeDetector changeDetector
	@Inject ValidationMarkerUpdater validationUpdater
	@Inject XtextResourceSet indexResourceSet
	@Inject IncrementalBuilder builder
	@Inject ChunkedResourceDescriptionsProvider indexProvider
	@Inject extension IResourceServiceProvider.Registry resourceServiceProviderFactory

	var URI baseURI
	var IndexState lastIndexState = new IndexState

	def init(URI baseURI) {
		this.baseURI = baseURI
	}

	def startBuild() {
		createBuildRequest.addChanges.build.updateIndex
		updateValidationMarkers
	}

	def BuildRequest addChanges(BuildRequest request) {
		return request => [
			dirtyFiles += changeDetector.modifiedResources
			deletedFiles += changeDetector.deletedResources
		]
	}

	def BuildRequest createBuildRequest() {
		return new BuildRequest => [
			baseDir = baseURI
			afterValidate = validationUpdater
			resourceSet = indexResourceSet
			state = lastIndexState
		]
	}

	def IndexState build(BuildRequest request) {
		return builder.build(request, [getResourceServiceProvider]).indexState
	}

	def updateValidationMarkers() {
		validationUpdater.updateMarkerMap
	}

	def updateIndex(IndexState indexState) {
		index.setContainer(baseURI.toString, indexState.resourceDescriptions)
	}

	private def getIndex() {
		indexProvider.getIndex(indexResourceSet)
	}

}

class ChunkedResourceDescriptionsProvider {

	def ChunkedResourceDescriptions getIndex(ResourceSet resourceSet) {
		var index = ChunkedResourceDescriptions.findInEmfObject(resourceSet)
		if (index === null) {
			index = new ChunkedResourceDescriptions(emptyMap, resourceSet)
		}
		return index
	}

}

interface ChangeDetector {

	def Iterable<URI> getModifiedResources()

	def Iterable<URI> getDeletedResources()

}
