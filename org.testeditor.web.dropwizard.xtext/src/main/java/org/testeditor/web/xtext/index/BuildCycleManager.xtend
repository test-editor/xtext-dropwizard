package org.testeditor.web.xtext.index

import com.google.common.base.Supplier
import com.google.inject.Inject
import java.io.File
import java.util.Set
import javax.inject.Named
import javax.inject.Provider
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ProjectDescription
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

import static com.google.common.base.Suppliers.memoize

@Singleton
class BuildCycleManager {

	@Inject Provider<XtextConfiguration> config
	@Inject ChangeDetector changeDetector
	@Inject ValidationMarkerUpdater validationUpdater
	@Inject XtextResourceSet indexResourceSet
	@Inject IncrementalBuilder builder
	@Inject ChunkedResourceDescriptionsProvider indexProvider
	@Inject extension IndexSearchPathProvider searchPathProvider
	@Inject extension IResourceServiceProvider.Registry resourceServiceProviderFactory

	var Supplier<URI> baseURI = memoize[URI.createFileURI(config.get.localRepoFileRoot)]

	var IndexState lastIndexState = new IndexState
	var String[] staticSearchPaths = null

	def void startBuild() {
		createBuildRequest.addChanges.build.updateIndex
		updateValidationMarkers
	}

	def BuildRequest addChanges(BuildRequest request) {
		return request => [
			val changes = changeDetector.detectChanges(indexResourceSet, searchPaths, new ChangedResources)
			dirtyFiles += changes.modifiedResources
			deletedFiles += changes.deletedResources
		]
	}

	def String[] getSearchPaths(BuildRequest request) {
		return getStaticSearchPaths + config.get.localRepoFileRoot.additionalSearchPaths
	}

	def BuildRequest createBuildRequest() {
		return new BuildRequest => [
			baseDir = baseURI.get
			afterValidate = validationUpdater
			resourceSet = indexProvider.indexResourceSet
			state = lastIndexState
		]
	}

	def IndexState build(BuildRequest request) {
		return builder.build(request, [getResourceServiceProvider]).indexState
	}

	def void updateValidationMarkers() {
		validationUpdater.updateMarkerMap
	}

	def void updateIndex(IndexState indexState) {
		val projectName = indexProvider.project.name
		val index = indexProvider.getResourceDescriptions()

		index.setContainer(projectName, indexState.resourceDescriptions)
	}

	private def getStaticSearchPaths() {
		if (staticSearchPaths === null) {
			val baseDir = new File(config.get.localRepoFileRoot)
			staticSearchPaths = config.get.indexSearchPaths.map[new File(baseDir, it).absolutePath]
		}
		return staticSearchPaths
	}

}

@Singleton
class ChunkedResourceDescriptionsProvider implements IResourceDescriptionsProvider {

	public static val String PROJECT_NAME = 'projectName'

	@Accessors(PUBLIC_GETTER)
	@Inject
	XtextResourceSet indexResourceSet

	@Inject(optional=true)
	@Named(PROJECT_NAME)
	String projectName

	var Supplier<ProjectDescription> project = memoize[
		new ProjectDescription => [
			name = projectName ?: 'Unnamed Project'
			attachToEmfObject(indexResourceSet)
		]
	]

	def ProjectDescription getProject() {
		return project.get
	}

	def ChunkedResourceDescriptions getResourceDescriptions() {
		var index = ChunkedResourceDescriptions.findInEmfObject(indexResourceSet)
		if (index === null) {
			index = new ChunkedResourceDescriptions(emptyMap, indexResourceSet)
		}
		return index
	}

	override ChunkedResourceDescriptions getResourceDescriptions(ResourceSet resourceSet) {
		return if (resourceSet !== indexResourceSet) {
			resourceSet.registerWithProject
			ChunkedResourceDescriptions.findInEmfObject(indexResourceSet) ?: resourceDescriptions.createShallowCopyWith(resourceSet)
		} else {
			resourceDescriptions
		}
	}

	private def registerWithProject(ResourceSet resourceSet) {
		if (ProjectDescription.findInEmfObject(resourceSet) === null) {
			project.get.attachToEmfObject(resourceSet)
		}
	}

}

interface IndexSearchPathProvider {

	def String[] additionalSearchPaths(String rootPath)

}

interface ChangeDetector {

	def ChangedResources detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges)

}

class ChangedResources {

	val modifiedResources = <URI>newHashSet
	val deletedResources = <URI>newHashSet

	def Set<URI> getModifiedResources() { return modifiedResources }

	def Set<URI> getDeletedResources() { return deletedResources }

}
