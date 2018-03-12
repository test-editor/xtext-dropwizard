package org.testeditor.web.xtext.index

import java.io.File
import java.util.Set
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
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

@Singleton
class BuildCycleManager {

	@Inject XtextConfiguration config
	@Inject ChangeDetector changeDetector
	@Inject ValidationMarkerUpdater validationUpdater
	@Inject XtextResourceSet indexResourceSet
	@Inject IncrementalBuilder builder
	@Inject ChunkedResourceDescriptionsProvider indexProvider
	@Inject extension IndexSearchPathProvider searchPathProvider
	@Inject extension IResourceServiceProvider.Registry resourceServiceProviderFactory

	var URI baseURI
	var IndexState lastIndexState = new IndexState
	var firstBuild = true
	var String[] staticSearchPaths = null

	def init(URI baseURI) {
		this.baseURI = baseURI
	}

	def startBuild() {
		startBuild(firstBuild)
		firstBuild = false
	}

	private def startBuild(boolean firstBuild) {
		createBuildRequest.addChanges(firstBuild).build.updateIndex
		updateValidationMarkers
	}

	def BuildRequest addChanges(BuildRequest request, boolean firstBuild) {
		return request => [
			if (firstBuild) {
//				dirtyFiles += changeDetector.allResources(indexResourceSet)
			} else {
				val changes = changeDetector.detectChanges(indexResourceSet, searchPaths)
				dirtyFiles += changes.modifiedResources
				deletedFiles += changes.deletedResources
			}
		]
	}

	def String[] getSearchPaths() {
		getStaticSearchPaths + config.localRepoFileRoot.additionalSearchPaths
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

	private def getStaticSearchPaths() {
		if (staticSearchPaths === null) {
			val baseDir = new File(config.localRepoFileRoot)
			staticSearchPaths = config.indexSearchPaths.map[new File(baseDir, it).absolutePath]
		}
		return staticSearchPaths
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

interface IndexSearchPathProvider {
	def String[] additionalSearchPaths(String rootPath)
}

interface ChangeDetector {
	def ChangedResources detectChanges(ResourceSet resourceSet, String[] paths)
}

interface ChangedResources {
	def Iterable<URI> getModifiedResources()

	def Iterable<URI> getDeletedResources()
}

class SetBasedChangedResources implements ChangedResources {
	val modifiedResources = <URI>newHashSet
	val deletedResources = <URI>newHashSet

	override Set<URI> getModifiedResources() { modifiedResources }

	override Set<URI> getDeletedResources() { deletedResources }
}
